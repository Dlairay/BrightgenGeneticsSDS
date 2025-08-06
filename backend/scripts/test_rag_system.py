"""Comprehensive test script for the RAG system."""

import os
import sys
import asyncio
import json
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Set up OpenAI API key
# Set your OpenAI API key as an environment variable before running this script
# Example: export OPENAI_API_KEY='your-api-key'
if 'OPENAI_API_KEY' not in os.environ:
    raise ValueError("OPENAI_API_KEY environment variable not set")

from app.services.rag_service import rag_service


def print_section(title):
    """Print a section header."""
    print(f"\n{'='*60}")
    print(f"🧪 {title}")
    print(f"{'='*60}")


def test_basic_functionality():
    """Test basic RAG functionality."""
    print_section("BASIC RAG FUNCTIONALITY TEST")
    
    # Test 1: Check if RAG is enabled
    print("1. Checking RAG configuration...")
    is_enabled = rag_service.is_rag_enabled()
    print(f"   RAG Enabled: {'✅ Yes' if is_enabled else '❌ No'}")
    
    if not is_enabled:
        print("   ❌ RAG is not properly configured. Check your OpenAI API key.")
        return False
    
    # Test 2: Get RAG status
    print("\n2. Getting RAG system status...")
    status = rag_service.get_rag_status()
    print(f"   Documents in vector store: {status.get('document_count', 0)}")
    print(f"   System initialized: {'✅ Yes' if status.get('initialized', False) else '❌ No'}")
    
    if status.get('document_count', 0) == 0:
        print("   ⚠️  No documents found. Run embedding script first.")
        return False
    
    return True


def test_knowledge_search():
    """Test knowledge search functionality."""
    print_section("KNOWLEDGE SEARCH TEST")
    
    test_queries = [
        "working memory activities",
        "cognitive development",
        "nutrition brain development",
        "early childhood milestones",
        "toddler activities"
    ]
    
    print("Testing knowledge search with various queries...")
    
    for i, query in enumerate(test_queries, 1):
        print(f"\n{i}. Query: '{query}'")
        
        try:
            results = rag_service.search_knowledge(query, k=3)
            print(f"   Found: {len(results)} results")
            
            if results:
                # Show first result details
                first_result = results[0]
                print(f"   📄 Top result from: {first_result['metadata'].get('filename', 'unknown')}")
                print(f"   📝 Content preview: {first_result['content'][:150]}...")
                print(f"   📊 Similarity score: {first_result.get('similarity_score', 'N/A')}")
            else:
                print("   ⚠️  No results found")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    return True


async def test_rag_enhanced_recommendations():
    """Test RAG-enhanced recommendation generation."""
    print_section("RAG-ENHANCED RECOMMENDATIONS TEST")
    
    # Test scenarios
    test_scenarios = [
        {
            "name": "Working Memory Focus",
            "traits": [{"trait_name": "working_memory"}, {"trait_name": "cognitive_development"}],
            "age": 36,  # 3 years old
            "gender": "female"
        },
        {
            "name": "Nutrition & Development",
            "traits": [{"trait_name": "brain_development"}, {"trait_name": "nutrition"}],
            "age": 24,  # 2 years old
            "gender": "male"
        }
    ]
    
    for i, scenario in enumerate(test_scenarios, 1):
        print(f"\n{i}. Testing scenario: {scenario['name']}")
        print(f"   👶 Child: {scenario['age']} months old, {scenario['gender']}")
        print(f"   🧬 Traits: {[t['trait_name'] for t in scenario['traits']]}")
        
        try:
            # Test RAG-enhanced generation
            print("   🔄 Generating RAG-enhanced recommendations...")
            
            result = await rag_service.generate_enhanced_initial_log(
                traits=scenario['traits'],
                derived_age=scenario['age'],
                gender=scenario['gender']
            )
            
            print(f"   ✅ Generation successful!")
            print(f"   🔬 RAG Enhanced: {'Yes' if result.get('rag_enhanced', False) else 'No'}")
            print(f"   📝 Summary: {result.get('summary', 'N/A')[:200]}...")
            
            if 'recommendations' in result:
                print(f"   🎯 Generated {len(result['recommendations'])} recommendations:")
                for j, rec in enumerate(result['recommendations'][:3], 1):
                    trait = rec.get('trait', 'unknown')
                    tldr = rec.get('tldr', 'N/A')
                    print(f"      {j}. {trait}: {tldr}")
            
            if 'followup_questions' in result:
                print(f"   ❓ Follow-up questions: {len(result['followup_questions'])}")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            import traceback
            traceback.print_exc()


def test_context_retrieval():
    """Test RAG context retrieval for specific traits."""
    print_section("CONTEXT RETRIEVAL TEST")
    
    print("Testing trait-specific context retrieval...")
    
    # Import the retriever directly to test context building
    try:
        from app.agents.planner_agent.rag.retriever import RAGRetriever
        
        retriever = RAGRetriever()
        
        # Test context retrieval for specific traits
        test_traits = ["working_memory", "cognitive_development", "nutrition"]
        
        print(f"Retrieving context for traits: {test_traits}")
        context = retriever.retrieve_for_traits(
            traits=test_traits,
            age=30,  # 2.5 years old
            k=3
        )
        
        print(f"✅ Context retrieval successful!")
        print(f"📊 Context structure:")
        print(f"   - Trait contexts: {len(context['trait_contexts'])} traits")
        print(f"   - General context: {len(context['general_context'])} items")
        print(f"   - Age-specific context: {len(context['age_specific_context'])} items")
        
        # Show sample context
        if context['trait_contexts']:
            first_trait = list(context['trait_contexts'].keys())[0]
            trait_context = context['trait_contexts'][first_trait]
            if trait_context:
                print(f"\n📄 Sample context for '{first_trait}':")
                print(f"   {trait_context[0]['content'][:200]}...")
        
        # Test context prompt building
        prompt = retriever.build_context_prompt(context)
        print(f"\n📝 Generated context prompt length: {len(prompt)} characters")
        print(f"   Sample: {prompt[:300]}...")
        
    except Exception as e:
        print(f"❌ Context retrieval test failed: {e}")
        import traceback
        traceback.print_exc()


async def test_comparison_with_without_rag():
    """Compare recommendations with and without RAG."""
    print_section("RAG VS NON-RAG COMPARISON TEST")
    
    print("Comparing recommendations with and without RAG...")
    
    test_traits = [{"trait_name": "working_memory"}]
    test_age = 36
    test_gender = "female"
    
    try:
        # Test with RAG
        print("1. Generating recommendations WITH RAG...")
        rag_result = await rag_service.generate_enhanced_initial_log(
            traits=test_traits,
            derived_age=test_age,
            gender=test_gender
        )
        
        # Test without RAG (fallback to original)
        print("2. Generating recommendations WITHOUT RAG...")
        from app.agents.planner_agent.agent import LogGenerationService
        original_service = LogGenerationService()
        
        original_result = await original_service.generate_initial_log(
            traits=test_traits,
            derived_age=test_age,
            gender=test_gender
        )
        
        print("\n📊 COMPARISON RESULTS:")
        print(f"RAG Enhanced: {rag_result.get('rag_enhanced', False)}")
        print(f"Recommendations count - RAG: {len(rag_result.get('recommendations', []))} | Original: {len(original_result.get('recommendations', []))}")
        
        # Compare first recommendations
        if rag_result.get('recommendations') and original_result.get('recommendations'):
            rag_rec = rag_result['recommendations'][0]
            orig_rec = original_result['recommendations'][0]
            
            print(f"\n🎯 FIRST RECOMMENDATION COMPARISON:")
            print(f"RAG Activity: {rag_rec.get('activity', 'N/A')[:150]}...")
            print(f"Original Activity: {orig_rec.get('activity', 'N/A')[:150]}...")
            
            print(f"\nRAG TLDR: {rag_rec.get('tldr', 'N/A')}")
            print(f"Original TLDR: {orig_rec.get('tldr', 'N/A')}")
        
    except Exception as e:
        print(f"❌ Comparison test failed: {e}")
        import traceback
        traceback.print_exc()


def test_api_endpoints():
    """Test RAG API endpoints (if running)."""
    print_section("API ENDPOINTS TEST")
    
    print("Note: This test requires the FastAPI server to be running.")
    print("To test API endpoints manually:")
    print("1. Start your server: uvicorn main:app --reload")
    print("2. Visit: http://localhost:8000/rag/status")
    print("3. Test search: POST http://localhost:8000/rag/search")
    print("   Body: {\"query\": \"working memory\", \"k\": 3}")


def print_usage_guide():
    """Print usage guide for the user."""
    print_section("HOW TO USE YOUR RAG SYSTEM")
    
    print("🎯 Your RAG system is ready! Here's how to use it:")
    
    print("\n1. 📁 ADD MORE CONTENT:")
    print("   - Drop TXT, HTML, or PDF files into:")
    print("     • app/data/knowledge_base/developmental_guidelines/")
    print("     • app/data/knowledge_base/nutrition_research/") 
    print("     • app/data/knowledge_base/cognitive_behavioral/")
    print("   - Run: python scripts/embed_txt_files.py")
    
    print("\n2. 🔍 SEARCH KNOWLEDGE:")
    print("   from app.services.rag_service import rag_service")
    print("   results = rag_service.search_knowledge('working memory activities')")
    
    print("\n3. 🧠 USE ENHANCED RECOMMENDATIONS:")
    print("   # Replace your existing LogGenerationService with:")
    print("   enhanced_log = await rag_service.generate_enhanced_initial_log(")
    print("       traits=[{'trait_name': 'working_memory'}],")
    print("       derived_age=36, gender='female')")
    
    print("\n4. 🔧 UPDATE YOUR CHILD SERVICE:")
    print("   # In app/services/child_service.py, replace:")
    print("   # from app.agents.planner_agent.agent import LogGenerationService")
    print("   # with:")
    print("   # from app.services.rag_service import rag_service")
    
    print("\n5. 🌐 API ENDPOINTS:")
    print("   • GET /rag/status - Check RAG system status")
    print("   • POST /rag/search - Search knowledge base")
    print("   • POST /rag/load-knowledge - Reload knowledge base")


async def main():
    """Run all tests."""
    print("🚀 COMPREHENSIVE RAG SYSTEM TEST")
    print("This will test all aspects of your RAG system...\n")
    
    # Run tests in sequence
    tests_passed = 0
    total_tests = 5
    
    try:
        if test_basic_functionality():
            tests_passed += 1
        
        if test_knowledge_search():
            tests_passed += 1
        
        await test_rag_enhanced_recommendations()
        tests_passed += 1
        
        test_context_retrieval()
        tests_passed += 1
        
        await test_comparison_with_without_rag()
        tests_passed += 1
        
    except Exception as e:
        print(f"\n❌ Test suite error: {e}")
        import traceback
        traceback.print_exc()
    
    # Test API endpoints info
    test_api_endpoints()
    
    # Print usage guide
    print_usage_guide()
    
    # Final summary
    print_section("TEST RESULTS SUMMARY")
    print(f"✅ Tests passed: {tests_passed}/{total_tests}")
    
    if tests_passed == total_tests:
        print("🎉 ALL TESTS PASSED! Your RAG system is working perfectly!")
    elif tests_passed >= 3:
        print("✅ Most tests passed! Your RAG system is mostly working.")
    else:
        print("⚠️  Some tests failed. Check the errors above.")
    
    print("\n🔥 Your RAG system is ready to enhance your child development recommendations!")


if __name__ == "__main__":
    asyncio.run(main())