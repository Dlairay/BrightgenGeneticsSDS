from typing import Dict, Any, List, Optional
from datetime import datetime
import uuid
from app.repositories.base_repository import BaseRepository
from google.cloud import firestore


class ChatbotRepository(BaseRepository):
    """Repository for chatbot conversation data."""
    
    def __init__(self):
        super().__init__()
        self.conversations_collection = self.get_collection("conversations")
        self.messages_collection = self.get_collection("messages")
    
    async def create_conversation(
        self,
        user_id: str,
        session_id: str,
        child_id: Optional[str] = None,
        is_temporary: bool = False
    ) -> Dict[str, Any]:
        """Create a new conversation session."""
        conversation_id = str(uuid.uuid4())
        conversation_data = {
            "id": conversation_id,
            "user_id": user_id,
            "session_id": session_id,
            "child_id": child_id,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "message_count": 0,
            "is_dr_bloom": is_temporary  # Rename for clarity - Dr. Bloom sessions are deleted after completion
        }
        
        # Store in Firestore
        self.conversations_collection.document(conversation_id).set(conversation_data)
        
        return conversation_data
    
    async def get_conversation(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get conversation by session ID."""
        # Query by session_id
        conversations = self.conversations_collection.where(
            "session_id", "==", session_id
        ).limit(1).stream()
        
        for conv in conversations:
            return conv.to_dict()
        
        return None
    
    async def get_user_conversations(
        self,
        user_id: str,
        child_id: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Get conversations for a user, optionally filtered by child."""
        query = self.conversations_collection.where(
            "user_id", "==", user_id
        )
        
        if child_id:
            query = query.where("child_id", "==", child_id)
        
        query = query.order_by("created_at", direction=firestore.Query.DESCENDING).limit(limit)
        
        conversations = []
        for doc in query.stream():
            conversations.append(doc.to_dict())
        
        return conversations
    
    async def add_message(
        self,
        session_id: str,
        user_message: str,
        agent_response: str,
        agent_type: str,
        image: Optional[str] = None,
        image_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """Add a message to a conversation."""
        message_id = str(uuid.uuid4())
        message_data = {
            "id": message_id,
            "session_id": session_id,
            "user_message": user_message,
            "agent_response": agent_response,
            "agent_type": agent_type,
            "timestamp": datetime.utcnow().isoformat(),
            "has_image": image is not None,
            "image_type": image_type
        }
        
        # Store image separately if provided (to avoid storing large base64 in message history)
        if image:
            message_data["image_ref"] = f"images/{session_id}/{message_id}"
        
        # Store message
        self.messages_collection.document(message_id).set(message_data)
        
        # Update conversation
        conversation = await self.get_conversation(session_id)
        if conversation:
            self.conversations_collection.document(
                conversation["id"]
            ).update({
                "updated_at": datetime.utcnow().isoformat(),
                "message_count": firestore.Increment(1)
            })
        
        return message_data
    
    async def get_conversation_messages(
        self,
        session_id: str,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get messages for a conversation session."""
        messages = []
        
        # Query without ordering to avoid index requirement
        query = self.messages_collection.where(
            "session_id", "==", session_id
        ).limit(limit)
        
        for doc in query.stream():
            messages.append(doc.to_dict())
        
        # Sort by timestamp in Python instead
        messages.sort(key=lambda x: x.get('timestamp', ''))
        
        return messages
    
    async def delete_conversation(self, conversation_id: str) -> bool:
        """Delete a conversation and its messages."""
        try:
            # Get conversation to find session_id
            conv_doc = self.conversations_collection.document(conversation_id).get()
            if not conv_doc.exists:
                print(f"Conversation {conversation_id} not found for deletion")
                return False
            
            session_id = conv_doc.to_dict().get("session_id")
            
            # Delete all messages
            messages = self.messages_collection.where(
                "session_id", "==", session_id
            ).stream()
            
            batch = self.db.batch()
            message_count = 0
            for msg in messages:
                batch.delete(msg.reference)
                message_count += 1
            
            # Delete conversation
            batch.delete(self.conversations_collection.document(conversation_id))
            
            batch.commit()
            print(f"Deleted conversation {conversation_id} and {message_count} messages")
            return True
        except Exception as e:
            print(f"Error deleting conversation {conversation_id}: {e}")
            return False
    
    async def cleanup_old_dr_bloom_sessions(self, hours_old: int = 1) -> int:
        """Clean up Dr. Bloom sessions older than specified hours."""
        try:
            from datetime import datetime, timedelta
            cutoff_time = (datetime.utcnow() - timedelta(hours=hours_old)).isoformat()
            
            # Find old Dr. Bloom conversations
            old_conversations = self.conversations_collection.where(
                "is_dr_bloom", "==", True
            ).where(
                "created_at", "<", cutoff_time
            ).stream()
            
            deleted_count = 0
            for conv in old_conversations:
                conv_data = conv.to_dict()
                if await self.delete_conversation(conv_data["id"]):
                    deleted_count += 1
            
            if deleted_count > 0:
                print(f"Cleaned up {deleted_count} old Dr. Bloom sessions")
            
            return deleted_count
        except Exception as e:
            print(f"Error during cleanup: {e}")
            return 0