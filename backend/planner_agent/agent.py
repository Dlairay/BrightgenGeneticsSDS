import os
import sys
import json
import asyncio
import warnings
import logging
from typing import Literal, List, Dict, Union
from pydantic import BaseModel, ValidationError
from dotenv import load_dotenv

from google.adk.agents import Agent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types

# Allow imports from backend directory
_current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(_current_dir))
import config
DATA_DIR = config.DATA_DIR

# Suppress warnings and logs below ERROR
warnings.filterwarnings("ignore")
logging.basicConfig(level=logging.ERROR)
load_dotenv()

# ─── Pydantic Schemas ─────────────────────────────────────────────────────────
class Recommendation(BaseModel):
    trait: str
    goal: str
    activity: str

class FollowupQuestion(BaseModel):
    question: str
    options: List[str]

class LogStructure(BaseModel):
    entry_type: Literal["initial", "checkin", "emergency"]
    interpreted_traits: List[str]
    recommendations: List[Recommendation]
    summary: str
    followup_questions: List[FollowupQuestion]

# ─── Utility: Clean agent responses ────────────────────────────────────────────
def _strip_code_fences(text: str) -> str:
    if text.startswith("```"):
        parts = text.split("\n", 1)
        text = parts[1] if len(parts) > 1 else ''
    if text.rstrip().endswith("```"):
        text = text.rstrip()[:-3]
    return text.strip()

# ─── Tools: read_logs & append_logs ────────────────────────────────────────────
def read_logs(child_id: int) -> List[dict]:
    fp = os.path.join(DATA_DIR, "child_profiles", f"child_{child_id}", "logs.json")
    if not os.path.exists(fp):
        raise FileNotFoundError(f"Logs not found for Child ID {child_id}: {fp}")
    with open(fp, 'r', encoding='utf-8') as f:
        return json.load(f)

def append_logs(child_id: int, log_entry: dict) -> None:
    validated = LogStructure(**log_entry)
    dirpath = os.path.join(DATA_DIR, "child_profiles", f"child_{child_id}")
    os.makedirs(dirpath, exist_ok=True)
    fp = os.path.join(dirpath, "logs.json")
    data = []
    if os.path.exists(fp):
        try:
            data = read_logs(child_id)
        except:
            data = []
    if validated.entry_type == "initial":
        data = [e for e in data if e.get("entry_type") != "initial"]
    data.append(validated.dict())
    with open(fp, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

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

# ─── Async Helpers ───────────────────────────────────────────────────────────
async def _generate_question_options(
    runner: Runner, question: str, traits: List[str], session_id: str
) -> List[str]:
    payload = {"question": question, "interpreted_traits": traits}
    content = types.Content(role='user', parts=[types.Part(text=json.dumps(payload))])
    result = None
    async for ev in runner.run_async(
        user_id="user_1", session_id=session_id, new_message=content
    ):
        if ev.is_final_response() and ev.content:
            result = ev.content.parts[0].text
            break
    if not result:
        raise RuntimeError("Option generation failed")
    return json.loads(_strip_code_fences(result))

async def _generate_new_entry(
    runner: Runner,
    traits: List[str],
    answers: Dict[str, str],
    session_id: str,
    history: List[dict]
) -> dict:
    payload = {
        "interpreted_traits": traits,
        "followup_answers": answers,
        "log_history": history
    }
    content = types.Content(role='user', parts=[types.Part(text=json.dumps(payload))])
    result = None
    async for ev in runner.run_async(
        user_id="user_1", session_id=session_id, new_message=content
    ):
        if ev.is_final_response() and ev.content:
            result = ev.content.parts[0].text
            break
    if not result:
        raise RuntimeError("Entry generation failed")
    return json.loads(_strip_code_fences(result))

# ─── Interactive Flow ─────────────────────────────────────────────────────────
async def handle_child_session(
    child_id: int,
    runner: Runner,
    opt_runner: Runner,
    session_id: str
):
    logs = read_logs(child_id)
    if not logs:
        print(f"No logs for Child {child_id}")
        return
    latest = logs[-1]

    # Normalize follow-up questions to objects
    raw_qs = latest.get('followup_questions', [])
    questions: List[Dict[str, Union[str, List[str]]]] = []
    for item in raw_qs:
        if isinstance(item, str):
            # legacy: convert to MCQ using option_agent
            opts = await _generate_question_options(opt_runner, item, latest['interpreted_traits'], session_id)
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

    new_entry = await _generate_new_entry(
        runner,
        latest['interpreted_traits'],
        answers,
        session_id,
        logs
    )
    append_logs(child_id, new_entry)

    print("New Recommendations:")
    for rec in new_entry['recommendations']:
        print(f"- {rec['trait']}: {rec['activity']}")

# ─── Exported Pipeline ─────────────────────────────────────────────────────────
async def run_for_child(child_id: int):
    session_id = f"session_{child_id}"
    svc = InMemorySessionService()
    await svc.create_session(
        app_name="child_log_manager_app", user_id="user_1", session_id=session_id
    )
    runner = Runner(
        agent=child_log_agent,
        app_name="child_log_manager_app",
        session_service=svc
    )
    opt_runner = Runner(
        agent=option_agent,
        app_name="child_log_manager_app",
        session_service=svc
    )
    await handle_child_session(child_id, runner, opt_runner, session_id)

__all__ = ["run_for_child"]