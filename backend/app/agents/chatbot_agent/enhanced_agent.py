"""RAG-enhanced chatbot agent for medical consultations with immunity & resilience focus."""

import os
import logging
from typing import Dict, List, Any, Optional

# Try to import base chatbot, but make it optional for testing
try:
    from .agent import ChildCareChatbot
except ImportError:
    # Fallback for testing without Google ADK
    class ChildCareChatbot:
        def __init__(self, app_name: str = "childcare_assistant"):
            self.app_name = app_name
            self.agents = {}
            self._create_agents()
        
        def _create_agents(self):
            pass
        
        async def chat(self, agent_id, query, user_id, session_id, context=None, verbose=False):
            return f"[Mock response from {agent_id}]: Processing query - {query[:50]}..."
        
        def list_agents(self):
            return list(self.agents.keys())
        
        def get_agent_info(self, agent_id):
            return {"name": agent_id, "description": "Mock agent", "tools": []}
        
        async def create_session(self, user_id, session_id):
            return {"session_id": session_id, "user_id": user_id}
        
        def create_agent(self, name, description, instruction, tools=None, agent_id=None):
            self.agents[agent_id or name] = {
                "name": name,
                "description": description,
                "instruction": instruction,
                "tools": tools or []
            }
        
        def get_trait_information(self, trait_name):
            return {"trait": trait_name, "info": "Mock trait information"}
        
        def suggest_activities(self, context):
            return ["Mock activity suggestion"]

from ..planner_agent.rag.vector_store import ChromaVectorStore
from ..planner_agent.rag.retriever import RAGRetriever
from ..planner_agent.knowledge.loader import KnowledgeLoader

logger = logging.getLogger(__name__)


class ImmunityRAGRetriever(RAGRetriever):
    """Specialized RAG retriever for immunity & resilience medical knowledge."""
    
    def __init__(self, vector_store: ChromaVectorStore = None):
        """Initialize immunity-focused RAG retriever."""
        # Use separate vector store for medical knowledge
        if vector_store is None:
            vector_store = ChromaVectorStore(
                persist_directory="app/data/chroma_db_medical",
                collection_name="immunity_medical_knowledge"
            )
        super().__init__(vector_store)
    
    def retrieve_medical_context(
        self,
        symptoms: List[str],
        age_months: Optional[int] = None,
        child_traits: Optional[List[str]] = None,
        k: int = 5
    ) -> Dict[str, Any]:
        """Retrieve medical context for symptoms and child profile.
        
        Args:
            symptoms: List of symptoms or concerns mentioned
            age_months: Child's age in months
            child_traits: List of relevant genetic/immunity traits
            k: Number of documents to retrieve
            
        Returns:
            Dictionary with medical context organized by relevance
        """
        context = {
            "symptom_contexts": {},
            "emergency_protocols": [],
            "age_specific_guidance": [],
            "trait_related_info": {}
        }
        
        # Retrieve context for each symptom
        for symptom in symptoms:
            symptom_context = self._retrieve_symptom_context(symptom, age_months, k=3)
            if symptom_context:
                context["symptom_contexts"][symptom] = symptom_context
        
        # Retrieve emergency protocols if urgent keywords detected
        if self._has_emergency_keywords(symptoms):
            emergency_context = self._retrieve_emergency_context(symptoms, k=3)
            context["emergency_protocols"] = emergency_context
        
        # Retrieve age-specific medical guidance
        if age_months:
            age_context = self._retrieve_age_medical_context(age_months, k=2)
            context["age_specific_guidance"] = age_context
        
        # Retrieve trait-related medical information
        if child_traits:
            for trait in child_traits:
                trait_context = self._retrieve_trait_medical_context(trait, k=2)
                if trait_context:
                    context["trait_related_info"][trait] = trait_context
        
        logger.info(f"Retrieved medical context for symptoms: {symptoms}")
        return context
    
    def _retrieve_symptom_context(
        self,
        symptom: str,
        age_months: Optional[int] = None,
        k: int = 3
    ) -> List[Dict[str, Any]]:
        """Retrieve context specific to a symptom."""
        queries = [
            symptom,
            f"{symptom} children",
            f"{symptom} pediatric",
            f"{symptom} treatment"
        ]
        
        # Add age context if available
        if age_months:
            age_years = age_months // 12
            queries.append(f"{symptom} {age_years} year old")
        
        all_results = []
        seen_content = set()
        
        for query in queries:
            results = self.vector_store.similarity_search_with_score(query, k=2)
            
            for doc, score in results:
                if score < 0.7:  # Quality threshold
                    continue
                
                content_hash = hash(doc.page_content[:100])
                if content_hash in seen_content:
                    continue
                seen_content.add(content_hash)
                
                all_results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": score,
                    "query_used": query
                })
        
        all_results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return all_results[:k]
    
    def _has_emergency_keywords(self, symptoms: List[str]) -> bool:
        """Check if symptoms contain emergency keywords."""
        emergency_keywords = [
            "breathing", "can't breathe", "difficulty breathing",
            "choking", "blue lips", "unconscious", "seizure",
            "high fever", "severe pain", "vomiting blood",
            "allergic reaction", "swelling", "rash spreading",
            "emergency", "urgent", "911", "hospital"
        ]
        
        symptoms_text = " ".join(symptoms).lower()
        return any(keyword in symptoms_text for keyword in emergency_keywords)
    
    def _retrieve_emergency_context(self, symptoms: List[str], k: int = 3) -> List[Dict[str, Any]]:
        """Retrieve emergency protocols and red flags."""
        emergency_queries = [
            "emergency symptoms children",
            "when to call 911 pediatric",
            "red flags medical emergency",
            "urgent care vs emergency room"
        ]
        
        all_results = []
        for query in emergency_queries:
            results = self.vector_store.similarity_search_with_score(query, k=2)
            for doc, score in results:
                all_results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": score,
                    "query_used": query
                })
        
        all_results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return all_results[:k]
    
    def _retrieve_age_medical_context(self, age_months: int, k: int = 2) -> List[Dict[str, Any]]:
        """Retrieve age-specific medical guidance."""
        age_years = age_months // 12
        
        age_queries = [
            f"{age_years} year old medical concerns",
            f"pediatric health {age_months} months",
            f"toddler health guidelines" if age_years < 3 else f"preschooler health"
        ]
        
        results = []
        for query in age_queries:
            docs = self.vector_store.similarity_search_with_score(query, k=2)
            for doc, score in docs:
                results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": score,
                    "query_used": query
                })
        
        results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return results[:k]
    
    def _retrieve_trait_medical_context(self, trait: str, k: int = 2) -> List[Dict[str, Any]]:
        """Retrieve medical context for specific genetic/immunity traits."""
        trait_queries = [
            f"{trait} medical implications",
            f"{trait} health risks children",
            f"{trait} pediatric management"
        ]
        
        results = []
        for query in trait_queries:
            docs = self.vector_store.similarity_search_with_score(query, k=2)
            for doc, score in docs:
                results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": score,
                    "query_used": query
                })
        
        results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return results[:k]
    
    def build_medical_context_prompt(self, context: Dict[str, Any]) -> str:
        """Build medical context prompt for Dr. Bloom."""
        prompt_parts = []
        
        # Add emergency protocols if present
        if context["emergency_protocols"]:
            prompt_parts.append("=== EMERGENCY PROTOCOLS ===")
            for item in context["emergency_protocols"][:2]:
                prompt_parts.append(f"🚨 {item['content'][:200]}...")
        
        # Add symptom-specific contexts
        if context["symptom_contexts"]:
            prompt_parts.append("\n=== SYMPTOM-SPECIFIC MEDICAL KNOWLEDGE ===")
            for symptom, symptom_context in context["symptom_contexts"].items():
                if symptom_context:
                    prompt_parts.append(f"\n🔍 Medical guidance for {symptom.upper()}:")
                    for item in symptom_context[:2]:
                        prompt_parts.append(f"• {item['content'][:250]}...")
        
        # Add age-specific guidance
        if context["age_specific_guidance"]:
            prompt_parts.append("\n=== AGE-SPECIFIC MEDICAL GUIDANCE ===")
            for item in context["age_specific_guidance"][:2]:
                prompt_parts.append(f"📅 {item['content'][:200]}...")
        
        # Add trait-related information
        if context["trait_related_info"]:
            prompt_parts.append("\n=== GENETIC/IMMUNITY TRAIT CONSIDERATIONS ===")
            for trait, trait_context in context["trait_related_info"].items():
                if trait_context:
                    prompt_parts.append(f"\n🧬 {trait.upper()} considerations:")
                    for item in trait_context[:1]:
                        prompt_parts.append(f"• {item['content'][:200]}...")
        
        prompt_parts.append("\n=== END MEDICAL CONTEXT ===\n")
        
        return "\n".join(prompt_parts)


class RAGEnhancedChildCareChatbot(ChildCareChatbot):
    """Enhanced chatbot with RAG capabilities for medical consultations."""
    
    def __init__(self, app_name: str = "childcare_rag_assistant"):
        super().__init__(app_name)
        self.use_rag = True
        self.auto_load_knowledge = True
        self._rag_initialized = False
        
        if self.use_rag:
            self.medical_vector_store = ChromaVectorStore(
                persist_directory="app/data/chroma_db_medical",
                collection_name="immunity_medical_knowledge"
            )
            self.medical_retriever = ImmunityRAGRetriever(self.medical_vector_store)
            self.medical_knowledge_loader = KnowledgeLoader(
                knowledge_base_path="app/data/knowledge_base/immunity_resilience",
                vector_store=self.medical_vector_store
            )
    
    def _ensure_medical_rag_ready(self) -> bool:
        """Ensure medical RAG system is initialized."""
        if not self.use_rag:
            return False
        
        if self._rag_initialized:
            return True
        
        try:
            doc_count = self.medical_vector_store.get_collection_count()
            
            if doc_count == 0 and self.auto_load_knowledge:
                logger.info("No medical documents found, auto-loading immunity knowledge...")
                loaded_count = self.medical_knowledge_loader.load_all_knowledge()
                if loaded_count > 0:
                    logger.info(f"Auto-loaded {loaded_count} medical documents")
                else:
                    logger.warning("No medical documents loaded - RAG disabled for medical consultations")
                    return False
            
            self._rag_initialized = True
            logger.info(f"Medical RAG system ready with {doc_count} documents")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize medical RAG system: {e}")
            return False
    
    def _create_agents(self):
        """Override to create RAG-enhanced Dr. Bloom agent."""
        # Create standard agents first
        super()._create_agents()
        
        # Replace Dr. Bloom with RAG-enhanced version
        self.create_agent(
            name="dr_bloom_rag",
            description="RAG-enhanced medical specialist for immunity & resilience concerns",
            instruction=(
                "You are Dr. Bloom, a pediatric medical specialist enhanced with evidence-based medical knowledge. "
                "Keep responses SHORT and ACTIONABLE while being medically accurate.\n\n"
                
                "FORMAT:\n"
                "1. One sentence acknowledgment of concern\n"
                "2. Bullet points of 2-3 specific, evidence-based actions\n"
                "3. Clear guidance on urgency level\n"
                "4. When to seek immediate medical care\n\n"
                
                "MEDICAL PRIORITY LEVELS:\n"
                "🚨 EMERGENCY: Call 911 immediately\n"
                "🏥 URGENT: Seek medical care today\n"
                "📞 ROUTINE: Schedule appointment within days\n"
                "🏠 HOME CARE: Monitor and manage at home\n\n"
                
                "Use the medical context provided to give evidence-based recommendations. "
                "Always prioritize child safety and encourage seeking professional medical care when uncertain.\n\n"
                
                "EXAMPLE:\n"
                "Parent: 'My 2-year-old has been coughing for 3 days with fever'\n"
                "You: 'Persistent cough with fever needs attention. Here's what to do:\n"
                "• Monitor temperature - if over 102°F for 3+ days, see doctor today 🏥\n"
                "• Keep child hydrated with small, frequent sips\n"
                "• Use humidifier or steam from hot shower for cough relief\n"
                "• Seek immediate care if breathing becomes difficult 🚨'\n\n"
                
                "NO LONG EXPLANATIONS. Focus on actionable medical guidance with appropriate urgency indicators."
            ),
            tools=[self.get_trait_information, self.suggest_activities],
            agent_id="dr_bloom"  # Replace the original
        )
    
    async def chat_with_medical_context(
        self,
        query: str,
        user_id: str,
        session_id: str,
        child_profile: Optional[Dict[str, Any]] = None,
        verbose: bool = False
    ) -> Dict[str, Any]:
        """Enhanced chat with medical RAG context for Dr. Bloom."""
        
        # Extract medical information from query and child profile
        symptoms = self._extract_symptoms_from_query(query)
        age_months = child_profile.get('age_months') if child_profile else None
        child_traits = child_profile.get('immunity_traits', []) if child_profile else None
        
        # Try to get medical RAG context
        medical_context = None
        rag_docs_count = 0
        
        if self._ensure_medical_rag_ready() and symptoms:
            try:
                context = self.medical_retriever.retrieve_medical_context(
                    symptoms=symptoms,
                    age_months=age_months,
                    child_traits=child_traits,
                    k=3
                )
                medical_context = self.medical_retriever.build_medical_context_prompt(context)
                
                # Count documents retrieved
                rag_docs_count = (
                    len(context.get('emergency_protocols', [])) +
                    sum(len(ctx) for ctx in context.get('symptom_contexts', {}).values()) +
                    len(context.get('age_specific_guidance', [])) +
                    sum(len(ctx) for ctx in context.get('trait_related_info', {}).values())
                )
                
                logger.info(f"🔥 MEDICAL RAG ACTIVATED: Retrieved context from {rag_docs_count} medical documents")
                
            except Exception as e:
                logger.warning(f"Failed to retrieve medical RAG context: {e}")
                medical_context = None
        
        # Enhance the agent instruction with medical context
        if medical_context and rag_docs_count > 0:
            # Get the Dr. Bloom agent and temporarily enhance its instruction
            original_instruction = self.agents["dr_bloom"].instruction
            
            enhanced_instruction = f"""{original_instruction}

CURRENT MEDICAL CONTEXT (Use this evidence-based information):
{medical_context}

Based on this medical knowledge, provide your response following the SHORT and ACTIONABLE format above.
"""
            
            try:
                # Temporarily update instruction
                self.agents["dr_bloom"].instruction = enhanced_instruction
                
                # Get response with enhanced context
                response = await super().chat(
                    "dr_bloom", query, user_id, session_id, child_profile, verbose
                )
                
                # Add RAG indicators to response
                enhanced_response = f"🔥 RAG-ENHANCED MEDICAL ADVICE:\n{response}"
                
                result = {
                    "response": enhanced_response,
                    "rag_enhanced": True,
                    "rag_medical_documents_used": rag_docs_count,
                    "symptoms_detected": symptoms,
                    "medical_context_length": len(medical_context) if medical_context else 0
                }
                
                logger.info(f"✅ MEDICAL RAG SUCCESS: Enhanced consultation with {rag_docs_count} medical documents")
                
            finally:
                # Restore original instruction
                self.agents["dr_bloom"].instruction = original_instruction
        
        else:
            # Fallback to standard response
            response = await super().chat(
                "dr_bloom", query, user_id, session_id, child_profile, verbose
            )
            
            result = {
                "response": response,
                "rag_enhanced": False,
                "rag_medical_documents_used": 0,
                "symptoms_detected": symptoms,
                "medical_context_length": 0
            }
        
        return result
    
    def _extract_symptoms_from_query(self, query: str) -> List[str]:
        """Extract potential symptoms or medical concerns from user query."""
        # Common medical keywords and symptoms
        medical_keywords = [
            # Symptoms
            "fever", "cough", "rash", "vomiting", "diarrhea", "headache",
            "pain", "swelling", "breathing", "wheezing", "allergic", "reaction",
            "infection", "sick", "illness", "tired", "fatigue", "appetite",
            "sleep", "crying", "fussy", "congestion", "runny nose",
            
            # Emergency terms
            "emergency", "urgent", "911", "hospital", "severe", "can't breathe",
            "unconscious", "seizure", "choking", "blue", "blood",
            
            # Body parts/systems
            "ear", "throat", "stomach", "chest", "skin", "eyes", "nose",
            "mouth", "head", "neck", "back", "arm", "leg"
        ]
        
        query_lower = query.lower()
        detected_symptoms = []
        
        for keyword in medical_keywords:
            if keyword in query_lower:
                detected_symptoms.append(keyword)
        
        # Also look for phrases
        symptom_phrases = [
            "not eating", "won't eat", "difficulty breathing", "trouble sleeping",
            "high fever", "low fever", "sore throat", "ear pain", "stomach ache",
            "throwing up", "can't sleep", "very tired", "won't play"
        ]
        
        for phrase in symptom_phrases:
            if phrase in query_lower:
                detected_symptoms.append(phrase)
        
        return list(set(detected_symptoms))  # Remove duplicates
    
    def get_medical_rag_status(self) -> Dict[str, Any]:
        """Get status of medical RAG system."""
        if not self.use_rag:
            return {"enabled": False, "reason": "Medical RAG disabled"}
        
        try:
            doc_count = self.medical_vector_store.get_collection_count()
            
            return {
                "enabled": True,
                "initialized": self._rag_initialized,
                "medical_document_count": doc_count,
                "vector_store_path": self.medical_vector_store.persist_directory,
                "collection_name": self.medical_vector_store.collection_name
            }
        except Exception as e:
            return {
                "enabled": True,
                "initialized": False,
                "error": str(e)
            }
    
    def load_medical_knowledge(self, force_reload: bool = False) -> Dict[str, Any]:
        """Load medical knowledge base."""
        if not self.use_rag:
            return {"success": False, "error": "Medical RAG is disabled"}
        
        try:
            loaded_count = self.medical_knowledge_loader.load_all_knowledge(force_reload)
            self._rag_initialized = True
            
            return {
                "success": True,
                "medical_documents_loaded": loaded_count,
                "force_reload": force_reload
            }
        except Exception as e:
            logger.error(f"Failed to load medical knowledge base: {e}")
            return {
                "success": False,
                "error": str(e)
            }


# Global instance for medical consultations
medical_chatbot = RAGEnhancedChildCareChatbot()