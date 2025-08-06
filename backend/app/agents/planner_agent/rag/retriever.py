"""RAG retriever service for enhanced recommendations."""

import logging
from typing import List, Dict, Any, Optional, Tuple
from .vector_store import ChromaVectorStore

logger = logging.getLogger(__name__)


class RAGRetriever:
    """Retrieves relevant context for developmental recommendations."""
    
    def __init__(self, vector_store: ChromaVectorStore = None):
        """Initialize RAG retriever.
        
        Args:
            vector_store: ChromaVectorStore instance
        """
        self.vector_store = vector_store or ChromaVectorStore()
    
    def retrieve_for_traits(
        self,
        traits: List[str],
        age: Optional[int] = None,
        k: int = 5,
        min_score_threshold: float = 0.7
    ) -> Dict[str, Any]:
        """Retrieve relevant context for specific traits.
        
        Args:
            traits: List of genetic traits
            age: Child's age in months
            k: Number of documents to retrieve per trait
            min_score_threshold: Minimum similarity score threshold
            
        Returns:
            Dictionary with retrieved context organized by trait
        """
        context = {
            "trait_contexts": {},
            "general_context": [],
            "age_specific_context": []
        }
        
        # Retrieve context for each trait
        for trait in traits:
            trait_context = self._retrieve_trait_context(
                trait, age, k, min_score_threshold
            )
            if trait_context:
                context["trait_contexts"][trait] = trait_context
        
        # Retrieve general developmental context
        if age:
            general_context = self._retrieve_age_context(age, k=3)
            context["general_context"] = general_context
            
            age_specific = self._retrieve_age_specific_activities(age, k=3)
            context["age_specific_context"] = age_specific
        
        logger.info(f"Retrieved context for {len(traits)} traits with age {age}")
        return context
    
    def _retrieve_trait_context(
        self,
        trait: str,
        age: Optional[int] = None,
        k: int = 5,
        min_score_threshold: float = 0.7
    ) -> List[Dict[str, Any]]:
        """Retrieve context specific to a trait.
        
        Args:
            trait: Genetic trait name
            age: Child's age in months
            k: Number of documents to retrieve
            min_score_threshold: Minimum similarity score
            
        Returns:
            List of relevant context documents
        """
        # Create search queries for the trait
        queries = [
            trait,
            f"{trait} development",
            f"{trait} activities",
            f"{trait} intervention strategies"
        ]
        
        all_results = []
        seen_content = set()
        
        for query in queries:
            # Add age context to query if available
            if age:
                age_years = age // 12
                age_query = f"{query} age {age_years} years child development"
            else:
                age_query = query
            
            results = self.vector_store.similarity_search_with_score(
                age_query, k=k//len(queries) + 1
            )
            
            for doc, score in results:
                # Filter by score threshold
                if score < min_score_threshold:
                    continue
                
                # Avoid duplicate content
                content_hash = hash(doc.page_content[:100])
                if content_hash in seen_content:
                    continue
                seen_content.add(content_hash)
                
                all_results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": score,
                    "query_used": age_query
                })
        
        # Sort by similarity score and return top k
        all_results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return all_results[:k]
    
    def _retrieve_age_context(self, age: int, k: int = 3) -> List[Dict[str, Any]]:
        """Retrieve general developmental context for age.
        
        Args:
            age: Child's age in months
            k: Number of documents to retrieve
            
        Returns:
            List of age-relevant context documents
        """
        age_years = age // 12
        age_months_remainder = age % 12
        
        queries = [
            f"{age_years} year old development milestones",
            f"early childhood {age_years}-{age_years+1} years",
            f"developmental activities {age} months old"
        ]
        
        results = []
        for query in queries:
            docs = self.vector_store.similarity_search_with_score(query, k=k//len(queries) + 1)
            for doc, score in docs:
                results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": score,
                    "query_used": query
                })
        
        # Remove duplicates and sort by score
        unique_results = []
        seen_content = set()
        
        for result in results:
            content_hash = hash(result["content"][:100])
            if content_hash not in seen_content:
                seen_content.add(content_hash)
                unique_results.append(result)
        
        unique_results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return unique_results[:k]
    
    def _retrieve_age_specific_activities(self, age: int, k: int = 3) -> List[Dict[str, Any]]:
        """Retrieve age-appropriate activities.
        
        Args:
            age: Child's age in months
            k: Number of documents to retrieve
            
        Returns:
            List of age-appropriate activity documents
        """
        age_years = age // 12
        
        queries = [
            f"activities for {age_years} year old children",
            f"cognitive games {age_years}-{age_years+1} years",
            f"educational activities {age} months development"
        ]
        
        # Filter by category if possible
        activity_filter = {"category": "cognitive"}
        
        results = []
        for query in queries:
            try:
                docs = self.vector_store.similarity_search_with_score(
                    query, k=k//len(queries) + 1, filter_dict=activity_filter
                )
            except:
                # Fallback without filter if filtering fails
                docs = self.vector_store.similarity_search_with_score(query, k=k//len(queries) + 1)
            
            for doc, score in docs:
                results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": score,
                    "query_used": query
                })
        
        # Sort and deduplicate
        unique_results = []
        seen_content = set()
        
        for result in results:
            content_hash = hash(result["content"][:100])
            if content_hash not in seen_content:
                seen_content.add(content_hash)
                unique_results.append(result)
        
        unique_results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return unique_results[:k]
    
    def build_context_prompt(self, context: Dict[str, Any]) -> str:
        """Build a formatted prompt with retrieved context.
        
        Args:
            context: Context dictionary from retrieve_for_traits
            
        Returns:
            Formatted context string for agent prompt
        """
        prompt_parts = []
        
        # Add trait-specific contexts
        if context["trait_contexts"]:
            prompt_parts.append("=== TRAIT-SPECIFIC RESEARCH CONTEXT ===")
            for trait, trait_context in context["trait_contexts"].items():
                if trait_context:
                    prompt_parts.append(f"\n📊 Research for {trait.upper()}:")
                    for item in trait_context[:2]:  # Limit to top 2 results per trait
                        prompt_parts.append(f"• {item['content'][:300]}...")
                        if item['metadata'].get('title'):
                            prompt_parts.append(f"  Source: {item['metadata']['title']}")
        
        # Add general age context
        if context["general_context"]:
            prompt_parts.append("\n=== AGE-APPROPRIATE DEVELOPMENT CONTEXT ===")
            for item in context["general_context"][:2]:
                prompt_parts.append(f"• {item['content'][:250]}...")
        
        # Add age-specific activities
        if context["age_specific_context"]:
            prompt_parts.append("\n=== EVIDENCE-BASED ACTIVITIES ===")
            for item in context["age_specific_context"][:2]:
                prompt_parts.append(f"• {item['content'][:250]}...")
        
        prompt_parts.append("\n=== END CONTEXT ===\n")
        
        return "\n".join(prompt_parts)
    
    def search_knowledge(
        self,
        query: str,
        category_filter: Optional[str] = None,
        k: int = 5
    ) -> List[Dict[str, Any]]:
        """General knowledge search interface.
        
        Args:
            query: Search query
            category_filter: Optional category to filter by
            k: Number of results to return
            
        Returns:
            List of search results
        """
        filter_dict = {"category": category_filter} if category_filter else None
        
        results = self.vector_store.similarity_search_with_score(
            query, k=k, filter_dict=filter_dict
        )
        
        formatted_results = []
        for doc, score in results:
            formatted_results.append({
                "content": doc.page_content,
                "metadata": doc.metadata,
                "similarity_score": score
            })
        
        return formatted_results