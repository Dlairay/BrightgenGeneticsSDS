"""Knowledge base loader for planner agent."""

import os
import logging
from typing import List, Dict, Any, Optional
from pathlib import Path
from ..rag.vector_store import ChromaVectorStore
from ..rag.documents import DocumentProcessor

logger = logging.getLogger(__name__)


class KnowledgeLoader:
    """Loads and manages knowledge base for RAG system."""
    
    def __init__(self, knowledge_base_path: str = None, vector_store: ChromaVectorStore = None):
        """Initialize knowledge loader.
        
        Args:
            knowledge_base_path: Path to knowledge base directory
            vector_store: ChromaVectorStore instance
        """
        if knowledge_base_path is None:
            knowledge_base_path = os.path.join(
                os.path.dirname(__file__),
                "../../../data/knowledge_base"
            )
        
        self.knowledge_base_path = knowledge_base_path
        self.vector_store = vector_store or ChromaVectorStore()
        self.document_processor = DocumentProcessor()
    
    def load_all_knowledge(self, force_reload: bool = False) -> int:
        """Load all knowledge base documents into vector store.
        
        Args:
            force_reload: Whether to clear existing data and reload
            
        Returns:
            Number of documents loaded
        """
        if force_reload:
            logger.info("Force reload requested - clearing existing vector store")
            self.vector_store.delete_collection()
        
        # Check if vector store already has data
        existing_count = self.vector_store.get_collection_count()
        if existing_count > 0 and not force_reload:
            logger.info(f"Vector store already contains {existing_count} documents")
            return existing_count
        
        # Process and load documents
        logger.info(f"Loading knowledge base from: {self.knowledge_base_path}")
        documents = self.document_processor.process_knowledge_base(self.knowledge_base_path)
        
        if not documents:
            logger.warning("No documents found in knowledge base")
            return 0
        
        # Embed documents
        self.vector_store.embed_documents(documents)
        
        final_count = self.vector_store.get_collection_count()
        logger.info(f"✅ Successfully loaded {final_count} document chunks into vector store")
        return final_count
    
    def load_category(self, category: str, force_reload: bool = False) -> int:
        """Load documents from a specific category.
        
        Args:
            category: Category to load (e.g., 'developmental_guidelines')
            force_reload: Whether to reload existing documents
            
        Returns:
            Number of documents loaded
        """
        category_path = os.path.join(self.knowledge_base_path, category)
        
        if not os.path.exists(category_path):
            logger.error(f"Category path does not exist: {category_path}")
            return 0
        
        logger.info(f"Loading category: {category}")
        documents = self.document_processor.load_directory(category_path)
        
        if not documents:
            logger.warning(f"No documents found in category: {category}")
            return 0
        
        # Chunk documents
        chunked_docs = self.document_processor.chunk_documents(documents)
        
        # If force_reload, remove existing documents from this category
        if force_reload:
            self._remove_category_documents(category)
        
        # Embed documents
        self.vector_store.embed_documents(chunked_docs)
        
        logger.info(f"✅ Loaded {len(chunked_docs)} chunks from category: {category}")
        return len(chunked_docs)
    
    def add_document_from_text(
        self,
        text: str,
        title: str,
        category: str = "manual",
        metadata: Optional[Dict[str, Any]] = None
    ) -> int:
        """Add a document directly from text.
        
        Args:
            text: Document text content
            title: Document title
            category: Document category
            metadata: Additional metadata
            
        Returns:
            Number of chunks created
        """
        if metadata is None:
            metadata = {}
        
        metadata.update({
            'title': title,
            'category': category,
            'type': 'text',
            'source': 'manual_input'
        })
        
        documents = self.document_processor.create_manual_document(text, metadata)
        self.vector_store.embed_documents(documents)
        
        logger.info(f"✅ Added document '{title}' as {len(documents)} chunks")
        return len(documents)
    
    def get_knowledge_stats(self) -> Dict[str, Any]:
        """Get statistics about the loaded knowledge base.
        
        Returns:
            Dictionary with knowledge base statistics
        """
        total_docs = self.vector_store.get_collection_count()
        
        # Count documents by category (this would require querying metadata)
        stats = {
            'total_documents': total_docs,
            'vector_store_path': self.vector_store.persist_directory,
            'knowledge_base_path': self.knowledge_base_path,
            'categories': self._get_available_categories()
        }
        
        return stats
    
    def _get_available_categories(self) -> List[str]:
        """Get list of available categories in knowledge base."""
        categories = []
        kb_path = Path(self.knowledge_base_path)
        
        if kb_path.exists():
            for item in kb_path.iterdir():
                if item.is_dir() and not item.name.startswith('.'):
                    categories.append(item.name)
        
        return categories
    
    def _remove_category_documents(self, category: str) -> None:
        """Remove all documents from a specific category.
        
        Note: This is a placeholder - ChromaDB doesn't have easy category deletion.
        In practice, you might need to rebuild the entire vector store.
        """
        logger.warning(f"Category-specific deletion not implemented. Consider force_reload=True for entire knowledge base.")
    
    def test_knowledge_retrieval(self, query: str, k: int = 3) -> List[Dict[str, Any]]:
        """Test knowledge retrieval with a sample query.
        
        Args:
            query: Test query
            k: Number of results to return
            
        Returns:
            List of retrieved documents with metadata
        """
        results = self.vector_store.similarity_search_with_score(query, k=k)
        
        formatted_results = []
        for doc, score in results:
            formatted_results.append({
                'content': doc.page_content[:200] + "..." if len(doc.page_content) > 200 else doc.page_content,
                'metadata': doc.metadata,
                'similarity_score': score
            })
        
        return formatted_results