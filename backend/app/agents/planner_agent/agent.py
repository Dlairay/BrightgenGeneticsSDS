import os
import sys
import json
import asyncio
import warnings
import logging
from typing import Literal, List, Dict, Union, Any
from pydantic import BaseModel, ValidationError, ConfigDict 
from dotenv import load_dotenv

from google.adk.agents import Agent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types
import pandas as pd 
import datetime 

# Suppress warnings and logs below ERROR
warnings.filterwarnings("ignore")
logging.basicConfig(level=logging.ERROR)
load_dotenv()

# Import from the refactored structure
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
from app.models.child_profile import ChildProfile
from app.repositories.trait_repository import TraitRepository 

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
    
    async def generate_initial_log(self, traits: List[Dict], derived_age: Union[int, None] = None, gender: Union[str, None] = None) -> Dict:
        """Generate initial log entry from traits data, optionally with derived age and gender."""
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
        
        # --- Add derived_age and gender to payload if available ---
        if derived_age is not None:
            payload["age"] = derived_age # Pass as 'age' to the agent
        if gender is not None:
            payload["gender"] = gender
        # --------------------------------------------------

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
        interpreted_traits: List[str],
        answers: Dict[str, str],
        session_id: str,
        log_history: List[dict],
        derived_age: Union[int, None] = None, # Change to derived_age
        gender: Union[str, None] = None # Add gender
    ) -> dict:
        """Generate a follow-up log entry."""
        runner = Runner(
            agent=child_log_agent,
            app_name=self.app_name,
            session_service=self.session_service
        )
        
        payload = {
            "interpreted_traits": interpreted_traits,
            "followup_answers": answers,
            "log_history": log_history
        }
        
        # --- Add derived_age and gender to payload if available ---
        if derived_age is not None:
            payload["age"] = derived_age # Pass as 'age' to the agent
        if gender is not None:
            payload["gender"] = gender
        # --------------------------------------------------

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
  • OPTIONAL: 'age' (integer, derived from birthday) and 'gender' (string) if provided.
Your output must be exactly one JSON object matching this schema (no markdown or fences):

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
• Incorporate 'age' and 'gender' into recommendations and summary if they are provided in the input payload.
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

# ─── Interactive Flow (Updated to use ChildProfile for I/O) ───────────────────────────
async def handle_child_session(child_profile: ChildProfile): # Now takes ChildProfile object directly
    """Handle interactive session for a child."""
    log_service = LogGenerationService()
    session_id = f"session_{child_profile.child_id}" # child_id is already a string
    await log_service._ensure_session(session_id)
    
    # Load logs using ChildProfile's Firestore-enabled method
    logs = child_profile.load_logs() 
    if not logs:
        print(f"No logs found for Child ID {child_profile.child_id}. Initial log might be needed. Exiting handle_child_session.")
        return
    
    # Convert Firestore Timestamps to strings for the agent
    logs_for_agent = _convert_firestore_timestamps_to_strings(logs)

    latest = logs_for_agent[-1] 

    # Load report to get birthday and gender
    child_report = child_profile.load_report()
    child_birthday_str = child_report.get("birthday") # Get birthday string
    child_gender = child_report.get("gender")

    # Derive age from birthday
    child_age = None
    if child_birthday_str:
        try:
            # Assuming birthday is in 'YYYY-MM-DD' format
            birth_date = datetime.datetime.strptime(child_birthday_str, '%Y-%m-%d').date()
            today = datetime.date.today()
            child_age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
        except ValueError:
            print(f"Warning: Could not parse birthday '{child_birthday_str}'. Age will not be passed to agent.")


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
        print("No follow-up questions from the latest log entry.")
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
        logs_for_agent, # Pass the converted logs as history to the agent
        derived_age=child_age,     # Pass derived age to agent
        gender=child_gender # Pass gender to agent
    )
    
    # Use ChildProfile's Firestore-enabled save_log
    child_profile.save_log(new_entry) 

    print("New Recommendations:")
    for rec in new_entry['recommendations']:
        print(f"- {rec['trait']}: {rec['activity']}")

# ─── Exported Functions ──────────────────────────────────────────────────────
async def run_for_child(child_id: str): # Child ID is now explicitly a string
    """Run interactive session for a child, creating a ChildProfile object."""
    from config import DATA_DIR 
    
    # Load trait_db (this is needed for ChildProfile initialization)
    trait_csv = os.path.join(DATA_DIR, "Genotype_Trait_Reference.csv")
    
    # Load trait_db from Firestore instead of CSV
    trait_repo = TraitRepository()
    trait_db = await trait_repo.load_trait_db() # Await this asynchronous call

    if trait_db.empty:
        raise RuntimeError("Trait reference data could not be loaded from Firestore. Cannot run child session.")

    # Instantiate ChildProfile with the given child_id and trait_db
    child_profile = ChildProfile(child_id=child_id, trait_db=trait_db)
    
    await handle_child_session(child_profile)

__all__ = ["LogGenerationService", "run_for_child"]
