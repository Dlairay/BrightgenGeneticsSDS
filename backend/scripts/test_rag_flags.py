"""Test script to demonstrate RAG flags in log entries."""

import os
import sys
import asyncio
import json
import logging
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Set up OpenAI API key
# Set your OpenAI API key as an environment variable before running this script
# Example: export OPENAI_API_KEY='your-api-key'
if 'OPENAI_API_KEY' not in os.environ:
    raise ValueError("OPENAI_API_KEY environment variable not set")

# Set up logging to see RAG activation messages
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

from app.services.rag_service import rag_service


def print_separator():
    print("\n" + "="*80)


def print_log_analysis(log_entry, title):
    """Print detailed analysis of a log entry showing RAG flags."""
    print_separator()
    print(f"📊 {title}")
    print_separator()
    
    # RAG Status Flags
    rag_enhanced = log_entry.get('rag_enhanced', False)
    rag_context_used = log_entry.get('rag_context_used', False)
    rag_docs_found = log_entry.get('rag_documents_found', 0)
    
    print(f"🔥 RAG ENHANCED: {'✅ YES' if rag_enhanced else '❌ NO'}")
    print(f"🔍 RAG CONTEXT USED: {'✅ YES' if rag_context_used else '❌ NO'}")
    print(f"📚 RAG DOCUMENTS FOUND: {rag_docs_found}")
    
    # Summary (should show RAG enhancement)
    summary = log_entry.get('summary', 'No summary available')
    print(f"\n📝 SUMMARY:")
    print(f"   {summary}")
    
    # Show first recommendation with RAG context
    recommendations = log_entry.get('recommendations', [])
    if recommendations:
        print(f"\n🎯 FIRST RECOMMENDATION:")
        first_rec = recommendations[0]
        print(f"   Trait: {first_rec.get('trait', 'N/A')}")
        print(f"   TLDR: {first_rec.get('tldr', 'N/A')}")
        print(f"   Activity: {first_rec.get('activity', 'N/A')[:200]}...")
    
    # Entry metadata
    entry_type = log_entry.get('entry_type', 'unknown')
    traits = log_entry.get('interpreted_traits', [])
    print(f"\n📋 METADATA:")
    print(f"   Entry Type: {entry_type}")
    print(f"   Traits: {', '.join(traits)}")
    
    # JSON flags for debugging
    print(f"\n🔧 RAG FLAGS (JSON):")
    rag_flags = {
        'rag_enhanced': rag_enhanced,
        'rag_context_used': rag_context_used,
        'rag_documents_found': rag_docs_found
    }
    print(f"   {json.dumps(rag_flags, indent=2)}")


async def test_rag_flags():
    """Test RAG flags with different scenarios."""
    
    print("🧪 TESTING RAG FLAGS IN LOG ENTRIES")
    print("This will show you exactly when and how RAG is working...")
    
    # Test Scenario 1: Working Memory + Cognitive Development
    print_separator()
    print("🧠 TEST 1: Working Memory & Cognitive Development")
    print("Expected: RAG should activate and find relevant documents")
    print_separator()
    
    try:
        result1 = await rag_service.generate_enhanced_initial_log(
            traits=[
                {"trait_name": "working_memory"},
                {"trait_name": "cognitive_development"}
            ],
            derived_age=36,  # 3 years old
            gender="female"
        )
        
        print_log_analysis(result1, "WORKING MEMORY & COGNITIVE DEVELOPMENT RESULTS")
        
    except Exception as e:
        print(f"❌ Test 1 failed: {e}")
        import traceback
        traceback.print_exc()
    
    # Test Scenario 2: Nutrition Focus
    print_separator()
    print("🥗 TEST 2: Nutrition & Brain Development")
    print("Expected: RAG should find nutrition research documents")
    print_separator()
    
    try:
        result2 = await rag_service.generate_enhanced_initial_log(
            traits=[
                {"trait_name": "nutrition"},
                {"trait_name": "brain_development"}
            ],
            derived_age=24,  # 2 years old
            gender="male"
        )
        
        print_log_analysis(result2, "NUTRITION & BRAIN DEVELOPMENT RESULTS")
        
    except Exception as e:
        print(f"❌ Test 2 failed: {e}")
        import traceback
        traceback.print_exc()
    
    # Test Scenario 3: Unknown Traits (should have less RAG context)
    print_separator()
    print("❓ TEST 3: Unknown/Rare Traits")
    print("Expected: RAG may find fewer documents, but should still enhance")
    print_separator()
    
    try:
        result3 = await rag_service.generate_enhanced_initial_log(
            traits=[
                {"trait_name": "rare_genetic_variant"},
                {"trait_name": "unknown_trait"}
            ],
            derived_age=18,  # 1.5 years old
            gender="female"
        )
        
        print_log_analysis(result3, "UNKNOWN TRAITS RESULTS")
        
    except Exception as e:
        print(f"❌ Test 3 failed: {e}")
        import traceback
        traceback.print_exc()
    
    # Summary
    print_separator()
    print("🎯 WHAT TO LOOK FOR IN YOUR LOGS:")
    print_separator()
    print("✅ SUCCESSFUL RAG ACTIVATION:")
    print("   - Log messages: '🔥 RAG ACTIVATED: Retrieved context from X documents'")
    print("   - Log messages: '✅ RAG SUCCESS: Enhanced log with X knowledge documents'")
    print("   - Summary starts with: '🔥 RAG-ENHANCED:'")
    print("   - JSON flags: rag_enhanced=true, rag_context_used=true, rag_documents_found>0")
    
    print("\n❌ RAG NOT WORKING:")
    print("   - No fire emoji messages in logs")
    print("   - Summary doesn't start with '🔥 RAG-ENHANCED:'")
    print("   - JSON flags: rag_enhanced=false, rag_documents_found=0")
    
    print("\n🔧 HOW TO DEBUG:")
    print("   - Check if vector store has documents: rag_service.get_rag_status()")
    print("   - Test knowledge search: rag_service.search_knowledge('working memory')")
    print("   - Check logs for RAG activation messages")
    
    print_separator()
    print("🎉 RAG FLAG TESTING COMPLETE!")
    print("Your logs now clearly show when RAG is working!")
    print_separator()


if __name__ == "__main__":
    asyncio.run(test_rag_flags())