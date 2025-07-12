from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from typing import List
import json

from app.core.security import get_current_user
from app.schemas.user import User
from app.schemas.child import Child, CheckInAnswers, RecommendationHistory, EmergencyCheckIn
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
        content = await file.read()
        genetic_data = json.loads(content.decode('utf-8'))
        
        required_fields = ["child_id", "birthday", "gender", "genotype_profile"]
        for field in required_fields:
            if field not in genetic_data:
                raise HTTPException(status_code=400, detail=f"Missing required field: {field}")
        
        return await child_service.create_child_profile(genetic_data, child_name, current_user.id)
        
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON file")
    except Exception as e:
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


@router.post("/{child_id}/emergency-checkin")
async def emergency_check_in(
    child_id: str,
    emergency_data: EmergencyCheckIn,
    current_user: User = Depends(get_current_user)
):
    try:
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        return await child_service.emergency_check_in(child_id, emergency_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to complete emergency check-in: {str(e)}")