from typing import Optional, Dict, Any, List
from datetime import datetime
import uuid
import re
import json
from fastapi import HTTPException, status
from app.repositories.chatbot_repository import ChatbotRepository
from app.repositories.child_repository import ChildRepository
from app.repositories.trait_repository import TraitRepository
from app.repositories.medical_log_repository import MedicalLogRepository
from app.agents.chatbot_agent import ChildCareChatbot
from app.agents.medical_visit_agent import MedicalVisitLogGenerator
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
            self.medical_log_repo = MedicalLogRepository()
            self.medical_log_generator = MedicalVisitLogGenerator()
            
            # Use shared chatbot instance
            if ChatbotService._chatbot is None:
                ChatbotService._chatbot = ChildCareChatbot()
            self.chatbot = ChatbotService._chatbot
            self._initialized = False
            self._immunity_regex_loaded = False
    
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
    
    
    async def generate_medical_logs_only(
        self,
        session_id: str,
        user_id: str,
        child_id: str
    ) -> Dict[str, Any]:
        """Generate medical visit logs from Dr. Bloom conversation. Dr. Bloom is now medical-focused only."""
        print("🏥 DR. BLOOM: Checking conversation for medical log generation...")
        
        # Get child context for traits
        child_context = await self._get_child_context(child_id)
        child_traits = child_context.get("traits", [])
        
        # Get the actual conversation messages from Firestore
        conversation_messages = await self.chatbot_repo.get_conversation_messages(session_id)
        
        if not conversation_messages:
            print("❌ No conversation messages found")
            return {
                "medical_logs_created": 0,
                "summary": "Dr. Bloom consultation completed, but no conversation data was found.",
                "status": "no_conversation"
            }
        
        # Build conversation text for analysis
        conversation_text = "CONVERSATION HISTORY:\n\n"
        for msg in conversation_messages:
            conversation_text += f"Parent: {msg.get('user_message', '')}\n"
            conversation_text += f"Dr. Bloom: {msg.get('agent_response', '')}\n\n"
        
        # Check for medical topics - not just immunity anymore
        print(f"🔍 ANALYZING CONVERSATION for medical topics...")
        print(f"🔍 CONVERSATION LENGTH: {len(conversation_text)} characters")
        print(f"🔍 CONVERSATION PREVIEW: {conversation_text[:300]}...")
        
        # Check for immunity-specific mentions
        immunity_mentions = self._check_immunity_mentions(conversation_text)
        print(f"🎯 IMMUNITY MENTIONS: {immunity_mentions}")
        
        # Check for general medical discussion
        has_medical_discussion = self._contains_medical_discussion(conversation_text)
        print(f"🩺 MEDICAL DISCUSSION CHECK: {has_medical_discussion}")
        
        medical_logs_created = 0
        
        # Generate medical log if ANY medical discussion occurred
        if immunity_mentions or has_medical_discussion:
            print(f"🏥 MEDICAL DISCUSSION DETECTED - Creating medical visit log...")
            try:
                medical_log = await self.medical_log_generator.generate_medical_log(
                    child_id=child_id,
                    session_id=session_id,
                    conversation_messages=conversation_messages,
                    child_traits=child_traits,
                    immunity_traits_mentioned=immunity_mentions
                )
                
                print(f"🏥 MEDICAL LOG GENERATED SUCCESSFULLY")
                print(f"🏥 MEDICAL LOG KEYS: {list(medical_log.keys())}")
                
                # Save the medical log
                log_id = await self.medical_log_repo.save_medical_log(medical_log)
                print(f"✅ MEDICAL VISIT LOG SAVED WITH ID: {log_id}")
                medical_logs_created = 1
                
                # Return the actual medical log content
                return {
                    "medical_logs_created": medical_logs_created,
                    "summary": medical_log.get('problem_discussed', 'Medical consultation completed'),
                    "status": "completed",
                    "immunity_traits_detected": immunity_mentions,
                    "medical_log": medical_log,
                    "log_id": log_id
                }
                
            except Exception as e:
                print(f"💥 ERROR GENERATING MEDICAL VISIT LOG:")
                print(f"   Error type: {type(e).__name__}")
                print(f"   Error message: {str(e)}")
                import traceback
                print(f"   Traceback: {traceback.format_exc()}")
        else:
            print(f"ℹ️  NO MEDICAL TOPICS DETECTED - No medical log needed")
        
        return {
            "medical_logs_created": medical_logs_created,
            "summary": "No medical topics were discussed in this consultation.",
            "status": "completed",
            "immunity_traits_detected": immunity_mentions
            # Don't include medical_log field when None to avoid serialization issues
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
    
    def _load_immunity_regex(self):
        """Load the immunity trait regex pattern from config."""
        try:
            with open('app/core/immunity_regex_config.json', 'r') as f:
                config = json.load(f)
                self.immunity_pattern = re.compile(config['pattern'], re.IGNORECASE)
                self.immunity_trait_names = config['trait_names']
                print(f"✅ Loaded immunity regex pattern with {len(self.immunity_trait_names)} trait names")
        except Exception as e:
            print(f"⚠️ Could not load immunity regex config: {e}")
            # Fallback pattern
            self.immunity_pattern = re.compile(
                r'\b(asthma|eczema|uv sensitivity|sun sensitivity|red hair)\b', 
                re.IGNORECASE
            )
            self.immunity_trait_names = []
        finally:
            self._immunity_regex_loaded = True
    
    def _check_immunity_mentions(self, text: str) -> List[str]:
        """Check if immunity traits are mentioned in text."""
        if not self._immunity_regex_loaded:
            self._load_immunity_regex()
        
        print(f"🔍 IMMUNITY REGEX CHECK:")
        print(f"   Text being analyzed: '{text[:200]}...'")
        print(f"   Pattern: {self.immunity_pattern.pattern[:100]}...")
        
        matches = self.immunity_pattern.findall(text)
        print(f"   Raw matches found: {matches}")
        
        # Deduplicate while preserving order
        unique_matches = list(dict.fromkeys(matches))
        print(f"   Unique matches: {unique_matches}")
        
        return unique_matches
    
    def _contains_medical_discussion(self, text: str) -> bool:
        """Check if conversation contains any medical discussion topics."""
        medical_keywords = [
            # Symptoms
            'fever', 'cough', 'rash', 'pain', 'ache', 'hurt', 'sick', 'illness', 
            'vomit', 'nausea', 'diarrhea', 'constipation', 'headache', 'dizzy',
            'tired', 'fatigue', 'sleep', 'appetite', 'eating',
            
            # Medical conditions
            'infection', 'virus', 'bacterial', 'cold', 'flu', 'pneumonia',
            'bronchitis', 'asthma', 'allergies', 'eczema', 'dermatitis',
            'diabetes', 'seizure', 'epilepsy', 'autism', 'adhd',
            
            # Medical terms
            'doctor', 'physician', 'pediatrician', 'hospital', 'clinic',
            'appointment', 'checkup', 'medication', 'medicine', 'treatment',
            'diagnosis', 'symptoms', 'prescription', 'vaccine', 'immunization',
            
            # Body parts/systems
            'breathing', 'respiratory', 'lungs', 'heart', 'stomach', 'digestive',
            'skin', 'eyes', 'ears', 'throat', 'nose', 'brain', 'neurological'
        ]
        
        print(f"🔍 MEDICAL KEYWORD CHECK:")
        print(f"   Text being analyzed: '{text[:200]}...'")
        
        text_lower = text.lower()
        found_keywords = []
        
        for keyword in medical_keywords:
            if keyword in text_lower:
                found_keywords.append(keyword)
                print(f"🩺 MEDICAL KEYWORD DETECTED: '{keyword}'")
        
        print(f"   Total keywords found: {len(found_keywords)} - {found_keywords}")
        
        return len(found_keywords) > 0
    
