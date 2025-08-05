from fastapi import APIRouter, HTTPException, Depends
from typing import List

from app.core.security import get_current_user
from app.schemas.user import User
from app.repositories.child_repository import ChildRepository
from app.repositories.medical_log_repository import MedicalLogRepository

router = APIRouter(prefix="/medical-logs", tags=["medical_logs"])
child_repo = ChildRepository()
medical_log_repo = MedicalLogRepository()


@router.get("/{child_id}")
async def get_medical_logs(
    child_id: str,
    limit: int = 10,
    current_user: User = Depends(get_current_user)
):
    """Get medical visit logs for a child."""
    try:
        # Verify user has access to child
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Get medical logs
        logs = await medical_log_repo.get_medical_logs_for_child(child_id, limit)
        
        return {
            "child_id": child_id,
            "logs": logs,
            "count": len(logs)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve medical logs: {str(e)}")


@router.get("/{child_id}/log/{log_id}")
async def get_medical_log_detail(
    child_id: str,
    log_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific medical visit log."""
    try:
        # Verify user has access to child
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Get the log
        log = await medical_log_repo.get_medical_log_by_id(log_id)
        
        if not log:
            raise HTTPException(status_code=404, detail="Medical log not found")
        
        # Verify the log belongs to the child
        if log.get("child_id") != child_id:
            raise HTTPException(status_code=403, detail="Log does not belong to this child")
        
        return log
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve medical log: {str(e)}")


@router.get("/{child_id}/by-trait/{trait_name}")
async def get_medical_logs_by_trait(
    child_id: str,
    trait_name: str,
    days: int = 30,
    current_user: User = Depends(get_current_user)
):
    """Get medical logs that discussed a specific immunity trait."""
    try:
        # Verify user has access to child
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Get logs for the trait
        logs = await medical_log_repo.get_recent_logs_by_trait(child_id, trait_name, days)
        
        return {
            "child_id": child_id,
            "trait_name": trait_name,
            "days_searched": days,
            "logs": logs,
            "count": len(logs)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve medical logs by trait: {str(e)}")