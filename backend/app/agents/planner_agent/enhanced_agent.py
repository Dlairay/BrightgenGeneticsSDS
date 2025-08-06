"""Enhanced planner agent with RAG capabilities."""

import os
import json
import logging
from typing import List, Dict, Any, Union, Optional
from .agent import LogGenerationService, LogEntry
from .rag.retriever import RAGRetriever
from .rag.vector_store import ChromaVectorStore
from .knowledge.loader import KnowledgeLoader

logger = logging.getLogger(__name__)


class EnhancedLogGenerationService:
    """Enhanced log generation service with RAG capabilities."""
    
    def __init__(self, use_rag: bool = True, auto_load_knowledge: bool = True):
        """Initialize enhanced service.
        
        Args:
            use_rag: Whether to use RAG for enhanced recommendations
            auto_load_knowledge: Whether to auto-load knowledge base on first use
        """
        # Original agent service
        self.base_service = LogGenerationService()
        
        # RAG components
        self.use_rag = use_rag
        self.auto_load_knowledge = auto_load_knowledge
        self._rag_initialized = False
        
        if use_rag:
            self.vector_store = ChromaVectorStore()
            self.retriever = RAGRetriever(self.vector_store)
            self.knowledge_loader = KnowledgeLoader(vector_store=self.vector_store)
    
    def _ensure_rag_ready(self) -> bool:
        """Ensure RAG system is initialized and ready."""
        if not self.use_rag:
            return False
        
        if self._rag_initialized:
            return True
        
        try:
            # Check if vector store has data
            doc_count = self.vector_store.get_collection_count()
            
            if doc_count == 0 and self.auto_load_knowledge:
                logger.info("No documents in vector store, auto-loading knowledge base...")
                loaded_count = self.knowledge_loader.load_all_knowledge()
                if loaded_count > 0:
                    logger.info(f"Auto-loaded {loaded_count} documents")
                else:
                    logger.warning("No documents loaded - RAG will be disabled for this session")
                    return False
            
            self._rag_initialized = True
            logger.info(f"RAG system ready with {doc_count} documents")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize RAG system: {e}")
            return False
    
    async def generate_initial_log(
        self,
        traits: List[Dict],
        derived_age: Union[int, None] = None,
        gender: Union[str, None] = None
    ) -> Dict:
        """Generate enhanced initial log with RAG context.
        
        Args:
            traits: List of trait dictionaries
            derived_age: Child's age in months
            gender: Child's gender
            
        Returns:
            Enhanced log entry dictionary
        """
        # Extract trait names for RAG retrieval
        trait_names = [trait.get("trait_name", "") for trait in traits]
        
        # Try to get RAG context
        rag_context = None
        rag_docs_count = 0
        if self._ensure_rag_ready():
            try:
                context = self.retriever.retrieve_for_traits(
                    traits=trait_names,
                    age=derived_age,
                    k=3  # Limit to avoid token overflow
                )
                rag_context = self.retriever.build_context_prompt(context)
                
                # Count documents retrieved
                rag_docs_count = sum(
                    len(trait_ctx) for trait_ctx in context['trait_contexts'].values()
                ) + len(context['general_context']) + len(context['age_specific_context'])
                
                logger.info(f"🔥 RAG ACTIVATED: Retrieved context from {rag_docs_count} documents for initial log")
            except Exception as e:
                logger.warning(f"Failed to retrieve RAG context: {e}")
                rag_context = None
        
        # Generate log with original service
        if rag_context:
            # Enhance the agent's knowledge with RAG context
            original_result = await self._generate_with_rag_context(
                self.base_service.generate_initial_log,
                traits, derived_age, gender, rag_context
            )
        else:
            # Fallback to original generation
            original_result = await self.base_service.generate_initial_log(
                traits, derived_age, gender
            )
        
        # Add RAG metadata with detailed flags
        if isinstance(original_result, dict):
            original_result["rag_enhanced"] = rag_context is not None
            original_result["rag_context_used"] = rag_context is not None
            original_result["rag_documents_found"] = rag_docs_count
            
            # Add visible RAG indicator to summary
            if rag_context and "summary" in original_result:
                original_result["summary"] = f"🔥 RAG-ENHANCED: {original_result['summary']}"
                logger.info(f"✅ RAG SUCCESS: Enhanced log with {rag_docs_count} knowledge documents")
        
        return original_result
    
    async def generate_followup_log(
        self,
        interpreted_traits: List[str],
        answers: Dict[str, str],
        session_id: str,
        log_history: List[dict],
        derived_age: Union[int, None] = None,
        gender: Union[str, None] = None
    ) -> dict:
        """Generate enhanced follow-up log with RAG context.
        
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
        # Try to get RAG context
        rag_context = None
        rag_docs_count = 0
        if self._ensure_rag_ready():
            try:
                context = self.retriever.retrieve_for_traits(
                    traits=interpreted_traits,
                    age=derived_age,
                    k=3
                )
                rag_context = self.retriever.build_context_prompt(context)
                
                # Count documents retrieved
                rag_docs_count = sum(
                    len(trait_ctx) for trait_ctx in context['trait_contexts'].values()
                ) + len(context['general_context']) + len(context['age_specific_context'])
                
                logger.info(f"🔥 RAG ACTIVATED: Retrieved context from {rag_docs_count} documents for follow-up log")
            except Exception as e:
                logger.warning(f"Failed to retrieve RAG context: {e}")
                rag_context = None
        
        # Generate log with context
        if rag_context:
            result = await self._generate_followup_with_rag_context(
                interpreted_traits, answers, session_id, log_history,
                derived_age, gender, rag_context
            )
        else:
            # Fallback to original generation
            result = await self.base_service._generate_followup_entry(
                interpreted_traits, answers, session_id, log_history,
                derived_age, gender
            )
        
        # Add RAG metadata with detailed flags
        if isinstance(result, dict):
            result["rag_enhanced"] = rag_context is not None
            result["rag_context_used"] = rag_context is not None
            result["rag_documents_found"] = rag_docs_count
            
            # Add visible RAG indicator to summary
            if rag_context and "summary" in result:
                result["summary"] = f"🔥 RAG-ENHANCED: {result['summary']}"
                logger.info(f"✅ RAG SUCCESS: Enhanced follow-up log with {rag_docs_count} knowledge documents")
        
        return result
    
    async def _generate_with_rag_context(
        self,
        original_method,
        traits: List[Dict],
        derived_age: Union[int, None],
        gender: Union[str, None],
        rag_context: str
    ) -> Dict:
        """Generate initial log with RAG context injection.
        
        This method temporarily modifies the agent's instruction to include RAG context.
        """
        # Store original instruction
        original_instruction = self.base_service.child_log_agent.instruction
        
        try:
            # Enhance instruction with RAG context
            enhanced_instruction = self._build_enhanced_instruction(
                original_instruction, rag_context
            )
            
            # Temporarily update agent instruction
            self.base_service.child_log_agent.instruction = enhanced_instruction
            
            # Generate with enhanced context
            result = await original_method(traits, derived_age, gender)
            
            return result
            
        finally:
            # Restore original instruction
            self.base_service.child_log_agent.instruction = original_instruction
    
    async def _generate_followup_with_rag_context(
        self,
        interpreted_traits: List[str],
        answers: Dict[str, str],
        session_id: str,
        log_history: List[dict],
        derived_age: Union[int, None],
        gender: Union[str, None],
        rag_context: str
    ) -> dict:
        """Generate follow-up log with RAG context injection."""
        # Store original instruction
        original_instruction = self.base_service.child_log_agent.instruction
        
        try:
            # Enhance instruction with RAG context
            enhanced_instruction = self._build_enhanced_instruction(
                original_instruction, rag_context
            )
            
            # Temporarily update agent instruction
            self.base_service.child_log_agent.instruction = enhanced_instruction
            
            # Generate with enhanced context
            result = await self.base_service._generate_followup_entry(
                interpreted_traits, answers, session_id, log_history,
                derived_age, gender
            )
            
            return result
            
        finally:
            # Restore original instruction
            self.base_service.child_log_agent.instruction = original_instruction
    
    def _build_enhanced_instruction(self, original_instruction: str, rag_context: str) -> str:
        """Build enhanced agent instruction with RAG context.
        
        Args:
            original_instruction: Original agent instruction
            rag_context: RAG context to inject
            
        Returns:
            Enhanced instruction string
        """
        context_injection = f"""

IMPORTANT: Use the following research-backed context to inform your recommendations. 
This context contains evidence-based strategies and activities from developmental research:

{rag_context}

When creating recommendations:
1. Reference specific strategies or activities mentioned in the context when relevant
2. Adapt the research findings to the child's specific traits and age
3. Ensure activities are practical and age-appropriate
4. Maintain the required JSON format while incorporating evidence-based insights

"""
        
        # Insert context before the JSON schema section
        if "Your output must be exactly one JSON object" in original_instruction:
            parts = original_instruction.split("Your output must be exactly one JSON object")
            enhanced = parts[0] + context_injection + "Your output must be exactly one JSON object" + parts[1]
        else:
            enhanced = original_instruction + context_injection
        
        return enhanced
    
    def get_rag_status(self) -> Dict[str, Any]:
        """Get status of RAG system.
        
        Returns:
            Dictionary with RAG system status
        """
        if not self.use_rag:
            return {"enabled": False, "reason": "RAG disabled in configuration"}
        
        try:
            doc_count = self.vector_store.get_collection_count()
            knowledge_stats = self.knowledge_loader.get_knowledge_stats()
            
            return {
                "enabled": True,
                "initialized": self._rag_initialized,
                "document_count": doc_count,
                "knowledge_stats": knowledge_stats,
                "vector_store_path": self.vector_store.persist_directory
            }
        except Exception as e:
            return {
                "enabled": True,
                "initialized": False,
                "error": str(e)
            }
    
    def load_knowledge_base(self, force_reload: bool = False) -> Dict[str, Any]:
        """Manually load knowledge base.
        
        Args:
            force_reload: Whether to force reload existing data
            
        Returns:
            Loading results
        """
        if not self.use_rag:
            return {"success": False, "error": "RAG is disabled"}
        
        try:
            loaded_count = self.knowledge_loader.load_all_knowledge(force_reload)
            self._rag_initialized = True
            
            return {
                "success": True,
                "documents_loaded": loaded_count,
                "force_reload": force_reload
            }
        except Exception as e:
            logger.error(f"Failed to load knowledge base: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def search_knowledge(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """Search the knowledge base.
        
        Args:
            query: Search query
            k: Number of results to return
            
        Returns:
            List of search results
        """
        if not self._ensure_rag_ready():
            return []
        
        try:
            return self.retriever.search_knowledge(query, k=k)
        except Exception as e:
            logger.error(f"Knowledge search failed: {e}")
            return []


# Maintain backward compatibility
__all__ = ["EnhancedLogGenerationService", "LogGenerationService"]