from fastapi import APIRouter, HTTPException, Depends
from typing import Optional

from app.core.security import get_current_user
from app.schemas.user import User
from app.repositories.child_repository import ChildRepository
from app.services.immunity_service import ImmunityService

router = APIRouter(prefix="/immunity", tags=["immunity"])
child_repo = ChildRepository()
immunity_service = ImmunityService()


@router.get("/{child_id}/suggestions")
async def get_immunity_suggestions(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get personalized immunity & resilience suggestions for a child based on their genetic traits.
    
    Returns suggestions grouped by trait name with:
    - Suggestion type (Provide/Avoid) shown as tick/cross
    - The suggestion text
    - Rationale for the suggestion
    """
    try:
        # Verify user has access to child
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Get immunity suggestions
        suggestions_data = await immunity_service.get_immunity_suggestions_for_child(child_id)
        
        return suggestions_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve immunity suggestions: {str(e)}")


@router.get("/{child_id}/dashboard")
async def get_immunity_dashboard(
    child_id: str,
    medical_logs_limit: Optional[int] = 5,
    current_user: User = Depends(get_current_user)
):
    """
    Get complete immunity dashboard data including suggestions and medical logs.
    
    This endpoint provides all data needed for the immunity page:
    1. Personalized suggestions based on genetic traits
    2. Recent medical visit logs from Dr. Bloom consultations
    """
    print(f"🛡️ IMMUNITY DASHBOARD REQUEST: child_id={child_id}, user={current_user.email}")
    try:
        # Verify user has access to child
        print(f"🔒 CHECKING ACCESS: user {current_user.id} to child {child_id}")
        has_access = await child_repo.user_has_access_to_child(current_user.id, child_id)
        print(f"🔑 ACCESS RESULT: {has_access}")
        
        if not has_access:
            print(f"❌ ACCESS DENIED: user {current_user.id} cannot access child {child_id}")
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Get dashboard data
        print(f"📊 FETCHING DASHBOARD DATA for child {child_id}")
        dashboard_data = await immunity_service.get_immunity_dashboard_data(
            child_id, 
            medical_logs_limit
        )
        
        print(f"✅ IMMUNITY DASHBOARD SUCCESS: {len(dashboard_data.get('suggestions', {}).get('immunity_traits', []))} traits found")
        return dashboard_data
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"💥 IMMUNITY DASHBOARD ERROR: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve immunity dashboard: {str(e)}")


@router.get("/{child_id}/traits")
async def get_child_immunity_traits(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get only the immunity & resilience traits for a child.
    
    This is useful for understanding which genetic traits are driving the suggestions.
    """
    try:
        # Verify user has access to child
        if not await child_repo.user_has_access_to_child(current_user.id, child_id):
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Get all traits
        all_traits = await child_repo.load_traits(child_id)
        
        # Filter for immunity traits
        immunity_traits = [
            {
                'trait_name': trait.get('trait_name'),
                'gene': trait.get('gene'),
                'description': trait.get('description'),
                'confidence': trait.get('confidence'),
                'rs_id': trait.get('rs_id'),
                'genotype': trait.get('genotype')
            }
            for trait in all_traits
            if trait.get('archetype', '').lower() == 'immunity & resilience'
        ]
        
        return {
            'child_id': child_id,
            'immunity_traits': immunity_traits,
            'total_count': len(immunity_traits)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve immunity traits: {str(e)}")