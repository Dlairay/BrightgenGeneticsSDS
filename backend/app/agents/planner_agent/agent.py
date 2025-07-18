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

# These imports are only needed for the LogGenerationService class 

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

__all__ = ["LogGenerationService"]
