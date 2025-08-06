"""Configuration for embeddings and RAG system."""

import os
from typing import Optional
from pydantic_settings import BaseSettings


class EmbeddingsConfig(BaseSettings):
    """Configuration for embeddings and RAG system."""
    
    # OpenAI Configuration
    openai_api_key: Optional[str] = None
    openai_embedding_model: str = "text-embedding-ada-002"
    openai_embedding_dimensions: int = 1536
    
    # ChromaDB Configuration
    chroma_persist_directory: str = "app/data/chroma_db"
    chroma_collection_name: str = "developmental_knowledge"
    
    # RAG Configuration
    rag_enabled: bool = True
    rag_chunk_size: int = 500
    rag_chunk_overlap: int = 50
    rag_retrieval_k: int = 5
    rag_score_threshold: float = 0.7
    
    # Knowledge Base Configuration
    knowledge_base_path: str = "app/data/knowledge_base"
    auto_load_knowledge: bool = True
    
    model_config = {
        "env_file": ".env",
        "env_prefix": "RAG_",
        "extra": "ignore"  # Allow extra fields from .env
    }
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # Use OPENAI_API_KEY if RAG_OPENAI_API_KEY is not set
        if not self.openai_api_key:
            self.openai_api_key = os.getenv("OPENAI_API_KEY")
    
    @property
    def is_configured(self) -> bool:
        """Check if RAG system is properly configured."""
        return (
            self.rag_enabled and 
            self.openai_api_key is not None and
            len(self.openai_api_key.strip()) > 0
        )


# Global config instance
embeddings_config = EmbeddingsConfig()