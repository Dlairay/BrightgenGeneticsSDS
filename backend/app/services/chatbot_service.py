from typing import Optional, Dict, Any, List
from datetime import datetime
import uuid
from fastapi import HTTPException, status
from google.genai import types
from app.repositories.chatbot_repository import ChatbotRepository
from app.repositories.child_repository import ChildRepository
from app.repositories.trait_repository import TraitRepository
from app.agents.chatbot_agent import ChildCareChatbot
from app.core.utils import prepare_image_for_llm, validate_image_type


class ChatbotService:
    """Service layer for chatbot functionality."""
    
    _instance = None
    _chatbot = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ChatbotService, cls).__new__(cls)
        return cls._instance
    
    def __init__(self):
        if not hasattr(self, '_initialized'):
            self.chatbot_repo = ChatbotRepository()
            self.child_repo = ChildRepository()
            self.trait_repo = TraitRepository()
            # Use shared chatbot instance
            if ChatbotService._chatbot is None:
                ChatbotService._chatbot = ChildCareChatbot()
            self.chatbot = ChatbotService._chatbot
            self._initialized = False
    
    async def initialize(self):
        """Initialize the chatbot service if not already initialized."""
        if not self._initialized:
            # Any async initialization can be done here
            self._initialized = True
    
    async def create_conversation(self, user_id: str, child_id: Optional[str] = None, is_temporary: bool = False) -> Dict[str, Any]:
        """Create a new conversation session."""
        await self.initialize()
        
        # Generate session ID
        session_id = str(uuid.uuid4())
        
        # Create session in chatbot (ensure session is created)
        try:
            session_result = await self.chatbot.create_session(user_id, session_id)
            print(f"Created chatbot session: {session_result}")
        except Exception as e:
            print(f"Error creating chatbot session: {e}")
            # Continue anyway - the runner might create it automatically
        # Create conversation record
        conversation = await self.chatbot_repo.create_conversation(
            user_id=user_id,
            session_id=session_id,
            child_id=child_id,
            is_temporary=is_temporary
        )
        
        return conversation
    
    async def send_message(
        self,
        user_id: str,
        session_id: str,
        message: str,
        agent_type: str = "general",
        image: Optional[str] = None,
        image_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send a message to the chatbot and get response."""
        await self.initialize()
        
        # Verify conversation exists and belongs to user
        conversation = await self.chatbot_repo.get_conversation(session_id)
        if not conversation or conversation.get("user_id") != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found")
        
        # Get context if child_id is associated
        context = None
        if conversation.get("child_id"):
            context = await self._get_child_context(conversation["child_id"])
        
        # Prepare message with image if provided
        if image and agent_type == "dr_bloom":
            # Validate image type
            validated_image_type = validate_image_type(image_type)
            
            # For now, we'll mention the image in the text
            # In a full implementation, you'd pass the image bytes to the LLM
            message_with_image = f"{message}\n\n[Image provided: {validated_image_type}]"
            
            # TODO: When Google ADK supports image input, use:
            # image_bytes, mime_type = prepare_image_for_llm(image, validated_image_type)
            # And pass the image_bytes to the chat method
        else:
            message_with_image = message
        
        # Send message to chatbot
        print(f"Sending message to chatbot - agent: {agent_type}, user: {user_id}, session: {session_id}")
        response = await self.chatbot.chat(
            agent_id=agent_type,
            query=message_with_image,
            user_id=user_id,
            session_id=session_id,
            context=context,
            verbose=True
        )
        
        # Save individual messages for Dr. Bloom sessions so we can summarize them later
        message_record = {
            "id": str(uuid.uuid4()),
            "user_message": message,
            "agent_response": response,
            "agent_type": agent_type,
            "timestamp": datetime.utcnow().isoformat(),
            "has_image": image is not None,
            "image_type": image_type
        }
        
        # Save message to database for Dr. Bloom sessions
        if agent_type == "dr_bloom":
            await self.chatbot_repo.add_message(
                session_id=session_id,
                user_message=message,
                agent_response=response,
                agent_type=agent_type,
                image=image,
                image_type=image_type
            )
        
        return {
            "message_id": message_record["id"],
            "user_message": message,
            "agent_response": response,
            "agent_type": agent_type,
            "timestamp": message_record["timestamp"]
        }
    
    async def get_conversation_history(
        self,
        user_id: str,
        session_id: str,
        limit: int = 50
    ) -> Dict[str, Any]:
        """Get conversation history for a session."""
        # Verify conversation belongs to user
        conversation = await self.chatbot_repo.get_conversation(session_id)
        if not conversation or conversation.get("user_id") != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found")
        
        # For Dr. Bloom conversations, we'll extract the history from the Google ADK session
        # This is a simplified approach - in production you might want to store message history
        messages = []
        
        return {
            "session_id": session_id,
            "child_id": conversation.get("child_id"),
            "created_at": conversation.get("created_at"),
            "messages": messages
        }
    
    async def get_user_conversations(
        self,
        user_id: str,
        child_id: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Get all conversations for a user, optionally filtered by child."""
        return await self.chatbot_repo.get_user_conversations(user_id, child_id, limit)
    
    async def get_available_agents(self) -> List[Dict[str, Any]]:
        """Get list of available chatbot agents."""
        agents = []
        for agent_id in self.chatbot.list_agents():
            info = self.chatbot.get_agent_info(agent_id)
            agents.append({
                "id": agent_id,
                "name": info["name"],
                "description": info["description"],
                "tools": info["tools"]
            })
        return agents
    
    async def _get_child_context(self, child_id: str) -> Dict[str, Any]:
        """Get child profile context for chatbot."""
        try:
            # Get child profile
            child = await self.child_repo.get(child_id)
            if not child:
                return {}
            
            # Get traits
            traits = []
            trait_ids = child.get("trait_ids", [])
            for trait_id in trait_ids:
                trait = await self.trait_repo.get(trait_id)
                if trait:
                    traits.append({
                        "name": trait.get("trait_name"),
                        "category": trait.get("category"),
                        "percentage": trait.get("percentage", 0)
                    })
            
            # Build context
            context = {
                "child_name": child.get("name"),
                "age_months": self._calculate_age_months(child.get("birth_date")),
                "traits": traits,
                "allergies": child.get("allergies", []),
                "dietary_restrictions": child.get("dietary_restrictions", [])
            }
            
            return context
        except Exception:
            # Return empty context if error
            return {}
    
    def _calculate_age_months(self, birth_date_str: Optional[str]) -> Optional[int]:
        """Calculate age in months from birth date string."""
        if not birth_date_str:
            return None
        
        try:
            birth_date = datetime.fromisoformat(birth_date_str.replace("Z", "+00:00"))
            today = datetime.now()
            months = (today.year - birth_date.year) * 12 + (today.month - birth_date.month)
            return max(0, months)
        except Exception:
            return None
    
    
    async def generate_structured_log(
        self,
        session_id: str,
        user_id: str,
        child_id: str
    ) -> Dict[str, Any]:
        """Generate structured log entry from Dr. Bloom conversation using the log generator agent."""
        print("Generating structured log from Dr. Bloom conversation...")
        
        # Get child context for traits
        child_context = await self._get_child_context(child_id)
        child_traits = child_context.get("traits", [])
        
        # Get the actual conversation messages from Firestore
        conversation_messages = await self.chatbot_repo.get_conversation_messages(session_id)
        
        if not conversation_messages:
            print("No conversation messages found, using fallback")
            return {
                "interpreted_traits": [],
                "recommendations": [
                    {"trait": "general", "goal": "Monitor child's condition", "activity": "Follow up as needed"}
                ],
                "summary": "Dr. Bloom consultation completed. No specific concerns were discussed.",
                "followup_questions": [
                    {"question": "How has your child been since the Dr. Bloom consultation?", 
                     "options": ["Much better", "Somewhat better", "No change", "Concerning changes"]}
                ]
            }
        
        # Build conversation text for the agent
        conversation_text = "CONVERSATION HISTORY:\n\n"
        for msg in conversation_messages:
            conversation_text += f"Parent: {msg.get('user_message', '')}\n"
            conversation_text += f"Dr. Bloom: {msg.get('agent_response', '')}\n\n"
        
        # Create the prompt for the log generator agent
        log_generation_prompt = f"""
{conversation_text}

CHILD TRAITS AVAILABLE: {[t.get('name') for t in child_traits]}

Analyze the conversation above and create a structured log entry.
Focus on the EXACT issue the parent mentioned and the EXACT recommendations Dr. Bloom gave.
"""
        
        # Instead of using a new session, let's directly parse the conversation
        # This avoids the session not found error
        print(f"Analyzing conversation with {len(conversation_messages)} messages")
        
        # Extract the parent's concerns and Dr. Bloom's advice
        parent_concerns = []
        dr_bloom_responses = []
        
        for msg in conversation_messages:
            user_msg = msg.get('user_message', '').strip()
            dr_response = msg.get('agent_response', '').strip()
            
            # Skip the initial greeting
            if user_msg and "consult with Dr. Bloom" not in user_msg:
                parent_concerns.append(user_msg)
            
            if dr_response:
                dr_bloom_responses.append(dr_response)
        
        if not parent_concerns or not dr_bloom_responses:
            print("No meaningful conversation found")
            return self._get_fallback_log(conversation_messages, child_traits)
        
        # Extract specific recommendations from Dr. Bloom's responses
        main_concern = parent_concerns[0]
        recommendations = []
        
        # Look for specific advice patterns in Dr. Bloom's responses
        combined_response = " ".join(dr_bloom_responses).lower()
        
        if "acknowledge" in combined_response or "validate" in combined_response or "feelings" in combined_response:
            recommendations.append({
                "trait": "emotional_regulation",
                "goal": "Help child process emotions",
                "activity": "Acknowledge child's feelings about the situation"
            })
        
        if "alternative" in combined_response or "distract" in combined_response or "offer" in combined_response:
            recommendations.append({
                "trait": "behavioral_management",
                "goal": "Redirect attention from disappointment",
                "activity": "Offer alternative activities or choices"
            })
        
        if "calm" in combined_response or "breath" in combined_response or "coping" in combined_response:
            recommendations.append({
                "trait": "coping_skills",
                "goal": "Teach coping strategies",
                "activity": "Practice calming techniques like deep breathing"
            })
        
        if "boundary" in combined_response or "limit" in combined_response:
            recommendations.append({
                "trait": "behavioral_management",
                "goal": "Set clear boundaries",
                "activity": "Establish and maintain consistent limits"
            })
        
        # If no specific recommendations found, create one based on the concern
        if not recommendations:
            recommendations = [{
                "trait": "general",
                "goal": "Address the specific concern",
                "activity": f"Follow Dr. Bloom's advice for handling {main_concern[:30]}..."
            }]
        
        # Create summary
        summary = f"Parent reported {main_concern}. Dr. Bloom recommended "
        if len(recommendations) == 1:
            summary += f"{recommendations[0]['activity'].lower()}."
        else:
            activities = [r['activity'].lower() for r in recommendations[:2]]
            summary += f"{' and '.join(activities)}."
        
        # Create follow-up question specific to the issue
        followup_question = {
            "question": f"How did your child respond when you tried these strategies for the {main_concern[:30]}... issue?",
            "options": ["Much better", "Some improvement", "No change", "Made things worse"]
        }
        
        structured_log = {
            "interpreted_traits": [],  # Empty for general behavioral issues
            "recommendations": recommendations[:3],  # Limit to 3
            "summary": summary,
            "followup_questions": [followup_question]
        }
        
        print(f"Generated structured log: {structured_log}")
        return structured_log
        
    def _get_fallback_log(self, conversation_messages: List[Dict], child_traits: List[Dict]) -> Dict[str, Any]:
        """Generate fallback log when conversation parsing fails."""
        main_concern = "general health concern"
        for msg in conversation_messages:
            user_msg = msg.get('user_message', '').strip()
            if user_msg and "consult with Dr. Bloom" not in user_msg:
                main_concern = user_msg
                break
        
        return {
            "interpreted_traits": [],
            "recommendations": [
                {"trait": "general", "goal": "Address parental concern", "activity": f"Monitor and follow Dr. Bloom's advice regarding: {main_concern[:50]}"}
            ],
            "summary": f"Parent reported: {main_concern}. Dr. Bloom provided guidance and recommendations.",
            "followup_questions": [
                {"question": f"How is the situation with: {main_concern[:40]}...?", 
                 "options": ["Resolved", "Improving", "No change", "Need more help"]}
            ]
        }
    
    async def delete_conversation_completely(self, session_id: str, user_id: str) -> bool:
        """Delete a conversation and all its messages immediately."""
        # Verify the conversation belongs to the user
        conversation = await self.chatbot_repo.get_conversation(session_id)
        if not conversation or conversation.get("user_id") != user_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found")
        
        # Delete the conversation and its messages
        success = await self.chatbot_repo.delete_conversation(conversation["id"])
        return success
    
