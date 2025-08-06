"""API endpoints for RAG system management."""

import logging
from typing import List, Dict, Any
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from ..core.security import get_current_user
from ..services.rag_service import rag_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/rag", tags=["RAG System"])


class KnowledgeSearchRequest(BaseModel):
    """Request model for knowledge search."""
    query: str
    k: int = 5


class KnowledgeSearchResponse(BaseModel):
    """Response model for knowledge search."""
    results: List[Dict[str, Any]]
    total_results: int


class RAGStatusResponse(BaseModel):
    """Response model for RAG status."""
    enabled: bool
    initialized: bool
    document_count: int = 0
    error: str = None


class LoadKnowledgeRequest(BaseModel):
    """Request model for loading knowledge base."""
    force_reload: bool = False


@router.get("/status", response_model=RAGStatusResponse)
async def get_rag_status(current_user: dict = Depends(get_current_user)):
    """Get RAG system status.
    
    Returns:
        RAG system status information
    """
    try:
        status = rag_service.get_rag_status()
        
        return RAGStatusResponse(
            enabled=status.get("enabled", False),
            initialized=status.get("initialized", False),
            document_count=status.get("document_count", 0),
            error=status.get("error")
        )
    except Exception as e:
        logger.error(f"Failed to get RAG status: {e}")
        raise HTTPException(status_code=500, detail="Failed to get RAG status")


@router.post("/search", response_model=KnowledgeSearchResponse)
async def search_knowledge(
    request: KnowledgeSearchRequest,
    current_user: dict = Depends(get_current_user)
):
    """Search the knowledge base.
    
    Args:
        request: Search request parameters
        current_user: Current authenticated user
        
    Returns:
        Search results from the knowledge base
    """
    try:
        if not rag_service.is_rag_enabled():
            raise HTTPException(
                status_code=503,
                detail="RAG system is not enabled or configured"
            )
        
        results = rag_service.search_knowledge(request.query, request.k)
        
        return KnowledgeSearchResponse(
            results=results,
            total_results=len(results)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Knowledge search failed: {e}")
        raise HTTPException(status_code=500, detail="Knowledge search failed")


@router.post("/load-knowledge")
async def load_knowledge_base(
    request: LoadKnowledgeRequest,
    current_user: dict = Depends(get_current_user)
):
    """Load knowledge base into vector store.
    
    Args:
        request: Load request parameters
        current_user: Current authenticated user
        
    Returns:
        Loading results
    """
    try:
        if not rag_service.is_rag_enabled():
            raise HTTPException(
                status_code=503,
                detail="RAG system is not enabled or configured"
            )
        
        result = rag_service.load_knowledge_base(request.force_reload)
        
        if not result["success"]:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to load knowledge base: {result.get('error', 'Unknown error')}"
            )
        
        return {
            "success": True,
            "documents_loaded": result["documents_loaded"],
            "force_reload": result.get("force_reload", False)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Knowledge base loading failed: {e}")
        raise HTTPException(status_code=500, detail="Knowledge base loading failed")


@router.get("/test")
async def test_rag_system(current_user: dict = Depends(get_current_user)):
    """Test the RAG system with a sample query.
    
    Returns:
        Test results and system information
    """
    try:
        if not rag_service.is_rag_enabled():
            return {
                "rag_enabled": False,
                "message": "RAG system is not enabled or configured"
            }
        
        status = rag_service.get_rag_status()
        
        # Test with sample queries
        test_queries = [
            "cognitive development activities",
            "motor skills development",
            "language development milestones"
        ]
        
        test_results = {}
        for query in test_queries:
            results = rag_service.search_knowledge(query, k=2)
            test_results[query] = {
                "result_count": len(results),
                "sample_result": results[0]["content"][:200] + "..." if results else None
            }
        
        return {
            "rag_enabled": True,
            "status": status,
            "test_results": test_results
        }
    except Exception as e:
        logger.error(f"RAG system test failed: {e}")
        raise HTTPException(status_code=500, detail="RAG system test failed")