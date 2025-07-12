from typing import Optional, Dict
from google.cloud import firestore

from app.core.database import get_db


class UserRepository:
    def __init__(self):
        self.db = get_db()
        self.collection = self.db.collection("users")
    
    async def create_user(self, user_data: Dict) -> str:
        user_doc = {
            **user_data,
            "created_at": firestore.SERVER_TIMESTAMP
        }
        user_ref = self.collection.add(user_doc)
        return user_ref[1].id
    
    async def get_user_by_email(self, email: str) -> Optional[tuple[str, Dict]]:
        users = self.collection.where("email", "==", email).limit(1).get()
        user_list = list(users)
        if user_list:
            user_doc = user_list[0]
            return user_doc.id, user_doc.to_dict()
        return None
    
    async def get_user_by_id(self, user_id: str) -> Optional[Dict]:
        user_doc = self.collection.document(user_id).get()
        if user_doc.exists:
            return user_doc.to_dict()
        return None