"""Script to embed medical knowledge for immunity & resilience chatbot."""

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


def embed_medical_knowledge(force_reload: bool = False):
    """Embed medical knowledge into separate vector store for chatbot."""
    
    # Check for OPENAI_API_KEY
    if not os.getenv("OPENAI_API_KEY"):
        logger.error("OPENAI_API_KEY environment variable is required!")
        return False
    
    logger.info("Starting MEDICAL knowledge embedding for Dr. Bloom chatbot...")
    
    # Paths
    medical_kb_path = project_root / "app" / "data" / "knowledge_base" / "immunity_resilience"
    
    if not medical_kb_path.exists():
        logger.error(f"Medical knowledge base directory not found: {medical_kb_path}")
        return False
    
    try:
        # Initialize components for MEDICAL vector store
        medical_vector_store = ChromaVectorStore(
            persist_directory="app/data/chroma_db_medical",
            collection_name="immunity_medical_knowledge"
        )
        document_processor = DocumentProcessor()
        preprocessor = DocumentPreprocessor()
        
        # Check existing embeddings
        existing_count = medical_vector_store.get_collection_count()
        if existing_count > 0:
            if force_reload:
                logger.info(f"Found {existing_count} existing medical embeddings - clearing for reload")
                medical_vector_store.delete_collection()
            else:
                logger.info(f"Found {existing_count} existing medical embeddings - adding to them")
        
        # Find all medical files
        txt_files = list(medical_kb_path.rglob("*.txt"))
        html_files = list(medical_kb_path.rglob("*.html")) + list(medical_kb_path.rglob("*.htm"))
        pdf_files = list(medical_kb_path.rglob("*.pdf"))
        all_files = txt_files + html_files + pdf_files
        
        logger.info(f"Found {len(txt_files)} TXT, {len(html_files)} HTML, {len(pdf_files)} PDF medical files")
        logger.info(f"Total medical files: {len(all_files)}")
        
        if not all_files:
            logger.warning("No medical files found in immunity_resilience directory")
            logger.info("Please add medical knowledge files to:")
            logger.info(f"  {medical_kb_path}")
            return False
        
        # Process each medical file  
        all_documents = []
        processed_count = 0
        
        for file_path in all_files:
            try:
                file_type = file_path.suffix.upper()
                logger.info(f"Processing {file_type}: {file_path.name}")
                
                # Load file based on type
                documents = document_processor.load_file(str(file_path))
                
                if not documents:
                    logger.warning(f"No content extracted from {file_path.name}")
                    continue
                
                # Chunk documents
                chunked_docs = document_processor.chunk_documents(documents)
                
                # Preprocess chunks for medical content
                processed_chunks = preprocessor.preprocess_documents(chunked_docs)
                
                all_documents.extend(processed_chunks)
                processed_count += 1
                
                logger.info(f"  ✅ {file_path.name}: {len(processed_chunks)} chunks")
                
            except Exception as e:
                logger.error(f"  ❌ Failed to process {file_path.name}: {e}")
                continue
        
        if not all_documents:
            logger.error("No medical documents were successfully processed")
            return False
        
        logger.info(f"\n🏥 Embedding {len(all_documents)} MEDICAL document chunks...")
        
        # Embed all medical documents in batches
        batch_size = 10
        total_embedded = 0
        
        for i in range(0, len(all_documents), batch_size):
            batch = all_documents[i:i + batch_size]
            try:
                medical_vector_store.embed_documents(batch)
                total_embedded += len(batch)
                logger.info(f"  Embedded medical batch {i//batch_size + 1}: {total_embedded}/{len(all_documents)} chunks")
            except Exception as e:
                logger.error(f"Failed to embed medical batch {i//batch_size + 1}: {e}")
                continue
        
        # Final status
        final_count = medical_vector_store.get_collection_count()
        logger.info(f"\n✅ MEDICAL embedding complete!")
        logger.info(f"🏥 MEDICAL KNOWLEDGE SUMMARY:")
        logger.info(f"   - Medical files processed: {processed_count}/{len(all_files)}")
        logger.info(f"   - Total medical chunks embedded: {total_embedded}")
        logger.info(f"   - Final medical vector store size: {final_count}")
        logger.info(f"   - Medical vector store: app/data/chroma_db_medical")
        
        # Test medical retrieval
        logger.info(f"\n🧪 Testing MEDICAL knowledge retrieval...")
        test_queries = ["fever symptoms", "emergency signs", "pediatric illness", "immune system"]
        
        for query in test_queries:
            results = medical_vector_store.similarity_search(query, k=2)
            logger.info(f"  '{query}': {len(results)} medical results found")
            if results:
                logger.info(f"    Sample: {results[0].page_content[:100]}...")
        
        logger.info(f"\n🎉 Dr. Bloom's medical RAG system is ready!")
        logger.info(f"🔥 Medical knowledge enhanced with {final_count} evidence-based documents!")
        return True
        
    except Exception as e:
        logger.error(f"Medical embedding process failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main function with command line argument support."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Embed medical knowledge for Dr. Bloom chatbot")
    parser.add_argument(
        "--force-reload", 
        action="store_true", 
        help="Clear existing medical embeddings and reload all"
    )
    
    args = parser.parse_args()
    
    success = embed_medical_knowledge(force_reload=args.force_reload)
    
    if success:
        print("\n🏥 MEDICAL RAG SYSTEM READY!")
        print("Dr. Bloom now has access to evidence-based medical knowledge!")
        print("\nNext steps:")
        print("1. Use RAGEnhancedChildCareChatbot in your chatbot service")
        print("2. Test with medical queries to see RAG enhancement")
        print("3. Add more medical documents to immunity_resilience/ folder")
    
    return 0 if success else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)