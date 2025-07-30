from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from typing import List
import json

from app.core.security import get_current_user
from app.schemas.user import User
from app.schemas.child import Child, CheckInAnswers, RecommendationHistory, DrBloomSessionStart, DrBloomSessionComplete
from app.services.child_service import ChildService
from app.repositories.child_repository import ChildRepository

router = APIRouter(prefix="/children", tags=["children"])
child_service = ChildService()
child_repo = ChildRepository()


@router.get("", response_model=List[Child])
async def get_children(current_user: User = Depends(get_current_user)):
    try:
        return await child_service.get_children_for_user(current_user.id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get children: {str(e)}")


@router.post("/upload-genetic-report")
async def upload_genetic_report(
    file: UploadFile = File(...),
    child_name: str = Form(...),
    current_user: User = Depends(get_current_user)
):
    try:
        # Check file type
        content_type = file.content_type
        if content_type not in ["application/json", "application/pdf"]:
            raise HTTPException(
                status_code=400, 
                detail=f"Unsupported file type: {content_type}. Please upload JSON or PDF file."
            )
        
        # Read file content
        content = await file.read()
        
        # Process file based on type
        result = await child_service.create_child_profile_from_file(
            content, content_type, child_name, current_user.id
        )
        
        if result.get("error") == "CHILD_ALREADY_EXISTS":
            raise HTTPException(status_code=409, detail=result["message"])
        elif result.get("error") == "CHILD_ID_TAKEN":
            raise HTTPException(status_code=409, detail=result["message"])
        
        # If profile was created successfully, fetch the mapped traits
        if result.get("child_id") and not result.get("error"):
            child_id = result["child_id"]
            mapped_traits = await child_service.get_child_traits_mapped(child_id)
            result["traits"] = mapped_traits
            
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        if "Invalid JSON format" in str(e):
            raise HTTPException(status_code=400, detail="Invalid JSON file format")
        elif "No data extracted" in str(e):
            raise HTTPException(status_code=400, detail="Could not extract genetic data from PDF")
        else:
            raise HTTPException(status_code=500, detail=f"Failed to process genetic report: {str(e)}")


@router.get("/{child_id}/check-in/questions")
async def get_check_in_questions(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.get_check_in_questions(child_id)
        
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get check-in questions: {str(e)}")


@router.post("/{child_id}/check-in/submit")
async def submit_check_in(
    child_id: str,
    answers: CheckInAnswers,
    current_user: User = Depends(get_current_user)
):
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.submit_check_in(child_id, answers)
        
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit check-in: {str(e)}")


@router.get("/{child_id}/profile")
async def get_child_profile(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.get_child_profile(child_id)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get child profile: {str(e)}")


@router.get("/{child_id}/recommendations-history", response_model=List[RecommendationHistory])
async def get_recommendations_history(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.get_recommendations_history(child_id)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get recommendations history: {str(e)}")


@router.get("/{child_id}/traits")
async def get_child_traits(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get child's genetic traits with mapped keys for display.
    Returns traits with keys: confidence, description, gene, trait_name
    """
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.get_child_traits_mapped(child_id)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get child traits: {str(e)}")


@router.post("/{child_id}/dr-bloom/start")
async def start_dr_bloom_session(
    child_id: str,
    session_data: DrBloomSessionStart,
    current_user: User = Depends(get_current_user)
):
    """Start a Dr. Bloom consultation session."""
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.start_dr_bloom_session(current_user.id, child_id, session_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start Dr. Bloom session: {str(e)}")


@router.post("/{child_id}/dr-bloom/complete")
async def complete_dr_bloom_session(
    child_id: str,
    complete_data: DrBloomSessionComplete,
    current_user: User = Depends(get_current_user)
):
    """Complete a Dr. Bloom session and generate log entry."""
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.complete_dr_bloom_session(current_user.id, child_id, complete_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to complete Dr. Bloom session: {str(e)}")