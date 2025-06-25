import os
import sys
import json
import asyncio
from typing import Literal, List # Import List and Literal for Pydantic
from pydantic import BaseModel, ValidationError # Import Pydantic classes

from google.adk.agents import Agent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types
import warnings
import logging
from dotenv import load_dotenv

# Add the parent directory of the current script (which should be 'backend') to sys.path
# This allows importing modules like 'config' from the 'backend' directory
current_script_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(current_script_dir) 
sys.path.insert(0, backend_dir)

# Import config.py and set DATA_DIR
import config
DATA_DIR = config.DATA_DIR


# Ignore all warnings
warnings.filterwarnings("ignore")
# Suppress logs below ERROR
logging.basicConfig(level=logging.ERROR)

# Load environment variables from .env file
load_dotenv()

# ─── 1. Define your Pydantic schemas ───────────────────────────────────────────────
class Recommendation(BaseModel):
    trait: str
    goal: str
    activity: str

class LogStructure(BaseModel):
    # entry_type should be one of "checkin" or "emergency"
    entry_type: Literal["checkin", "emergency"] 
    interpreted_traits: List[str]
    recommendations: List[Recommendation]
    summary: str
    followup_questions: List[str]


# @title Define your tools
def read_logs(ChildID: int) -> str:
    """
    Accesses the logs for a given child ID.
    Args:
        ChildID: The unique integer identifier for the child whose logs are to be read.
    Returns:
        A JSON string of the log data if found, or an error message.
    """
    try:
        logs_fp = os.path.join(DATA_DIR, "child_profiles", f"child_{ChildID}", "logs.json")
        if not os.path.exists(logs_fp):
            return json.dumps({"status": "error", "message": f"Logs file not found for Child ID: {ChildID} at path: {logs_fp}"})
        with open(logs_fp, 'r', encoding='utf-8') as f:
            logs_data = json.load(f)
        return json.dumps({"status": "success", "data": logs_data})
    except json.JSONDecodeError:
        return json.dumps({"status": "error", "message": f"Error: logs.json for Child ID {ChildID} is malformed or empty at path: {logs_fp}."})
    except Exception as e:
        return json.dumps({"status": "error", "message": f"Error reading logs for Child ID {ChildID} at path: {logs_fp}: {str(e)}"})

def append_logs(ChildID: int, log_entry: dict) -> str:
    """
    Appends a new log entry for a given child ID after validating it against LogStructure.
    Args:
        ChildID: The unique integer identifier for the child to append logs for.
        log_entry: A dictionary representing the new log entry, expected to conform to LogStructure.
    Returns:
        A success message or an error message.
    """
    try:
        # Validate the log_entry against the Pydantic schema
        validated_log = LogStructure(**log_entry)
        
        logs_dir = os.path.join(DATA_DIR, "child_profiles", f"child_{ChildID}")
        
        # Check if the child's profile directory exists
        if not os.path.exists(logs_dir):
            return json.dumps({"status": "error", "message": f"Child profile not found for Child ID: {ChildID}. Cannot append logs."})

        logs_fp = os.path.join(logs_dir, "logs.json")

        logs_data = []
        if os.path.exists(logs_fp):
            with open(logs_fp, 'r', encoding='utf-8') as f:
                try:
                    logs_data = json.load(f)
                except json.JSONDecodeError:
                    logs_data = [] # Start with empty list if file is empty or malformed
        
        # Append the validated log entry (converted back to dict)
        logs_data.append(validated_log.dict()) 
        
        with open(logs_fp, 'w', encoding='utf-8') as f:
            json.dump(logs_data, f, indent=2)
        
        return json.dumps({"status": "success", "message": f"Log entry added for child ID {ChildID} for entry type '{validated_log.entry_type}' at path: {logs_fp}."})
    except ValidationError as e:
        return json.dumps({"status": "error", "message": f"Log entry validation failed: {e.errors()}"})
    except Exception as e:
        return json.dumps({"status": "error", "message": f"Error appending log entry for Child ID {ChildID} at path: {logs_fp}: {str(e)}"})


# Create the Agent
AGENT_MODEL = "gemini-2.0-flash"  # Use the correct model name for your environment
APP_NAME = "child_log_manager_app"
USER_ID = "user_1"
SESSION_ID = "session_001"

child_log_agent = Agent(
    name="child_log_agent_v1",
    model=AGENT_MODEL,
    description="Manages and accesses log information for specific children, ensuring all new log entries adhere to a strict structure.",
    instruction=(
        "You are a helpful assistant for managing child logs. "
        "When the user asks to read logs for a specific child, use the 'read_logs' tool. "
        "The child's ID is essential for this. "
        "When the user asks to add a new log entry for a child, use the 'append_logs' tool. "
        "For 'append_logs', you must provide a 'log_entry' as a JSON dictionary that strictly adheres to the following schema:\n"
        "```json\n"
        "{\n"
        "  \"entry_type\": \"checkin\" | \"emergency\",\n"
        "  \"interpreted_traits\": [\"trait1\", \"trait2\"],\n"
        "  \"recommendations\": [\n"
        "    {\"trait\": \"example_trait\", \"goal\": \"example_goal\", \"activity\": \"example_activity\"}\n"
        "  ],\n"
        "  \"summary\": \"A summary of the log entry.\",\n"
        "  \"followup_questions\": [\"Question 1?\", \"Question 2?\"]\n"
        "}\n"
        "```\n"
        "Fill in all fields meaningfully based on the user's request. Always provide all required fields in the JSON.\n"
        "If a tool operation fails, report the error to the user. "
        "If a tool operation succeeds, confirm the action or present the requested data clearly. "
        "Always ask for the Child ID if it's not provided for log operations."
        "The Child ID MUST be a numerical value (e.g., '1', '2'). Do not use text like 'child-one'."
        "When reading logs, provide the content of the logs to the user."
        "When appending logs, confirm that the log was added and mention its entry type."
    ),
    tools=[read_logs, append_logs], 
)

async def call_agent_async(query: str, runner: Runner, user_id: str, session_id: str):
    print(f"\n>>> User Query: {query}")
    content = types.Content(role='user', parts=[types.Part(text=query)])
    final_response = "Agent did not produce a final response."

    async for event in runner.run_async(user_id=user_id, session_id=session_id, new_message=content):
        if event.is_final_response():
            if event.content and event.content.parts:
                final_response = event.content.parts[0].text
            elif getattr(event, 'actions', None) and event.actions.escalate:
                final_response = f"Agent escalated: {event.error_message or 'No specific message.'}"
            break

    print(f"<<< Agent Response: {final_response}")

async def main():
    # Setup session
    session_service = InMemorySessionService()
    session = await session_service.create_session(
        app_name=APP_NAME,
        user_id=USER_ID,
        session_id=SESSION_ID
    )
    print(f"Session created: App='{APP_NAME}', User='{USER_ID}', Session='{SESSION_ID}'")

    # Setup runner
    runner = Runner(
        agent=child_log_agent, 
        app_name=APP_NAME,
        session_service=session_service
    )
    print(f"Runner created for agent '{runner.agent.name}'.")

    # --- Sample interactions with dynamic ChildID ---

    # Test case 1: Read logs for Child ID 1 (ensure child_1/logs.json exists and is valid)
    await call_agent_async("Read the logs for Child ID 1", runner, USER_ID, SESSION_ID)

    # Test case 2: Try to add a VALID structured log for Child ID 1
    # This requires the agent to understand and generate the full JSON structure
    valid_log_query = (
        "Add a new log entry for Child ID 1. It was a checkin. "
        "Interpreted traits: 'Curious', 'Energetic'. "
        "Recommendations: For 'Curious', goal 'Encourage exploration', activity 'Provide new toys'. "
        "Summary: Child had a very active day, showing great curiosity. "
        "Follow-up questions: 'How to channel excess energy?', 'Any new interests observed?'"
    )
    await call_agent_async(valid_log_query, runner, USER_ID, SESSION_ID)

    # Test case 3: Try to add an INVALID structured log (missing a required field, or wrong type)
    # The agent should call append_logs, which will fail validation, and the agent should report this.
    invalid_log_query = (
        "Add an entry for Child ID 1. It was a checkin. "
        "Recommendations: For 'Curious', goal 'Encourage exploration', activity 'Provide new toys'. "
        "Summary: Child had a very active day, showing great curiosity."
        "Follow-up questions: 'How to channel excess energy?', 'Any new interests observed?'"
        # Missing 'interpreted_traits' for demonstration of validation failure
    )
    await call_agent_async(invalid_log_query, runner, USER_ID, SESSION_ID)


    # Test case 4: Read logs for Child ID 2 (still expecting not found as it shouldn't be created)
    await call_agent_async("What's in the logs for Child ID 2?", runner, USER_ID, SESSION_ID)

    # Test case 5: Try to append a log for Child ID 2 (should fail because profile not found)
    await call_agent_async("Add a log for Child ID 2: {'event': 'test', 'summary': 'attempting to log'}", runner, USER_ID, SESSION_ID) # The LLM will still try to generate the full schema here

    # Test case 6: Read logs for Child ID 1 again to see the new valid entry
    await call_agent_async("Read the logs for Child ID 1", runner, USER_ID, SESSION_ID)

    # Original test cases (kept for completeness)
    await call_agent_async("Can you read the logs for Child ID 123?", runner, USER_ID, SESSION_ID) 
    await call_agent_async("Add a new log entry for Child 123: {'event': 'naptime', 'duration': '2 hours', 'notes': 'Slept soundly'}", runner, USER_ID, SESSION_ID)
    await call_agent_async("What's in the logs for Child ID 999?", runner, USER_ID, SESSION_ID)
    await call_agent_async("Can you read some logs?", runner, USER_ID, SESSION_ID)
    await call_agent_async("Read logs for child-one", runner, USER_ID, SESSION_ID)


if __name__ == '__main__':
    asyncio.run(main())
