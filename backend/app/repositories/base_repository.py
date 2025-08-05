from app.core.database import get_db


class BaseRepository:
    def __init__(self):
        self.db = get_db()
        # Collections that should be under 'bloomie/reference'
        self.reference_collections = {
            "trait_references",
            "growth_milestones", 
            "immunity_suggestions"
        }
        # Collections that should be under 'bloomie/data'
        self.data_collections = {
            "users",
            "user_children", 
            "children",
            "medical_visit_logs",
            "conversations",
            "messages"
        }
    
    def get_collection(self, collection_name: str):
        if collection_name in self.reference_collections:
            # Static reference data: bloomie/reference/{collection}
            return self.db.collection("bloomie").document("reference").collection(collection_name)
        elif collection_name in self.data_collections:
            # App data: bloomie/data/{collection}
            return self.db.collection("bloomie").document("data").collection(collection_name)
        else:
            # Fallback to root level (shouldn't happen)
            return self.db.collection(collection_name)