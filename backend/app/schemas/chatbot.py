from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class CreateConversationRequest(BaseModel):
    """Request schema for creating a new conversation."""
    child_id: Optional[str] = Field(None, description="Optional child ID to associate with conversation")


class CreateConversationResponse(BaseModel):
    """Response schema for conversation creation."""
    conversation_id: str
    session_id: str
    user_id: str
    child_id: Optional[str]
    created_at: str


class SendMessageRequest(BaseModel):
    """Request schema for sending a message."""
    message: str = Field(..., min_length=1, max_length=5000, description="User message")
    agent_type: str = Field("general", description="Type of agent to use", 
                           pattern="^(general|traits|development|dr_bloom)$")
    image: Optional[str] = Field(None, description="Base64 encoded image")
    image_type: Optional[str] = Field(None, description="MIME type of the image")


class MessageResponse(BaseModel):
    """Response schema for a message."""
    message_id: str
    user_message: str
    agent_response: str
    agent_type: str
    timestamp: str


class ConversationMessage(BaseModel):
    """Schema for a conversation message."""
    id: str
    user_message: str
    agent_response: str
    agent_type: str
    timestamp: str


class ConversationHistory(BaseModel):
    """Response schema for conversation history."""
    session_id: str
    child_id: Optional[str]
    created_at: str
    messages: List[ConversationMessage]


class ConversationSummary(BaseModel):
    """Schema for conversation summary."""
    id: str
    session_id: str
    user_id: str
    child_id: Optional[str]
    created_at: str
    updated_at: str
    message_count: int


class AgentInfo(BaseModel):
    """Schema for agent information."""
    id: str
    name: str
    description: str
    tools: List[str]


class AvailableAgentsResponse(BaseModel):
    """Response schema for available agents."""
    agents: List[AgentInfo]