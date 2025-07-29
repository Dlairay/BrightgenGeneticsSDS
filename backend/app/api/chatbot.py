from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from app.schemas.chatbot import (
    CreateConversationRequest,
    CreateConversationResponse,
    SendMessageRequest,
    MessageResponse,
    ConversationHistory,
    ConversationSummary,
    AvailableAgentsResponse
)
from app.schemas.user import User
from app.services.chatbot_service import ChatbotService
from app.core.security import get_current_user

router = APIRouter(prefix="/chatbot", tags=["chatbot"])
chatbot_service = ChatbotService()


@router.post("/conversations", response_model=CreateConversationResponse)
async def create_conversation(
    request: CreateConversationRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new chatbot conversation session."""
    try:
        conversation = await chatbot_service.create_conversation(
            user_id=current_user.id,
            child_id=request.child_id
        )
        
        return CreateConversationResponse(
            conversation_id=conversation["id"],
            session_id=conversation["session_id"],
            user_id=conversation["user_id"],
            child_id=conversation.get("child_id"),
            created_at=conversation["created_at"]
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create conversation: {str(e)}"
        )


@router.post("/conversations/{session_id}/messages", response_model=MessageResponse)
async def send_message(
    session_id: str,
    request: SendMessageRequest,
    current_user: User = Depends(get_current_user)
):
    """Send a message to the chatbot and get a response."""
    try:
        response = await chatbot_service.send_message(
            user_id=current_user.id,
            session_id=session_id,
            message=request.message,
            agent_type=request.agent_type,
            image=request.image,
            image_type=request.image_type
        )
        
        return MessageResponse(**response)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send message: {str(e)}"
        )


@router.get("/conversations/{session_id}/history", response_model=ConversationHistory)
async def get_conversation_history(
    session_id: str,
    limit: int = 50,
    current_user: User = Depends(get_current_user)
):
    """Get the conversation history for a session."""
    try:
        history = await chatbot_service.get_conversation_history(
            user_id=current_user.id,
            session_id=session_id,
            limit=limit
        )
        
        return ConversationHistory(**history)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get conversation history: {str(e)}"
        )


@router.get("/conversations", response_model=List[ConversationSummary])
async def get_user_conversations(
    child_id: str = None,
    limit: int = 20,
    current_user: User = Depends(get_current_user)
):
    """Get all conversations for the current user."""
    try:
        conversations = await chatbot_service.get_user_conversations(
            user_id=current_user.id,
            child_id=child_id,
            limit=limit
        )
        
        return [ConversationSummary(**conv) for conv in conversations]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get conversations: {str(e)}"
        )


@router.get("/agents", response_model=AvailableAgentsResponse)
async def get_available_agents(
    current_user: User = Depends(get_current_user)
):
    """Get list of available chatbot agents and their capabilities."""
    try:
        agents = await chatbot_service.get_available_agents()
        return AvailableAgentsResponse(agents=agents)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get available agents: {str(e)}"
        )