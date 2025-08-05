from typing import List, Dict, Optional
from google.cloud import firestore
import datetime

from app.repositories.base_repository import BaseRepository
from app.models.child_profile import ChildProfile


def _convert_firestore_timestamps_to_strings(obj):
    if isinstance(obj, datetime.datetime):
        return obj.isoformat()
    elif isinstance(obj, dict):
        return {k: _convert_firestore_timestamps_to_strings(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [_convert_firestore_timestamps_to_strings(elem) for elem in obj]
    else:
        return obj


class ChildRepository(BaseRepository):
    def __init__(self):
        super().__init__()
        self.profiles_collection = self.get_collection("children")
        self.user_children_collection = self.get_collection("user_children")
    
    async def get_profile_doc_ref(self, child_id: str) -> firestore.DocumentReference:
        return self.profiles_collection.document(str(child_id))
    
    async def save_report(self, child_id: str, data: Dict):
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc_ref.set({"report": data}, merge=True)
        print(f"✅ Successfully saved report for Child ID {child_id} to Firestore.")
    
    async def load_report(self, child_id: str) -> Dict:
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc = doc_ref.get()
        if doc.exists:
            return doc.to_dict().get("report", {})
        return {}
    
    async def save_traits(self, child_id: str, traits: List[Dict]):
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc_ref.set({"traits": traits}, merge=True)
        print(f"✅ Successfully saved traits for Child ID {child_id} to Firestore.")
    
    async def load_traits(self, child_id: str) -> List[Dict]:
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc = doc_ref.get()
        if doc.exists:
            return doc.to_dict().get("traits", [])
        return []
    
    async def save_log(self, child_id: str, log_entry: Dict):
        doc_ref = await self.get_profile_doc_ref(child_id)
        logs_collection_ref = doc_ref.collection('logs')
        
        log_entry_to_save = log_entry.copy()
        
        if log_entry_to_save.get('entry_type') == 'initial':
            initial_logs = logs_collection_ref.where('entry_type', '==', 'initial').stream()
            if any(True for _ in initial_logs):
                print("⚠️ Initial log entry already exists in Firestore; skipping append.")
                return
        
        log_entry_to_save['timestamp'] = firestore.SERVER_TIMESTAMP
        logs_collection_ref.add(log_entry_to_save)
        print(f"✅ Successfully saved log for Child ID {child_id} to Firestore.")
    
    async def load_logs(self, child_id: str) -> List[Dict]:
        doc_ref = await self.get_profile_doc_ref(child_id)
        logs_ref = doc_ref.collection('logs').order_by(
            'timestamp', direction=firestore.Query.ASCENDING
        )
        logs = [doc.to_dict() for doc in logs_ref.stream()]
        print(f"DEBUG: Retrieved {len(logs)} logs for Child ID {child_id} from Firestore.")
        return logs
    
    async def associate_child_with_user(self, user_id: str, child_id: str):
        # Check if association already exists
        existing_docs = self.user_children_collection.where("user_id", "==", user_id).where("child_id", "==", child_id).limit(1).get()
        
        if len(list(existing_docs)) > 0:
            print(f"⚠️ Association between user {user_id} and child {child_id} already exists; skipping creation.")
            return
        
        user_child_doc = {
            "user_id": user_id,
            "child_id": child_id,
            "created_at": firestore.SERVER_TIMESTAMP
        }
        self.user_children_collection.add(user_child_doc)
        print(f"✅ Successfully associated child {child_id} with user {user_id}.")
    
    async def get_children_for_user(self, user_id: str) -> List[str]:
        children_docs = self.user_children_collection.where("user_id", "==", user_id).get()
        child_ids = [doc.to_dict()["child_id"] for doc in children_docs]
        # Remove duplicates while preserving order
        return list(dict.fromkeys(child_ids))
    
    async def user_has_access_to_child(self, user_id: str, child_id: str) -> bool:
        docs = self.user_children_collection.where("user_id", "==", user_id).where("child_id", "==", child_id).limit(1).get()
        return len(list(docs)) > 0
    
    async def get_child_profile_json(self, child_id: str) -> Dict:
        report_data = await self.load_report(child_id)
        traits_data = await self.load_traits(child_id)
        logs_data = await self.load_logs(child_id)
        
        return {
            "child_id": child_id,
            "report": _convert_firestore_timestamps_to_strings(report_data),
            "traits": _convert_firestore_timestamps_to_strings(traits_data),
            "logs": _convert_firestore_timestamps_to_strings(logs_data)
        }
    
    async def save_immunity_data(self, child_id: str, immunity_data: Dict):
        """Save pre-computed immunity recommendations to child profile."""
        immunity_data['created_at'] = firestore.SERVER_TIMESTAMP
        immunity_data['last_updated'] = firestore.SERVER_TIMESTAMP
        
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc_ref.set({"immunity_recommendations": immunity_data}, merge=True)
    
    async def load_immunity_data(self, child_id: str) -> Dict:
        """Load pre-computed immunity recommendations from child profile."""
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc = doc_ref.get()
        if doc.exists:
            data = doc.to_dict()
            return data.get("immunity_recommendations", {})
        return {}
    
    async def save_roadmap_data(self, child_id: str, roadmap_data: Dict):
        """Save pre-computed growth roadmap to child profile."""
        roadmap_data['created_at'] = firestore.SERVER_TIMESTAMP
        roadmap_data['last_updated'] = firestore.SERVER_TIMESTAMP
        
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc_ref.set({"roadmap": roadmap_data}, merge=True)
    
    async def load_roadmap_data(self, child_id: str) -> Dict:
        """Load pre-computed growth roadmap from child profile."""
        doc_ref = await self.get_profile_doc_ref(child_id)
        doc = doc_ref.get()
        if doc.exists:
            data = doc.to_dict()
            return data.get("roadmap", {})
        return {}