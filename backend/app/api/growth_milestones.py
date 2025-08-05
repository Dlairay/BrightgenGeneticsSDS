from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any
from app.core.security import get_current_user
from app.services.growth_milestone_service import GrowthMilestoneService

router = APIRouter()


@router.get("/{child_id}/roadmap")
async def get_child_growth_roadmap(
    child_id: str,
    current_user: dict = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get the complete growth milestone roadmap for a child.
    
    Returns a roadmap showing all age-based milestones for the child's
    Growth & Development genetic traits, organized by age groups.
    """
    try:
        milestone_service = GrowthMilestoneService()
        roadmap = await milestone_service.get_child_roadmap(child_id)
        
        return {
            "success": True,
            "data": roadmap
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving growth roadmap: {str(e)}"
        )


@router.get("/{child_id}/current")
async def get_current_milestones(
    child_id: str,
    current_user: dict = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get only the current age milestones for a child.
    
    Returns milestones that are relevant for the child's current age,
    focusing on immediate Growth & Development recommendations.
    """
    try:
        milestone_service = GrowthMilestoneService()
        current_milestones = await milestone_service.get_current_milestones(child_id)
        
        return {
            "success": True,
            "data": current_milestones
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving current milestones: {str(e)}"
        )


@router.get("/{child_id}/overview")
async def get_milestone_overview(
    child_id: str,
    current_user: dict = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get a high-level overview of all milestones for a child.
    
    Returns summary statistics and next upcoming milestone information
    for the child's Growth & Development journey.
    """
    try:
        milestone_service = GrowthMilestoneService()
        overview = await milestone_service.get_milestone_overview(child_id)
        
        return {
            "success": True,
            "data": overview
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving milestone overview: {str(e)}"
        )