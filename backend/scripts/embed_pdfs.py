"""Simple script to embed all PDFs in the knowledge base into ChromaDB."""

import os
import sys
from pathlib import Path
import logging

# Add the project root to the Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from app.agents.planner_agent.rag.vector_store import ChromaVectorStore
from app.agents.planner_agent.rag.documents import DocumentProcessor
from app.agents.planner_agent.knowledge.preprocessor import DocumentPreprocessor

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def embed_all_pdfs(knowledge_base_path: str = None, force_reload: bool = False):
    """Embed all PDFs in knowledge base directories.
    
    Args:
        knowledge_base_path: Path to knowledge base directory
        force_reload: Whether to clear existing embeddings and reload
    """
    
    # Default knowledge base path
    if knowledge_base_path is None:
        knowledge_base_path = project_root / "app" / "data" / "knowledge_base"
    else:
        knowledge_base_path = Path(knowledge_base_path)
    
    if not knowledge_base_path.exists():
        logger.error(f"Knowledge base directory not found: {knowledge_base_path}")
        logger.info("Please create the directory and add PDF files")
        return False
    
    # Check for OPENAI_API_KEY
    if not os.getenv("OPENAI_API_KEY"):
        logger.error("OPENAI_API_KEY environment variable is required!")
        logger.info("Please set your OpenAI API key in your .env file or environment")
        return False
    
    logger.info(f"Starting PDF embedding process...")
    logger.info(f"Knowledge base path: {knowledge_base_path}")
    logger.info(f"Force reload: {force_reload}")
    
    try:
        # Initialize components
        vector_store = ChromaVectorStore()
        document_processor = DocumentProcessor()
        preprocessor = DocumentPreprocessor()
        
        # Check existing embeddings
        existing_count = vector_store.get_collection_count()
        if existing_count > 0:
            if force_reload:
                logger.info(f"Found {existing_count} existing embeddings - clearing for reload")
                vector_store.delete_collection()
            else:
                logger.info(f"Found {existing_count} existing embeddings - use --force-reload to clear")
                response = input("Continue and add to existing embeddings? (y/n): ")
                if response.lower() != 'y':
                    logger.info("Embedding cancelled")
                    return False
        
        # Find all supported files (PDF and HTML)
        pdf_files = list(knowledge_base_path.rglob("*.pdf"))
        html_files = list(knowledge_base_path.rglob("*.html")) + list(knowledge_base_path.rglob("*.htm"))
        all_files = pdf_files + html_files
        
        logger.info(f"Found {len(pdf_files)} PDF files and {len(html_files)} HTML files to process")
        logger.info(f"Total files: {len(all_files)}")
        
        if not all_files:
            logger.warning("No PDF or HTML files found in knowledge base directories")
            logger.info("Add PDF or HTML files to these directories:")
            for subdir in knowledge_base_path.iterdir():
                if subdir.is_dir() and not subdir.name.startswith('.'):
                    logger.info(f"  - {subdir.name}/")
            return False
        
        # Process each file
        all_documents = []
        processed_count = 0
        
        for file_path in all_files:
            try:
                file_type = "PDF" if file_path.suffix.lower() == '.pdf' else "HTML"
                logger.info(f"Processing {file_type}: {file_path.name}")
                
                # Load file (PDF or HTML)
                documents = document_processor.load_file(str(file_path))
                
                if not documents:
                    logger.warning(f"No content extracted from {file_path.name}")
                    continue
                
                # Chunk documents
                chunked_docs = document_processor.chunk_documents(documents)
                
                # Preprocess chunks for better quality
                processed_chunks = preprocessor.preprocess_documents(chunked_docs)
                
                all_documents.extend(processed_chunks)
                processed_count += 1
                
                logger.info(f"  ✅ {file_path.name}: {len(processed_chunks)} chunks")
                
            except Exception as e:
                logger.error(f"  ❌ Failed to process {file_path.name}: {e}")
                continue
        
        if not all_documents:
            logger.error("No documents were successfully processed")
            return False
        
        logger.info(f"\nEmbedding {len(all_documents)} document chunks...")
        
        # Embed all documents in batches
        batch_size = 50
        total_embedded = 0
        
        for i in range(0, len(all_documents), batch_size):
            batch = all_documents[i:i + batch_size]
            try:
                vector_store.embed_documents(batch)
                total_embedded += len(batch)
                logger.info(f"  Embedded batch {i//batch_size + 1}: {total_embedded}/{len(all_documents)} chunks")
            except Exception as e:
                logger.error(f"Failed to embed batch {i//batch_size + 1}: {e}")
                continue
        
        # Final status
        final_count = vector_store.get_collection_count()
        logger.info(f"\n✅ Embedding complete!")
        logger.info(f"📊 Summary:")
        logger.info(f"   - Files processed: {processed_count}/{len(all_files)} ({len(pdf_files)} PDFs, {len(html_files)} HTML)")
        logger.info(f"   - Total chunks embedded: {total_embedded}")
        logger.info(f"   - Final vector store size: {final_count}")
        
        # Test retrieval
        logger.info(f"\n🧪 Testing retrieval...")
        test_queries = ["cognitive development", "motor skills", "language development"]
        
        for query in test_queries:
            results = vector_store.similarity_search(query, k=2)
            logger.info(f"  '{query}': {len(results)} results found")
            if results:
                logger.info(f"    Sample: {results[0].page_content[:100]}...")
        
        logger.info(f"\n🎉 All done! Your RAG system is ready to use.")
        return True
        
    except Exception as e:
        logger.error(f"Embedding process failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main function with command line argument support."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Embed PDFs into ChromaDB vector store")
    parser.add_argument(
        "--knowledge-base", 
        type=str, 
        help="Path to knowledge base directory (default: app/data/knowledge_base)"
    )
    parser.add_argument(
        "--force-reload", 
        action="store_true", 
        help="Clear existing embeddings and reload all"
    )
    
    args = parser.parse_args()
    
    success = embed_all_pdfs(
        knowledge_base_path=args.knowledge_base,
        force_reload=args.force_reload
    )
    
    return 0 if success else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)