"""Script to load knowledge base into ChromaDB vector store."""

import os
import sys
import asyncio
import logging
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from app.agents.planner_agent.enhanced_agent import EnhancedLogGenerationService
from app.core.embeddings_config import embeddings_config

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def main():
    """Load knowledge base into vector store."""
    
    # Check configuration
    if not embeddings_config.is_configured:
        logger.error("RAG system is not properly configured!")
        logger.error("Please set OPENAI_API_KEY in your environment or .env file")
        return 1
    
    logger.info("Starting knowledge base loading...")
    logger.info(f"OpenAI API Key configured: {'Yes' if embeddings_config.openai_api_key else 'No'}")
    logger.info(f"Knowledge base path: {embeddings_config.knowledge_base_path}")
    logger.info(f"ChromaDB path: {embeddings_config.chroma_persist_directory}")
    
    # Check if knowledge base directory exists
    kb_path = Path(embeddings_config.knowledge_base_path)
    if not kb_path.exists():
        logger.error(f"Knowledge base directory does not exist: {kb_path}")
        logger.info("Please create the directory and add PDF files to it")
        return 1
    
    # Check for PDF files
    pdf_count = len(list(kb_path.rglob("*.pdf")))
    if pdf_count == 0:
        logger.warning("No PDF files found in knowledge base directory")
        logger.info("Please add PDF files to the knowledge base subdirectories:")
        for subdir in kb_path.iterdir():
            if subdir.is_dir():
                logger.info(f"  - {subdir.name}/")
    else:
        logger.info(f"Found {pdf_count} PDF files in knowledge base")
    
    try:
        # Initialize enhanced service
        service = EnhancedLogGenerationService(use_rag=True, auto_load_knowledge=False)
        
        # Load knowledge base
        logger.info("Loading knowledge base...")
        result = service.load_knowledge_base(force_reload=True)
        
        if result["success"]:
            logger.info(f"✅ Successfully loaded {result['documents_loaded']} document chunks")
            
            # Test the system
            logger.info("Testing knowledge retrieval...")
            test_results = service.search_knowledge("cognitive development activities", k=3)
            
            if test_results:
                logger.info(f"✅ Retrieved {len(test_results)} test results")
                for i, result in enumerate(test_results[:2], 1):
                    logger.info(f"Test result {i}: {result['content'][:100]}...")
            else:
                logger.warning("No test results retrieved - this may indicate an issue")
            
            # Show system status
            status = service.get_rag_status()
            logger.info(f"RAG System Status: {status}")
            
        else:
            logger.error(f"Failed to load knowledge base: {result.get('error', 'Unknown error')}")
            return 1
    
    except Exception as e:
        logger.error(f"Error loading knowledge base: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    logger.info("Knowledge base loading completed successfully!")
    return 0


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)