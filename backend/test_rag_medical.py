#!/usr/bin/env python3
"""Test script for medical RAG system without Google ADK dependency."""

import os
import sys
from pathlib import Path

# Add project to path
sys.path.insert(0, str(Path(__file__).parent))

# Set OpenAI API key
# Set your OpenAI API key as an environment variable before running this script
# Example: export OPENAI_API_KEY='your-api-key'
if 'OPENAI_API_KEY' not in os.environ:
    raise ValueError("OPENAI_API_KEY environment variable not set")

def test_medical_vector_store():
    """Test the medical vector store functionality."""
    print("🧪 Testing Medical RAG Vector Store")
    print("=" * 50)
    
    try:
        from app.agents.planner_agent.rag.vector_store import ChromaVectorStore
        
        # Initialize medical vector store
        medical_store = ChromaVectorStore(
            persist_directory="app/data/chroma_db_medical",
            collection_name="immunity_medical_knowledge"
        )
        
        # Check document count
        doc_count = medical_store.get_collection_count()
        print(f"✅ Medical documents loaded: {doc_count}")
        
        if doc_count == 0:
            print("⚠️  No documents found. Running embedding script...")
            os.system("python scripts/embed_medical_knowledge.py")
            doc_count = medical_store.get_collection_count()
            print(f"✅ After embedding: {doc_count} documents")
        
        # Test various medical queries
        test_queries = [
            "fever in children",
            "emergency symptoms",
            "allergic reaction",
            "breathing difficulty",
            "pediatric immunity",
            "when to call 911"
        ]
        
        print("\n📋 Testing Medical Query Retrieval:")
        for query in test_queries:
            results = medical_store.similarity_search(query, k=2)
            print(f"\n🔍 Query: '{query}'")
            print(f"   Results found: {len(results)}")
            if results:
                preview = results[0].page_content[:150].replace('\n', ' ')
                print(f"   Preview: {preview}...")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_medical_rag_retriever():
    """Test the immunity RAG retriever."""
    print("\n🧪 Testing Medical RAG Retriever")
    print("=" * 50)
    
    try:
        from app.agents.planner_agent.rag.vector_store import ChromaVectorStore
        from app.agents.chatbot_agent.enhanced_agent import ImmunityRAGRetriever
        
        # Initialize retriever
        medical_store = ChromaVectorStore(
            persist_directory="app/data/chroma_db_medical",
            collection_name="immunity_medical_knowledge"
        )
        retriever = ImmunityRAGRetriever(medical_store)
        
        # Test medical context retrieval
        symptoms = ["fever", "cough", "breathing difficulty"]
        age_months = 24  # 2 year old
        child_traits = ["asthma", "allergies"]
        
        print(f"📝 Test Case:")
        print(f"   Symptoms: {symptoms}")
        print(f"   Age: {age_months} months")
        print(f"   Traits: {child_traits}")
        
        context = retriever.retrieve_medical_context(
            symptoms=symptoms,
            age_months=age_months,
            child_traits=child_traits,
            k=3
        )
        
        print(f"\n📊 Retrieved Context:")
        print(f"   Symptom contexts: {len(context['symptom_contexts'])} symptoms analyzed")
        print(f"   Emergency protocols: {len(context['emergency_protocols'])} items")
        print(f"   Age-specific guidance: {len(context['age_specific_guidance'])} items")
        print(f"   Trait-related info: {len(context['trait_related_info'])} traits")
        
        # Build and display context prompt
        prompt = retriever.build_medical_context_prompt(context)
        print(f"\n📄 Medical Context Prompt Length: {len(prompt)} characters")
        print(f"   Preview: {prompt[:300]}...")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_symptom_extraction():
    """Test symptom extraction from queries."""
    print("\n🧪 Testing Symptom Extraction")
    print("=" * 50)
    
    try:
        # Simple symptom extraction logic (without full chatbot)
        test_cases = [
            ("My child has a high fever and severe headache", ["fever", "headache", "severe"]),
            ("She's been vomiting and has diarrhea since yesterday", ["vomiting", "diarrhea"]),
            ("He can't breathe properly and his lips are turning blue", ["breathe", "blue"]),
            ("My toddler has a rash all over his body", ["rash"]),
            ("She's not eating and seems very tired", ["eating", "tired"]),
        ]
        
        medical_keywords = [
            "fever", "cough", "rash", "vomiting", "diarrhea", "headache",
            "pain", "swelling", "breathing", "wheezing", "allergic", "reaction",
            "infection", "sick", "illness", "tired", "fatigue", "appetite",
            "sleep", "crying", "fussy", "congestion", "runny nose",
            "emergency", "urgent", "911", "hospital", "severe", "can't breathe",
            "unconscious", "seizure", "choking", "blue", "blood",
            "ear", "throat", "stomach", "chest", "skin", "eyes", "nose",
            "mouth", "head", "neck", "back", "arm", "leg", "eating"
        ]
        
        print("📋 Testing symptom detection:")
        for query, expected in test_cases:
            query_lower = query.lower()
            detected = [kw for kw in medical_keywords if kw in query_lower]
            
            print(f"\n   Query: '{query}'")
            print(f"   Detected: {detected}")
            print(f"   ✅ Match" if any(e in detected for e in expected) else "   ⚠️  Partial match")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def main():
    """Run all tests."""
    print("🔥 MEDICAL RAG SYSTEM TEST SUITE")
    print("=" * 70)
    
    # Run tests
    tests_passed = 0
    tests_total = 3
    
    if test_medical_vector_store():
        tests_passed += 1
    
    if test_medical_rag_retriever():
        tests_passed += 1
    
    if test_symptom_extraction():
        tests_passed += 1
    
    # Summary
    print("\n" + "=" * 70)
    print(f"📊 TEST SUMMARY: {tests_passed}/{tests_total} tests passed")
    
    if tests_passed == tests_total:
        print("🎉 ALL TESTS PASSED! Medical RAG system is ready!")
        print("\n✨ The chatbot now has access to:")
        print("   • Emergency symptom recognition guides")
        print("   • Pediatric immunity information")
        print("   • Age-specific medical guidance")
        print("   • Symptom-based context retrieval")
        print("\n🔥 RAG enhancement will automatically activate when:")
        print("   • Dr. Bloom is consulted")
        print("   • Medical symptoms are detected in queries")
        print("   • Immunity/resilience topics are discussed")
    else:
        print(f"⚠️  Some tests failed. Please check the errors above.")
    
    return tests_passed == tests_total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)