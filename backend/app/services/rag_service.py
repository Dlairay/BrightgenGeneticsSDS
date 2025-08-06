"""RAG service for integrating with existing service layer."""

import logging
from typing import List, Dict, Any, Optional
from ..agents.planner_agent.enhanced_agent import EnhancedLogGenerationService
from ..core.embeddings_config import embeddings_config

logger = logging.getLogger(__name__)


class RAGService:
    """Service layer for RAG operations."""
    
    def __init__(self):
        """Initialize RAG service."""
        self._enhanced_service = None
        self._initialized = False
    
    @property
    def enhanced_service(self) -> EnhancedLogGenerationService:
        """Lazy initialization of enhanced service."""
        if self._enhanced_service is None:
            self._enhanced_service = EnhancedLogGenerationService(
                use_rag=embeddings_config.rag_enabled,
                auto_load_knowledge=embeddings_config.auto_load_knowledge
            )
        return self._enhanced_service
    
    async def generate_enhanced_initial_log(
        self,
        traits: List[Dict],
        derived_age: Optional[int] = None,
        gender: Optional[str] = None
    ) -> Dict:
        """Generate enhanced initial log using RAG.
        
        Args:
            traits: List of trait dictionaries
            derived_age: Child's age in months
            gender: Child's gender
            
        Returns:
            Enhanced log entry dictionary
        """
        try:
            return await self.enhanced_service.generate_initial_log(
                traits, derived_age, gender
            )
        except Exception as e:
            logger.error(f"RAG-enhanced log generation failed: {e}")
            # Fallback to original service
            from ..agents.planner_agent.agent import LogGenerationService
            fallback_service = LogGenerationService()
            return await fallback_service.generate_initial_log(traits, derived_age, gender)
    
    async def generate_enhanced_followup_log(
        self,
        interpreted_traits: List[str],
        answers: Dict[str, str],
        session_id: str,
        log_history: List[dict],
        derived_age: Optional[int] = None,
        gender: Optional[str] = None
    ) -> dict:
        """Generate enhanced follow-up log using RAG.
        
        Args:
            interpreted_traits: List of trait names
            answers: Follow-up question answers
            session_id: Session identifier
            log_history: Previous log entries
            derived_age: Child's age in months
            gender: Child's gender
            
        Returns:
            Enhanced log entry dictionary
        """
        try:
            return await self.enhanced_service.generate_followup_log(
                interpreted_traits, answers, session_id, log_history,
                derived_age, gender
            )
        except Exception as e:
            logger.error(f"RAG-enhanced followup log generation failed: {e}")
            # Fallback to original service
            from ..agents.planner_agent.agent import LogGenerationService
            fallback_service = LogGenerationService()
            return await fallback_service._generate_followup_entry(
                interpreted_traits, answers, session_id, log_history,
                derived_age, gender
            )
    
    def get_rag_status(self) -> Dict[str, Any]:
        """Get RAG system status.
        
        Returns:
            Dictionary with RAG system status information
        """
        try:
            return self.enhanced_service.get_rag_status()
        except Exception as e:
            logger.error(f"Failed to get RAG status: {e}")
            return {
                "enabled": False,
                "error": str(e),
                "configuration": {
                    "rag_enabled": embeddings_config.rag_enabled,
                    "openai_configured": bool(embeddings_config.openai_api_key),
                    "knowledge_base_path": embeddings_config.knowledge_base_path
                }
            }
    
    def search_knowledge(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """Search the knowledge base.
        
        Args:
            query: Search query
            k: Number of results to return
            
        Returns:
            List of search results
        """
        try:
            return self.enhanced_service.search_knowledge(query, k)
        except Exception as e:
            logger.error(f"Knowledge search failed: {e}")
            return []
    
    def load_knowledge_base(self, force_reload: bool = False) -> Dict[str, Any]:
        """Load knowledge base into vector store.
        
        Args:
            force_reload: Whether to force reload existing data
            
        Returns:
            Loading results
        """
        try:
            return self.enhanced_service.load_knowledge_base(force_reload)
        except Exception as e:
            logger.error(f"Knowledge base loading failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def is_rag_enabled(self) -> bool:
        """Check if RAG is enabled and configured.
        
        Returns:
            Whether RAG is enabled and properly configured
        """
        return embeddings_config.is_configured


# Global RAG service instance
rag_service = RAGService()