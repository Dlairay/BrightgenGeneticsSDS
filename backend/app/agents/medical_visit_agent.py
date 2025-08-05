"""
Medical Visit Log Agent

This agent generates structured medical visit logs from chat conversations
that discuss immunity & resilience topics. The logs are designed to be
taken to doctor visits for professional follow-up.
"""

import os
import json
import asyncio
import logging
from typing import List, Dict, Optional, Union
from datetime import datetime
from pydantic import BaseModel, Field
from dotenv import load_dotenv

from google.adk.agents import Agent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types

# Load environment variables
load_dotenv()

# Suppress logging noise
logging.basicConfig(level=logging.ERROR)
logging.getLogger('google_adk').setLevel(logging.ERROR)
logging.getLogger('google.adk').setLevel(logging.ERROR)
logging.getLogger('google_genai').setLevel(logging.ERROR)
logging.getLogger('google.genai').setLevel(logging.ERROR)

# Define the medical visit log structure
class MedicalVisitLog(BaseModel):
    child_id: str
    session_id: str
    generation_timestamp: str
    conversation_date: str
    problem_discussed: str  # Simple, clear description of the main issue
    immediate_recommendations: List[str]  # Practical things parents can do now
    follow_up_questions: List[str]  # Questions to ask doctor if they visit
    disclaimer: str  # Medical disclaimer
    immunity_traits_mentioned: List[str]
    emergency_warning: Union[str, None] = None  # Only if urgent symptoms detected

# Model configuration
MODEL = "gemini-2.0-flash"

# Define the agent using ADK
medical_visit_agent = Agent(
    name="medical_visit_log_generator",
    model=MODEL,
    description="Generates structured medical logs from parent-chatbot conversations about immunity issues.",
    instruction="""
You are a helpful assistant that provides immediate, practical support to concerned parents while creating a simple log for their records. Your primary goal is to help parents feel supported with safe, actionable advice they can use right away.

Your task is to:
1. Identify the main problem the parent is concerned about
2. Provide 3-5 practical, immediate recommendations parents can safely try at home
3. Suggest 2-3 specific questions they should ask their doctor if they decide to visit
4. Include a clear medical disclaimer
5. Flag any emergency symptoms that need immediate medical attention

IMPORTANT: Focus on being helpful and practical, not creating detailed medical documentation. Parents want immediate help, not paperwork.

Examples of GOOD problem_discussed:
- "Child has red, itchy patches on arms that worsen at night"
- "Frequent coughing and wheezing after playing outside"
- "Rash appears after eating certain foods"

Examples of GOOD immediate_recommendations:
- "Apply fragrance-free moisturizer to affected areas twice daily"
- "Keep a symptom diary noting time, triggers, and severity"
- "Use cool compresses for 10-15 minutes to reduce itching"
- "Ensure child stays hydrated with water throughout the day"
- "Remove potential allergens like dust mites from bedroom"

Examples of GOOD follow_up_questions:
- "Could this be related to my child's genetic predisposition to eczema?"
- "What allergy tests would you recommend given these symptoms?"
- "Are there preventive medications we should consider?"

Output must be valid JSON with this structure:
{
  "child_id": "string",
  "session_id": "string",
  "generation_timestamp": "ISO timestamp",
  "conversation_date": "ISO timestamp",
  "problem_discussed": "Clear, simple description of the main concern in 1-2 sentences",
  "immediate_recommendations": [
    "Practical action parent can take now",
    "Another safe home remedy or management tip",
    "Monitoring or tracking suggestion"
  ],
  "follow_up_questions": [
    "Specific question to ask doctor",
    "Another relevant medical question"
  ],
  "disclaimer": "This information is for educational purposes only and is not medical advice. Dr. Bloom is an AI assistant, not a licensed medical professional. Always consult with your child's healthcare provider for medical concerns.",
  "immunity_traits_mentioned": ["trait1", "trait2"],
  "emergency_warning": "SEEK IMMEDIATE MEDICAL ATTENTION: [specific reason]" or null
}

Guidelines:
- Be warm, supportive, and practical
- Focus on what parents can DO right now
- Keep recommendations safe and conservative
- Always include the medical disclaimer
- Only set emergency_warning for truly urgent symptoms (difficulty breathing, high fever in infants, severe allergic reactions, etc.)
- Keep the language simple and parent-friendly

Remember: You're here to help worried parents feel supported with practical advice, not to replace their doctor.
Return ONLY valid JSON, no markdown or explanations.
"""
)

def _strip_code_fences(text: str) -> str:
    """Remove code fences from AI responses."""
    if text.startswith("```"):
        parts = text.split("\n", 1)
        if len(parts) > 1:
            text = parts[1]
        if text.endswith("```"):
            text = text[:-3]
    return text.strip()

class MedicalVisitLogGenerator:
    def __init__(self):
        self.agent = medical_visit_agent
        self.app_name = "medical_visit_log_app"
        self.session_service = InMemorySessionService()
        
    async def generate_medical_log(
        self,
        child_id: str,
        session_id: str,
        conversation_messages: List[Dict],
        child_traits: List[Dict],
        immunity_traits_mentioned: List[str]
    ) -> Dict:
        """
        Generate a medical visit log from a chat conversation.
        
        Args:
            child_id: The child's ID
            session_id: The chat session ID
            conversation_messages: List of chat messages
            child_traits: Child's genetic traits (filtered for immunity & resilience)
            immunity_traits_mentioned: List of immunity traits detected in conversation
            
        Returns:
            Structured medical visit log
        """
        print(f"🏥 MEDICAL LOG GENERATION START:")
        print(f"   Child ID: {child_id}")
        print(f"   Session ID: {session_id}")
        print(f"   Messages count: {len(conversation_messages)}")
        print(f"   Child traits count: {len(child_traits)}")
        print(f"   Immunity traits mentioned: {immunity_traits_mentioned}")
        
        # Filter traits to only immunity & resilience archetype
        relevant_traits = [
            {
                "trait_name": trait.get("trait_name", ""),
                "description": trait.get("description", ""),
                "gene": trait.get("gene", ""),
                "confidence": trait.get("confidence", "")
            }
            for trait in child_traits
            if trait.get("archetype", "").lower() == "immunity & resilience"
        ]
        
        print(f"🧬 FILTERED IMMUNITY TRAITS: {len(relevant_traits)} traits")
        for trait in relevant_traits:
            print(f"   - {trait.get('trait_name')}")
        
        # Prepare the conversation for analysis
        conversation_text = self._format_conversation(conversation_messages)
        print(f"💬 CONVERSATION TEXT LENGTH: {len(conversation_text)} characters")
        print(f"💬 CONVERSATION PREVIEW: {conversation_text[:200]}...")
        
        # Create the payload for the agent
        payload = {
            "child_id": child_id,
            "session_id": session_id,
            "conversation_date": datetime.now().isoformat(),
            "immunity_traits_mentioned": immunity_traits_mentioned,
            "relevant_genetic_traits": relevant_traits,
            "conversation": conversation_text
        }
        
        print(f"📦 PAYLOAD PREPARED: {len(json.dumps(payload))} characters")
        
        try:
            print(f"🤖 CREATING MEDICAL VISIT AGENT RUNNER...")
            # Create runner for the agent
            runner = Runner(
                agent=self.agent,
                app_name=self.app_name,
                session_service=self.session_service
            )
            print(f"✅ RUNNER CREATED SUCCESSFULLY")
            
            # Create the message content
            content = types.Content(
                role='user',
                parts=[types.Part(text=json.dumps(payload))]
            )
            print(f"📨 MESSAGE CONTENT CREATED")
            
            # Create session first
            medical_session_id = f"medical_log_{session_id}"
            print(f"🔧 CREATING SESSION: {medical_session_id}")
            
            await self.session_service.create_session(
                app_name=self.app_name,
                user_id="medical_log_user", 
                session_id=medical_session_id
            )
            print(f"✅ SESSION CREATED: {medical_session_id}")
            
            # Run the agent
            print(f"🚀 STARTING AGENT EXECUTION...")
            result = None
            event_count = 0
            async for ev in runner.run_async(
                user_id="medical_log_user",
                session_id=medical_session_id,
                new_message=content
            ):
                event_count += 1
                print(f"📡 EVENT {event_count}: Type={type(ev).__name__}, is_final={ev.is_final_response()}")
                
                if ev.is_final_response() and ev.content:
                    result = ev.content.parts[0].text
                    print(f"✅ FINAL RESPONSE RECEIVED: {len(result)} characters")
                    print(f"📄 RESPONSE PREVIEW: {result[:200]}...")
                    break
            
            print(f"🔍 AGENT EXECUTION COMPLETE. Events processed: {event_count}")
            
            if not result:
                print(f"❌ NO RESPONSE FROM AGENT")
                raise ValueError("No response from medical visit agent")
            
            # Parse the response
            print(f"🧹 CLEANING RESPONSE...")
            cleaned = _strip_code_fences(result)
            print(f"📋 CLEANED RESPONSE: {len(cleaned)} characters")
            print(f"📋 CLEANED PREVIEW: {cleaned[:300]}...")
            
            print(f"🔧 PARSING JSON...")
            medical_log = json.loads(cleaned)
            print(f"✅ JSON PARSED SUCCESSFULLY")
            
            # Ensure all required fields are present
            medical_log['child_id'] = child_id
            medical_log['session_id'] = session_id
            medical_log['generation_timestamp'] = datetime.now().isoformat()
            
            # Make sure we have the immunity traits mentioned
            if 'immunity_traits_mentioned' not in medical_log:
                medical_log['immunity_traits_mentioned'] = immunity_traits_mentioned
            
            # Ensure disclaimer is present
            if 'disclaimer' not in medical_log:
                medical_log['disclaimer'] = "This information is for educational purposes only and is not medical advice. Dr. Bloom is an AI assistant, not a licensed medical professional. Always consult with your child's healthcare provider for medical concerns."
            
            return medical_log
                
        except Exception as e:
            print(f"💥 MEDICAL LOG GENERATION ERROR:")
            print(f"   Error type: {type(e).__name__}")
            print(f"   Error message: {str(e)}")
            import traceback
            print(f"   Traceback: {traceback.format_exc()}")
            
            # Return a basic log structure on error
            error_log = {
                "child_id": child_id,
                "session_id": session_id,
                "generation_timestamp": datetime.now().isoformat(),
                "conversation_date": datetime.now().isoformat(),
                "problem_discussed": "Unable to process conversation due to technical error",
                "immediate_recommendations": [
                    "Please consult with your healthcare provider directly",
                    "Keep monitoring your child's symptoms",
                    "Document any changes or new symptoms"
                ],
                "follow_up_questions": [
                    "Please share your concerns directly with your doctor"
                ],
                "disclaimer": "This information is for educational purposes only and is not medical advice. Dr. Bloom is an AI assistant, not a licensed medical professional. Always consult with your child's healthcare provider for medical concerns.",
                "immunity_traits_mentioned": immunity_traits_mentioned,
                "emergency_warning": None,
                "error": str(e)
            }
            print(f"🔄 RETURNING ERROR LOG STRUCTURE")
            return error_log
    
    def _format_conversation(self, messages: List[Dict]) -> str:
        """Format conversation messages for analysis."""
        formatted = []
        for msg in messages:
            if msg.get("user_message"):
                formatted.append(f"Parent: {msg.get('user_message')}")
            if msg.get("agent_response"):
                formatted.append(f"Dr. Bloom: {msg.get('agent_response')}")
        return "\n\n".join(formatted)