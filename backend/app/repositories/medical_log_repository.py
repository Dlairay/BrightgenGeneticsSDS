from typing import Dict, List, Optional
from datetime import datetime
from google.cloud import firestore

from app.repositories.base_repository import BaseRepository


class MedicalLogRepository(BaseRepository):
    """Repository for medical visit logs."""
    
    def __init__(self):
        super().__init__()
        self.collection = self.get_collection("medical_visit_logs")
    
    async def save_medical_log(self, log_data: Dict) -> str:
        """
        Save a medical visit log to Firestore.
        
        Args:
            log_data: The medical log data
            
        Returns:
            Document ID of the saved log
        """
        # Make a copy to avoid modifying the original
        log_to_save = log_data.copy()
        
        # Add server timestamp to the copy
        log_to_save['created_at'] = firestore.SERVER_TIMESTAMP
        
        # Create document with auto-generated ID
        doc_ref = self.collection.add(log_to_save)
        doc_id = doc_ref[1].id
        
        print(f"✅ Successfully saved medical visit log {doc_id} for child {log_data.get('child_id')}")
        return doc_id
    
    async def get_medical_logs_for_child(
        self,
        child_id: str,
        limit: int = 10
    ) -> List[Dict]:
        """
        Get medical visit logs for a specific child.
        
        Args:
            child_id: The child's ID
            limit: Maximum number of logs to return
            
        Returns:
            List of medical log documents
        """
        # Optimized: get only what we need, let Firestore handle the work
        try:
            # Try with ordering first (faster if index exists)
            logs = self.collection.where(
                "child_id", "==", child_id
            ).order_by("generation_timestamp", direction=firestore.Query.DESCENDING).limit(limit).stream()
            
            result = []
            for log in logs:
                log_data = log.to_dict()
                log_data['id'] = log.id
                result.append(log_data)
            
            return result
            
        except Exception as e:
            print(f"⚠️ Firestore ordering failed (no index?), falling back to in-memory sort: {e}")
            # Fallback: minimal fetch + in-memory sort
            logs = self.collection.where(
                "child_id", "==", child_id
            ).limit(limit).stream()  # Only get what we actually need
            
            result = []
            for log in logs:
                log_data = log.to_dict()
                log_data['id'] = log.id
                result.append(log_data)
            
            # Sort by timestamp in memory (smaller dataset now)
            result.sort(key=lambda x: x.get('generation_timestamp', ''), reverse=True)
            
            return result
    
    async def get_medical_log_by_id(self, log_id: str) -> Optional[Dict]:
        """
        Get a specific medical log by ID.
        
        Args:
            log_id: The document ID
            
        Returns:
            Medical log document or None
        """
        doc = self.collection.document(log_id).get()
        if doc.exists:
            log_data = doc.to_dict()
            log_data['id'] = doc.id
            return log_data
        return None
    
    async def get_recent_logs_by_trait(
        self,
        child_id: str,
        trait_name: str,
        days: int = 30
    ) -> List[Dict]:
        """
        Get recent medical logs that discussed a specific trait.
        
        Args:
            child_id: The child's ID
            trait_name: The immunity trait name
            days: How many days back to search
            
        Returns:
            List of medical logs mentioning the trait
        """
        # Calculate cutoff date
        from datetime import timedelta
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        # Query logs
        logs = self.collection.where(
            "child_id", "==", child_id
        ).where(
            "immunity_traits_discussed", "array_contains", trait_name
        ).where(
            "generation_timestamp", ">", cutoff_date.isoformat()
        ).stream()
        
        result = []
        for log in logs:
            log_data = log.to_dict()
            log_data['id'] = log.id
            result.append(log_data)
        
        # Sort by timestamp in Python
        result.sort(key=lambda x: x.get('generation_timestamp', ''), reverse=True)
        
        return result