import os
import sys
import json
import asyncio
import warnings
import logging
from typing import Literal, List
from pydantic import BaseModel, ValidationError
from dotenv import load_dotenv

from google.adk.agents import Agent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types

# Allow imports from backend directory
current_script_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(current_script_dir)
sys.path.insert(0, backend_dir)
import config
DATA_DIR = config.DATA_DIR

# Suppress warnings and logs below ERROR
warnings.filterwarnings("ignore")
logging.basicConfig(level=logging.ERROR)
load_dotenv()

# ─── Pydantic Schemas ─────────────────────────────────────────────────────────┐
class Recommendation(BaseModel):
    trait: str
    goal: str
    activity: str

class LogStructure(BaseModel):
    entry_type: Literal["checkin", "emergency"]
    interpreted_traits: List[str]
    recommendations: List[Recommendation]
    summary: str
    followup_questions: List[str]
# └────────────────────────────────────────────────────────────────────────────┘

# ─── Utility: Clean agent responses ────────────────────────────────────────────┐
def strip_code_fences(text: str) -> str:
    """
    Remove Markdown code fences or extra backticks from the AI response.
    """
    if text.startswith("```"):
        parts = text.split("\n", 1)
        text = parts[1] if len(parts) > 1 else ''
    if text.rstrip().endswith("```"):
        text = text.rstrip()[:-3]
    return text.strip()
# └────────────────────────────────────────────────────────────────────────────┘

# ─── Tools: read_logs & append_logs ────────────────────────────────────────────┐
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
    data.append(validated.dict())
    with open(fp, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
# └────────────────────────────────────────────────────────────────────────────┘

# ─── Agents Setup ─────────────────────────────────────────────────────────────┐
AGENT_MODEL = "gemini-2.0-flash"

child_log_agent = Agent(
    name="child_log_agent_v1",
    model=AGENT_MODEL,
    description="Generates structured child log entries based on follow-up answers.",
    instruction=(
        "You are a child log assistant. When given 'interpreted_traits' (list of strings) and 'followup_answers' (dict mapping questions to response strings), "
        "generate a new JSON log entry that matches this schema exactly: {entry_type: \"checkin\" | \"emergency\", interpreted_traits: [...], recommendations: [{trait, goal, activity}], summary: string, followup_questions: [strings]}.")
)

option_agent = Agent(
    name="child_log_option_agent",
    model=AGENT_MODEL,
    description="Generates possible responses to a follow-up question given traits.",
    instruction=(
        "You are an assistant that, when given a JSON object with keys 'question' (string) and 'interpreted_traits' (list of strings), "
        "return a JSON array of three concise strings, each a relevant possible response to the question.")
)
# └────────────────────────────────────────────────────────────────────────────┘

# ─── Async Helpers ────────────────────────────────────────────────────────────┐
async def generate_question_options(runner: Runner, question: str, traits: List[str]) -> List[str]:
    payload = {"question": question, "interpreted_traits": traits}
    content = types.Content(role='user', parts=[types.Part(text=json.dumps(payload))])
    result_text = None
    async for event in runner.run_async(user_id="user_1", session_id="session_001", new_message=content):
        if event.is_final_response() and event.content:
            result_text = event.content.parts[0].text
            break
    if not result_text:
        raise RuntimeError("Failed to generate options for question.")
    return json.loads(strip_code_fences(result_text))

async def generate_new_entry(runner: Runner, traits: List[str], answers: dict) -> str:
    payload = {"interpreted_traits": traits, "followup_answers": answers}
    content = types.Content(role='user', parts=[types.Part(text=json.dumps(payload))])
    raw_text = None
    async for event in runner.run_async(user_id="user_1", session_id="session_001", new_message=content):
        if event.is_final_response() and event.content:
            raw_text = event.content.parts[0].text
            break
    if not raw_text:
        raise RuntimeError("Failed to generate new log entry.")
    return strip_code_fences(raw_text)
# └────────────────────────────────────────────────────────────────────────────┘

# ─── Interactive Flow ─────────────────────────────────────────────────────────┐
async def handle_child_session(child_id: int, runner: Runner, opt_runner: Runner):
    try:
        logs = read_logs(child_id)
    except Exception as e:
        print(f"Error reading logs: {e}")
        return
    if not logs:
        print(f"No logs found for Child ID {child_id}.")
        return
    latest = logs[-1]
    questions = latest.get('followup_questions', [])
    if not questions:
        print("No follow-up questions in the latest log.")
        return

    print("\nPlease choose or type your response to each follow-up question:\n")
    answers = {}
    for q in questions:
        print(f"Question: {q}")
        try:
            opts = await generate_question_options(opt_runner, q, latest['interpreted_traits'])
        except Exception:
            opts = []
        if opts:
            for i, opt in enumerate(opts, 1):
                print(f"  {i}. {opt}")
        resp = input("Your response (enter number or custom text): ").strip()
        if resp.isdigit() and opts and 1 <= int(resp) <= len(opts):
            answers[q] = opts[int(resp) - 1]
        else:
            answers[q] = resp

    print("\nGenerating new recommendations based on your responses...")
    entry_text = await generate_new_entry(runner, latest['interpreted_traits'], answers)
    try:
        new_entry = json.loads(entry_text)
    except json.JSONDecodeError:
        print("Agent output was not valid JSON after cleaning:")
        print(entry_text)
        return

    try:
        append_logs(child_id, new_entry)
        print(f"New log entry appended. Entry type: {new_entry.get('entry_type')}")
    except ValidationError as ve:
        print(f"Validation error: {ve}")
        return
    except Exception as e:
        print(f"Error appending log: {e}")
        return

    print("\nNew Recommendations:")
    for rec in new_entry.get('recommendations', []):
        print(f"- Trait: {rec['trait']} | Goal: {rec['goal']} | Activity: {rec['activity']}")
# └────────────────────────────────────────────────────────────────────────────┘

# ─── Pipeline Runner ───────────────────────────────────────────────────────────┐
async def run_for_child(child_id: int):
    session_service = InMemorySessionService()
    await session_service.create_session(
        app_name="child_log_manager_app", user_id="user_1", session_id=f"session_{child_id}"
    )
    runner = Runner(
        agent=child_log_agent,
        app_name="child_log_manager_app",
        session_service=session_service
    )
    opt_runner = Runner(
        agent=option_agent,
        app_name="child_log_manager_app",
        session_service=session_service
    )
    await handle_child_session(child_id, runner, opt_runner)
# └────────────────────────────────────────────────────────────────────────────┘

if __name__ == '__main__':
    cid = 1
    asyncio.run(run_for_child(cid))
