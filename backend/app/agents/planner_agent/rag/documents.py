"""Document processing utilities for RAG system."""

import os
import logging
from typing import List, Dict, Any, Optional
from pathlib import Path
from langchain.schema import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader, UnstructuredHTMLLoader, TextLoader
from langchain_community.document_loaders.base import BaseLoader

logger = logging.getLogger(__name__)


class DocumentProcessor:
    """Processes documents for embedding into vector store."""
    
    def __init__(self, chunk_size: int = 500, chunk_overlap: int = 50):
        """Initialize document processor.
        
        Args:
            chunk_size: Size of text chunks for embedding
            chunk_overlap: Overlap between consecutive chunks
        """
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            length_function=len,
            separators=["\n\n", "\n", " ", ""]
        )
    
    def load_pdf(self, file_path: str) -> List[Document]:
        """Load a single PDF file.
        
        Args:
            file_path: Path to the PDF file
            
        Returns:
            List of Document objects
        """
        try:
            loader = PyPDFLoader(file_path)
            documents = loader.load()
            
            # Add file metadata
            file_name = Path(file_path).stem
            category = self._extract_category_from_path(file_path)
            
            for doc in documents:
                doc.metadata.update({
                    'source': file_path,
                    'filename': file_name,
                    'category': category,
                    'type': 'pdf'
                })
            
            logger.info(f"Loaded {len(documents)} pages from {file_path}")
            return documents
        except Exception as e:
            logger.error(f"Failed to load PDF {file_path}: {e}")
            return []
    
    def load_html(self, file_path: str) -> List[Document]:
        """Load a single HTML file.
        
        Args:
            file_path: Path to the HTML file
            
        Returns:
            List of Document objects
        """
        try:
            loader = UnstructuredHTMLLoader(file_path)
            documents = loader.load()
            
            # Add file metadata
            file_name = Path(file_path).stem
            category = self._extract_category_from_path(file_path)
            
            for doc in documents:
                doc.metadata.update({
                    'source': file_path,
                    'filename': file_name,
                    'category': category,
                    'type': 'html'
                })
            
            logger.info(f"Loaded HTML content from {file_path}")
            return documents
        except Exception as e:
            logger.error(f"Failed to load HTML {file_path}: {e}")
            return []
    
    def load_txt(self, file_path: str) -> List[Document]:
        """Load a single TXT file.
        
        Args:
            file_path: Path to the TXT file
            
        Returns:
            List of Document objects
        """
        try:
            loader = TextLoader(file_path, encoding='utf-8')
            documents = loader.load()
            
            # Add file metadata
            file_name = Path(file_path).stem
            category = self._extract_category_from_path(file_path)
            
            for doc in documents:
                doc.metadata.update({
                    'source': file_path,
                    'filename': file_name,
                    'category': category,
                    'type': 'txt'
                })
            
            logger.info(f"Loaded TXT content from {file_path}")
            return documents
        except Exception as e:
            logger.error(f"Failed to load TXT {file_path}: {e}")
            return []
    
    def load_file(self, file_path: str) -> List[Document]:
        """Load a file (PDF, HTML, or TXT) based on its extension.
        
        Args:
            file_path: Path to the file
            
        Returns:
            List of Document objects
        """
        file_extension = Path(file_path).suffix.lower()
        
        if file_extension == '.pdf':
            return self.load_pdf(file_path)
        elif file_extension in ['.html', '.htm']:
            return self.load_html(file_path)
        elif file_extension == '.txt':
            return self.load_txt(file_path)
        else:
            logger.warning(f"Unsupported file type: {file_extension} for {file_path}")
            return []
    
    def load_directory(self, directory_path: str, file_patterns: List[str] = None) -> List[Document]:
        """Load all supported files from a directory.
        
        Args:
            directory_path: Path to directory containing files
            file_patterns: List of glob patterns to match (default: PDFs and HTML)
            
        Returns:
            List of Document objects
        """
        if file_patterns is None:
            file_patterns = ["**/*.pdf", "**/*.html", "**/*.htm", "**/*.txt"]
        
        all_documents = []
        
        for pattern in file_patterns:
            try:
                # Determine loader class based on pattern
                if pattern.endswith(('.pdf',)):
                    loader_cls = PyPDFLoader
                    file_type = 'pdf'
                elif pattern.endswith(('.html', '.htm')):
                    loader_cls = UnstructuredHTMLLoader
                    file_type = 'html'
                elif pattern.endswith(('.txt',)):
                    loader_cls = TextLoader
                    file_type = 'txt'
                else:
                    continue
                
                loader = DirectoryLoader(
                    directory_path,
                    glob=pattern,
                    loader_cls=loader_cls,
                    show_progress=True
                )
                documents = loader.load()
                
                # Add metadata based on directory structure and file type
                for doc in documents:
                    category = self._extract_category_from_path(doc.metadata.get('source', ''))
                    doc.metadata.update({
                        'category': category,
                        'type': file_type
                    })
                
                all_documents.extend(documents)
                logger.info(f"Loaded {len(documents)} {file_type.upper()} documents from {directory_path}")
                
            except Exception as e:
                logger.error(f"Failed to load {pattern} from {directory_path}: {e}")
                continue
        
        logger.info(f"Total loaded {len(all_documents)} documents from {directory_path}")
        return all_documents
    
    def chunk_documents(self, documents: List[Document]) -> List[Document]:
        """Split documents into smaller chunks for embedding.
        
        Args:
            documents: List of documents to chunk
            
        Returns:
            List of chunked documents
        """
        if not documents:
            return []
        
        try:
            chunked_docs = self.text_splitter.split_documents(documents)
            
            # Add chunk metadata
            for i, doc in enumerate(chunked_docs):
                doc.metadata.update({
                    'chunk_id': i,
                    'total_chunks': len(chunked_docs)
                })
            
            logger.info(f"Split {len(documents)} documents into {len(chunked_docs)} chunks")
            return chunked_docs
        except Exception as e:
            logger.error(f"Failed to chunk documents: {e}")
            return documents
    
    def process_knowledge_base(self, knowledge_base_path: str) -> List[Document]:
        """Process entire knowledge base directory.
        
        Args:
            knowledge_base_path: Path to knowledge base directory
            
        Returns:
            List of processed and chunked documents
        """
        all_documents = []
        
        # Process each subdirectory
        knowledge_path = Path(knowledge_base_path)
        if not knowledge_path.exists():
            logger.error(f"Knowledge base path does not exist: {knowledge_base_path}")
            return []
        
        for subdir in knowledge_path.iterdir():
            if subdir.is_dir() and not subdir.name.startswith('.'):
                logger.info(f"Processing directory: {subdir.name}")
                docs = self.load_directory(str(subdir))
                all_documents.extend(docs)
        
        # Chunk all documents
        chunked_docs = self.chunk_documents(all_documents)
        
        logger.info(f"Processed knowledge base: {len(all_documents)} documents → {len(chunked_docs)} chunks")
        return chunked_docs
    
    def _extract_category_from_path(self, file_path: str) -> str:
        """Extract category from file path based on directory structure.
        
        Args:
            file_path: Full path to the file
            
        Returns:
            Category string
        """
        path_parts = Path(file_path).parts
        
        # Look for known category directories
        categories = {
            'developmental_guidelines': 'developmental',
            'nutrition_research': 'nutrition',
            'cognitive_behavioral': 'cognitive_behavioral',
            'immunity_resilience': 'immunity_resilience',
            'cognitive_activities': 'cognitive_behavioral',  # backward compatibility
            'behavioral_strategies': 'cognitive_behavioral'  # backward compatibility
        }
        
        for part in path_parts:
            if part in categories:
                return categories[part]
        
        return 'general'
    
    def create_manual_document(
        self,
        text: str,
        metadata: Dict[str, Any],
        chunk: bool = True
    ) -> List[Document]:
        """Create documents from manual text input.
        
        Args:
            text: Text content
            metadata: Document metadata
            chunk: Whether to chunk the text
            
        Returns:
            List of Document objects
        """
        doc = Document(page_content=text, metadata=metadata)
        
        if chunk:
            return self.text_splitter.split_documents([doc])
        else:
            return [doc]
    
    def filter_documents_by_metadata(
        self,
        documents: List[Document],
        filters: Dict[str, Any]
    ) -> List[Document]:
        """Filter documents by metadata criteria.
        
        Args:
            documents: List of documents to filter
            filters: Dictionary of metadata filters
            
        Returns:
            Filtered list of documents
        """
        filtered_docs = []
        
        for doc in documents:
            match = True
            for key, value in filters.items():
                if key not in doc.metadata or doc.metadata[key] != value:
                    match = False
                    break
            
            if match:
                filtered_docs.append(doc)
        
        logger.info(f"Filtered {len(documents)} documents to {len(filtered_docs)} matching criteria")
        return filtered_docs