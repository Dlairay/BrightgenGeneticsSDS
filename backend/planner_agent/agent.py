import os
import sys
import json
import asyncio
import warnings
import logging
from typing import Literal, List, Dict, Union
from pydantic import BaseModel, ValidationError, ConfigDict 
from dotenv import load_dotenv
from google.cloud import firestore
import datetime 

from google.adk.agents import Agent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types

# Allow imports from backend directory
_current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(_current_dir))
import config

# Suppress warnings and logs below ERROR
warnings.filterwarnings("ignore")
logging.basicConfig(level=logging.ERROR) # Keep this for minimal logging
load_dotenv()

# Initialize Firestore Client
db = firestore.Client()
print(f"Firestore Client initialized. Project ID: {db.project}") # Add debug print for project ID

# ─── Pydantic Schemas ─────────────────────────────────────────────────────────
class Recommendation(BaseModel):
    trait: str
    goal: str
    activity: str

class FollowupQuestion(BaseModel):
    question: str
    options: List[str]

class LogEntry(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True) 

    entry_type: Literal["initial", "checkin", "emergency"]
    interpreted_traits: List[str]
    recommendations: List[Recommendation]
    summary: str
    followup_questions: List[FollowupQuestion]
    timestamp: Union[datetime.datetime, str, None] = None 


# ─── Utility Functions ────────────────────────────────────────────────────────
def _strip_code_fences(text: str) -> str:
    """Remove code fences from AI responses."""
    if text.startswith("```"):
        parts = text.split("\n", 1)
        text = parts[1] if len(parts) > 1 else ''
    if text.rstrip().endswith("```"):
        text = text.rstrip()[:-3]
    return text.strip()

# ─── Firestore I/O Functions ──────────────────────────────────────────────────
def get_child_logs_collection_ref(child_id: int):
    """Helper to get the Firestore subcollection reference for a child's logs."""
    # Ensure child_id is always treated as a string for document ID
    return db.collection('profiles').document(str(child_id)).collection('logs')

def read_logs(child_id: int) -> List[dict]:
    """Read logs for a specific child from Firestore."""
    logs_ref = get_child_logs_collection_ref(child_id).order_by(
        'timestamp', direction=firestore.Query.ASCENDING
    )
    logs = [doc.to_dict() for doc in logs_ref.stream()]
    print(f"DEBUG: Retrieved {len(logs)} logs for Child ID {child_id}.") # Debug print
    if not logs:
        print(f"DEBUG: No logs found in Firestore for profiles/child_{child_id}/logs") # Debug print
        # Also check if the parent document exists
        parent_doc = db.collection('profiles').document(str(child_id)).get()
        if not parent_doc.exists:
            print(f"DEBUG: Parent document 'profiles/{child_id}' does NOT exist.")
        else:
            print(f"DEBUG: Parent document 'profiles/{child_id}' EXISTS.")
    return logs

def append_logs(child_id: int, log_entry: dict) -> None:
    """Append a log entry to child's logs in Firestore."""
    logs_collection_ref = get_child_logs_collection_ref(child_id)

    # Validate structure *before* modifying the timestamp type
    validated = LogEntry(**log_entry) 

    if validated.entry_type == "initial":
        initial_logs = logs_collection_ref.where('entry_type', '==', 'initial').stream()
        if any(true for true in initial_logs):
            print("⚠️ Initial log entry already exists in Firestore; skipping append.")
            return

    log_entry['timestamp'] = firestore.SERVER_TIMESTAMP
    
    logs_collection_ref.add(log_entry)
    print(f"✅ Successfully saved log for Child ID {child_id} to Firestore.")


# ─── Agents Setup ─────────────────────────────────────────────────────────────
MODEL = "gemini-2.0-flash"

child_log_agent = Agent(
    name="child_log_agent_v2",
    model=MODEL,
    description="Generates structured child log entries with multiple-choice follow-up questions.",
    instruction="""
You are a JSON-only assistant.
Receive a JSON payload with keys:
  • 'interpreted_traits' (list of strings),
  • 'followup_answers' (dict mapping question→response),
  • 'log_history' (array of prior entries).
You must output exactly one JSON object matching this schema (no markdown or fences):

{
  "entry_type": "initial" | "checkin" | "emergency",
  "interpreted_traits": [string, …],
  "recommendations": [
    { "trait": string, "goal": string, "activity": string }, …
  ],
  "summary": string,
  "followup_questions": [
    {
      "question": string,
      "options": [string, string, string, string]
    }, …
  ]
}

• Emit exactly four options per question.
• Options should cover the most likely parent answers.
• Use simple, mutually-exclusive choices.
"""
)

option_agent = Agent(
    name="child_log_option_agent",
    model=MODEL,
    description="Generates possible responses to a follow-up question.",
    instruction=(
        "You are a JSON-only assistant.\n"
        "Given a JSON object with 'question' (string) and 'interpreted_traits' (list of strings),\n"
        "return exactly three concise strings in a JSON array, each a relevant response.\n"
        "Do not wrap in markdown or code fences."
    )
)

# ─── Log Generation Service ────────────────────────────────────────────────────
class LogGenerationService:
    """Service class for generating log entries using AI agents."""
    
    def __init__(self):
        self.session_service = InMemorySessionService()
        self.app_name = "child_log_manager_app"
    
    async def _ensure_session(self, session_id: str):
        """Ensure a session exists."""
        try:
            await self.session_service.create_session(
                app_name=self.app_name, 
                user_id="user_1", 
                session_id=session_id
            )
        except Exception:
            # Session might already exist
            pass
    
    async def generate_initial_log(self, traits: List[Dict]) -> Dict:
        """Generate initial log entry from traits data."""
        session_id = "initial_log_session"
        await self._ensure_session(session_id)
        
        runner = Runner(
            agent=child_log_agent,
            app_name=self.app_name,
            session_service=self.session_service
        )
        
        # Create payload for initial log generation
        payload = {
            "interpreted_traits": [trait.get("trait_name", "") for trait in traits],
            "followup_answers": {},
            "log_history": []
        }
        
        content = types.Content(
            role='user', 
            parts=[types.Part(text=json.dumps(payload))]
        )
        
        result = None
        async for ev in runner.run_async(
            user_id="user_1", 
            session_id=session_id, 
            new_message=content
        ):
            if ev.is_final_response() and ev.content:
                result = ev.content.parts[0].text
                break
        
        if not result:
            raise RuntimeError("Initial log generation failed")
        
        cleaned = _strip_code_fences(result)
        try:
            log_data = json.loads(cleaned)
            validated = LogEntry(**log_data) 
            return validated.dict()
        except (json.JSONDecodeError, ValidationError) as e:
            print(f"❌ Log generation error: {e}")
            print(f"Raw response: {cleaned}")
            raise

    async def _generate_question_options(
        self, question: str, traits: List[str], session_id: str
    ) -> List[str]:
        """Generate options for a follow-up question."""
        runner = Runner(
            agent=option_agent,
            app_name=self.app_name,
            session_service=self.session_service
        )
        
        payload = {"question": question, "interpreted_traits": traits}
        content = types.Content(
            role='user', 
            parts=[types.Part(text=json.dumps(payload))]
        )
        
        result = None
        async for ev in runner.run_async(
            user_id="user_1", 
            session_id=session_id, 
            new_message=content
        ):
            if ev.is_final_response() and ev.content:
                result = ev.content.parts[0].text
                break
        
        if not result:
            raise RuntimeError("Option generation failed")
        
        return json.loads(_strip_code_fences(result))

    async def _generate_followup_entry(
        self,
        traits: List[str],
        answers: Dict[str, str],
        session_id: str,
        history: List[dict]
    ) -> dict:
        """Generate a follow-up log entry."""
        runner = Runner(
            agent=child_log_agent,
            app_name=self.app_name,
            session_service=self.session_service
        )
        
        payload = {
            "interpreted_traits": traits,
            "followup_answers": answers,
            "log_history": history
        }
        
        content = types.Content(
            role='user', 
            parts=[types.Part(text=json.dumps(payload))]
        )
        
        result = None
        async for ev in runner.run_async(
            user_id="user_1", 
            session_id=session_id, 
            new_message=content
        ):
            if ev.is_final_response() and ev.content:
                result = ev.content.parts[0].text
                break
        
        if not result:
            raise RuntimeError("Entry generation failed")
        
        return json.loads(_strip_code_fences(result))

# ─── Interactive Flow ─────────────────────────────────────────────────────────
async def handle_child_session(child_id: int):
    """Handle interactive session for a child."""
    log_service = LogGenerationService()
    session_id = f"session_{child_id}"
    await log_service._ensure_session(session_id)
    
    logs = read_logs(child_id)
    if not logs:
        print(f"No logs found for Child ID {child_id}. Initial log might be needed. Exiting handle_child_session.") # Clarified message
        return
    
    # NEW: Convert Firestore Timestamps to strings for the agent
    # This function is assumed to be available from childprofile.py (or you can copy it here)
    from childprofile import _convert_firestore_timestamps_to_strings 
    logs_for_agent = _convert_firestore_timestamps_to_strings(logs)

    latest = logs_for_agent[-1]

    # Normalize follow-up questions to objects
    raw_qs = latest.get('followup_questions', [])
    questions: List[Dict[str, Union[str, List[str]]]] = []
    for item in raw_qs:
        if isinstance(item, str):
            # legacy: convert to MCQ using option_agent
            opts = await log_service._generate_question_options(
                item, latest['interpreted_traits'], session_id
            )
            questions.append({"question": item, "options": opts})
        else:
            questions.append(item)

    if not questions:
        print("No follow-up questions.")
        return

    print("Respond to each follow-up question:")
    answers: Dict[str, str] = {}
    for qobj in questions:
        text = qobj['question']
        opts = qobj['options']
        print(f"\n{text}")
        for i, opt in enumerate(opts, 1):
            print(f"  {i}. {opt}")
        choice = None
        while choice not in range(1, len(opts) + 1):
            try:
                choice = int(input(f"Select 1–{len(opts)}: ").strip())
            except ValueError:
                continue
        answers[text] = opts[choice - 1]

    new_entry = await log_service._generate_followup_entry(
        latest['interpreted_traits'],
        answers,
        session_id,
        logs_for_agent # Pass the converted logs as history to the agent
    )
    append_logs(child_id, new_entry) # This now uses the Firestore append_logs

    print("New Recommendations:")
    for rec in new_entry['recommendations']:
        print(f"- {rec['trait']}: {rec['activity']}")

# ─── Exported Functions ──────────────────────────────────────────────────────
async def run_for_child(child_id: int):
    """Run interactive session for a child."""
    # Ensure child_id is treated as a string for consistency with Firestore document IDs
    await handle_child_session(child_id)

__all__ = ["LogGenerationService", "run_for_child", "read_logs", "append_logs"]