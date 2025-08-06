"""ChromaDB vector store management for planner agent RAG system."""

import os
import logging
from typing import List, Dict, Any, Optional
from langchain.schema import Document
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings

logger = logging.getLogger(__name__)


class ChromaVectorStore:
    """Manages ChromaDB vector store for developmental recommendations."""
    
    def __init__(self, persist_directory: str = None, collection_name: str = "developmental_knowledge"):
        """Initialize ChromaDB vector store.
        
        Args:
            persist_directory: Directory to persist ChromaDB data
            collection_name: Name of the collection to use
        """
        if persist_directory is None:
            persist_directory = os.path.join(
                os.path.dirname(__file__), 
                "../../../data/chroma_db"
            )
        
        self.persist_directory = persist_directory
        self.collection_name = collection_name
        self.embedding_function = OpenAIEmbeddings()
        self._db = None
    
    @property
    def db(self) -> Chroma:
        """Lazy initialization of ChromaDB."""
        if self._db is None:
            try:
                # Try to load existing database
                self._db = Chroma(
                    persist_directory=self.persist_directory,
                    embedding_function=self.embedding_function,
                    collection_name=self.collection_name
                )
                logger.info(f"Loaded existing ChromaDB from {self.persist_directory}")
            except Exception as e:
                logger.warning(f"Could not load existing ChromaDB: {e}")
                # Create new database if loading fails
                self._db = Chroma(
                    persist_directory=self.persist_directory,
                    embedding_function=self.embedding_function,
                    collection_name=self.collection_name
                )
                logger.info(f"Created new ChromaDB at {self.persist_directory}")
        
        return self._db
    
    def embed_documents(self, documents: List[Document]) -> None:
        """Embed documents into the vector store.
        
        Args:
            documents: List of LangChain Document objects to embed
        """
        if not documents:
            logger.warning("No documents provided for embedding")
            return
        
        try:
            # Add documents to existing database
            self.db.add_documents(documents)
            logger.info(f"✅ Embedded {len(documents)} documents into ChromaDB")
        except Exception as e:
            logger.error(f"Failed to embed documents: {e}")
            raise
    
    def embed_knowledge_from_text(
        self,
        text: str,
        metadata: Dict[str, Any],
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> None:
        """Embed text content with metadata into vector store.
        
        Args:
            text: Text content to embed
            metadata: Metadata to associate with the text
            chunk_size: Size of text chunks
            chunk_overlap: Overlap between chunks
        """
        from langchain.text_splitter import RecursiveCharacterTextSplitter
        
        # Split text into chunks
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size, 
            chunk_overlap=chunk_overlap
        )
        chunks = splitter.split_text(text)
        
        # Create documents with metadata
        documents = [
            Document(page_content=chunk, metadata=metadata)
            for chunk in chunks
        ]
        
        self.embed_documents(documents)
        logger.info(f"✅ Embedded {len(documents)} chunks from text with metadata: {metadata}")
    
    def similarity_search(
        self,
        query: str,
        k: int = 5,
        filter_dict: Optional[Dict[str, Any]] = None
    ) -> List[Document]:
        """Search for similar documents.
        
        Args:
            query: Search query
            k: Number of results to return
            filter_dict: Optional metadata filters
            
        Returns:
            List of similar documents
        """
        try:
            if filter_dict:
                results = self.db.similarity_search(query, k=k, filter=filter_dict)
            else:
                results = self.db.similarity_search(query, k=k)
            
            logger.debug(f"Found {len(results)} similar documents for query: {query[:50]}...")
            return results
        except Exception as e:
            logger.error(f"Similarity search failed: {e}")
            return []
    
    def similarity_search_with_score(
        self,
        query: str,
        k: int = 5,
        filter_dict: Optional[Dict[str, Any]] = None
    ) -> List[tuple]:
        """Search for similar documents with similarity scores.
        
        Args:
            query: Search query
            k: Number of results to return
            filter_dict: Optional metadata filters
            
        Returns:
            List of (document, score) tuples
        """
        try:
            if filter_dict:
                results = self.db.similarity_search_with_score(query, k=k, filter=filter_dict)
            else:
                results = self.db.similarity_search_with_score(query, k=k)
            
            logger.debug(f"Found {len(results)} similar documents with scores for query: {query[:50]}...")
            return results
        except Exception as e:
            logger.error(f"Similarity search with score failed: {e}")
            return []
    
    def get_collection_count(self) -> int:
        """Get number of documents in the collection."""
        try:
            return self.db._collection.count()
        except Exception as e:
            logger.error(f"Failed to get collection count: {e}")
            return 0
    
    def delete_collection(self) -> None:
        """Delete the entire collection."""
        try:
            self.db.delete_collection()
            self._db = None  # Reset the database instance
            logger.info(f"Deleted collection: {self.collection_name}")
        except Exception as e:
            logger.error(f"Failed to delete collection: {e}")
            raise