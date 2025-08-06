"""Script to embed TXT files (avoiding problematic PDFs for now)."""

import os
import sys
import logging
from pathlib import Path

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


def embed_txt_files(knowledge_base_path: str = None, force_reload: bool = False):
    """Embed TXT files in knowledge base directories.
    
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
        return False
    
    # Check for OPENAI_API_KEY
    if not os.getenv("OPENAI_API_KEY"):
        logger.error("OPENAI_API_KEY environment variable is required!")
        return False
    
    logger.info(f"Starting TXT file embedding process...")
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
                logger.info(f"Found {existing_count} existing embeddings - adding to them")
        
        # Find all TXT files
        txt_files = list(knowledge_base_path.rglob("*.txt"))
        logger.info(f"Found {len(txt_files)} TXT files to process")
        
        if not txt_files:
            logger.warning("No TXT files found in knowledge base directories")
            return False
        
        # Process each TXT file
        all_documents = []
        processed_count = 0
        
        for txt_file in txt_files:
            try:
                logger.info(f"Processing TXT: {txt_file.name}")
                
                # Load TXT
                documents = document_processor.load_txt(str(txt_file))
                
                if not documents:
                    logger.warning(f"No content extracted from {txt_file.name}")
                    continue
                
                # Chunk documents
                chunked_docs = document_processor.chunk_documents(documents)
                
                # Preprocess chunks for better quality
                processed_chunks = preprocessor.preprocess_documents(chunked_docs)
                
                all_documents.extend(processed_chunks)
                processed_count += 1
                
                logger.info(f"  ✅ {txt_file.name}: {len(processed_chunks)} chunks")
                
            except Exception as e:
                logger.error(f"  ❌ Failed to process {txt_file.name}: {e}")
                continue
        
        if not all_documents:
            logger.error("No documents were successfully processed")
            return False
        
        logger.info(f"\nEmbedding {len(all_documents)} document chunks...")
        
        # Embed all documents in batches
        batch_size = 10  # Smaller batches for testing
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
        logger.info(f"   - TXT files processed: {processed_count}/{len(txt_files)}")
        logger.info(f"   - Total chunks embedded: {total_embedded}")
        logger.info(f"   - Final vector store size: {final_count}")
        
        # Test retrieval
        logger.info(f"\n🧪 Testing retrieval...")
        test_queries = ["working memory", "cognitive development", "nutrition brain"]
        
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
    
    parser = argparse.ArgumentParser(description="Embed TXT files into ChromaDB vector store")
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
    
    success = embed_txt_files(
        knowledge_base_path=args.knowledge_base,
        force_reload=args.force_reload
    )
    
    return 0 if success else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)