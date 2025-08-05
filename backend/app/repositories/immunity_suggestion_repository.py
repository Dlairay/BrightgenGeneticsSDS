from typing import List, Dict, Optional
from app.repositories.base_repository import BaseRepository


class ImmunitySuggestionRepository(BaseRepository):
    """Repository for immunity & resilience suggestions."""
    
    def __init__(self):
        super().__init__()
        self.collection = self.get_collection("immunity_suggestions")
    
    async def get_suggestions_for_traits(self, trait_names: List[str]) -> List[Dict]:
        """
        Get all immunity suggestions for a list of trait names.
        
        Args:
            trait_names: List of trait names to get suggestions for
            
        Returns:
            List of suggestion documents
        """
        if not trait_names:
            return []
        
        all_suggestions = []
        
        # Query for each trait name
        for trait_name in trait_names:
            suggestions = self.collection.where(
                "trait_name", "==", trait_name
            ).stream()
            
            for doc in suggestions:
                suggestion_data = doc.to_dict()
                suggestion_data['id'] = doc.id
                all_suggestions.append(suggestion_data)
        
        return all_suggestions
    
    async def get_suggestions_by_archetype(self, archetype: str = "Immunity & Resilience") -> List[Dict]:
        """
        Get all suggestions for a specific archetype.
        
        Args:
            archetype: The archetype to filter by
            
        Returns:
            List of suggestion documents
        """
        suggestions = self.collection.where(
            "archetype", "==", archetype
        ).stream()
        
        result = []
        for doc in suggestions:
            suggestion_data = doc.to_dict()
            suggestion_data['id'] = doc.id
            result.append(suggestion_data)
        
        return result
    
    async def get_grouped_suggestions_for_child(self, trait_names: List[str]) -> Dict[str, List[Dict]]:
        """
        Get suggestions grouped by trait name for display.
        
        Args:
            trait_names: List of trait names from child's profile
            
        Returns:
            Dictionary with trait names as keys and lists of suggestions as values
        """
        suggestions = await self.get_suggestions_for_traits(trait_names)
        
        # Group by trait name
        grouped = {}
        for suggestion in suggestions:
            trait_name = suggestion.get('trait_name', 'Unknown')
            if trait_name not in grouped:
                grouped[trait_name] = []
            
            # Format suggestion for display
            formatted_suggestion = {
                'id': suggestion.get('id'),
                'type': suggestion.get('suggestion_type', ''),  # 'Provide' or 'Avoid'
                'is_positive': suggestion.get('suggestion_type', '').lower() == 'provide',
                'suggestion': suggestion.get('suggestion', ''),
                'rationale': suggestion.get('rationale', ''),
                'archetype': suggestion.get('archetype', '')
            }
            grouped[trait_name].append(formatted_suggestion)
        
        # Sort suggestions within each group - Provide first, then Avoid
        for trait_name in grouped:
            grouped[trait_name].sort(key=lambda x: (not x['is_positive'], x['suggestion']))
        
        return grouped