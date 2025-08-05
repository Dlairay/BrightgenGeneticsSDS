from typing import Dict, List
from app.repositories.child_repository import ChildRepository
from app.repositories.immunity_suggestion_repository import ImmunitySuggestionRepository
from app.repositories.medical_log_repository import MedicalLogRepository


class ImmunityService:
    """Service for immunity & resilience features."""
    
    def __init__(self):
        self.child_repo = ChildRepository()
        self.immunity_suggestion_repo = ImmunitySuggestionRepository()
        self.medical_log_repo = MedicalLogRepository()
    
    async def get_immunity_suggestions_for_child(self, child_id: str) -> Dict:
        """
        Get personalized immunity suggestions based on child's traits.
        
        Args:
            child_id: The child's ID
            
        Returns:
            Dictionary containing grouped suggestions and child info
        """
        # Get child's traits
        all_traits = await self.child_repo.load_traits(child_id)
        
        # Filter for immunity & resilience traits
        immunity_traits = [
            trait for trait in all_traits
            if trait.get('archetype', '').lower() == 'immunity & resilience'
        ]
        
        # Extract trait names
        trait_names = [trait.get('trait_name', '') for trait in immunity_traits if trait.get('trait_name')]
        
        # Get grouped suggestions
        grouped_suggestions = await self.immunity_suggestion_repo.get_grouped_suggestions_for_child(trait_names)
        
        # Get child info for display
        report_data = await self.child_repo.load_report(child_id)
        child_name = report_data.get('name', 'Child')
        
        return {
            'child_id': child_id,
            'child_name': child_name,
            'immunity_traits': immunity_traits,
            'suggestions_by_trait': grouped_suggestions,
            'total_traits': len(immunity_traits),
            'total_suggestions': sum(len(suggestions) for suggestions in grouped_suggestions.values())
        }
    
    async def get_immunity_dashboard_data(self, child_id: str, medical_logs_limit: int = 5) -> Dict:
        """
        Get complete immunity dashboard data including pre-computed suggestions and fresh medical logs.
        
        Args:
            child_id: The child's ID
            medical_logs_limit: Number of recent medical logs to include
            
        Returns:
            Dictionary containing suggestions and medical logs
        """
        # Get PRE-COMPUTED suggestions (much faster!)
        suggestions_data = await self.child_repo.load_immunity_data(child_id)
        
        # Fallback: if no pre-computed data, compute on-the-fly (for backwards compatibility)
        if not suggestions_data:
            print(f"⚠️ No pre-computed immunity data found for child {child_id}, computing on-the-fly...")
            suggestions_data = await self.get_immunity_suggestions_for_child(child_id)
        
        # Get recent medical logs (these need to be fresh)
        medical_logs = await self.medical_log_repo.get_medical_logs_for_child(
            child_id, 
            limit=medical_logs_limit
        )
        
        # Format medical logs for display
        formatted_logs = []
        for log in medical_logs:
            # Extract the raw fields
            problem_discussed = log.get('problem_discussed', '')
            emergency_warning = log.get('emergency_warning')
            
            formatted_logs.append({
                'id': log.get('id'),
                'date': log.get('generation_timestamp', ''),
                'conversation_date': log.get('conversation_date', ''),
                'primary_concerns': [problem_discussed] if problem_discussed else [],  # Only add if not empty
                'summary': problem_discussed,  # Use problem_discussed as summary
                'traits_discussed': log.get('immunity_traits_mentioned', []),  # Correct field name
                'questions_for_doctor': log.get('follow_up_questions', []),  # Correct field name
                'emergency_indicators': [emergency_warning] if emergency_warning else [],  # Convert to array
                # Also include raw fields for debugging
                'raw_problem_discussed': problem_discussed,
                'raw_immediate_recommendations': log.get('immediate_recommendations', []),
                'raw_follow_up_questions': log.get('follow_up_questions', []),
                'raw_disclaimer': log.get('disclaimer', ''),
                'raw_immunity_traits_mentioned': log.get('immunity_traits_mentioned', [])
            })
        
        return {
            'suggestions': suggestions_data,
            'medical_logs': {
                'logs': formatted_logs,
                'total_count': len(formatted_logs),
                'has_emergency_indicators': any(
                    log.get('emergency_indicators', []) for log in formatted_logs
                )
            }
        }