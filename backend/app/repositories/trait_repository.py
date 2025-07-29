import pandas as pd
from typing import Optional

from app.core.database import get_db


class TraitRepository:
    def __init__(self):
        self.db = get_db()
        self.collection = self.db.collection("trait_references")
        self._cached_df: Optional[pd.DataFrame] = None
    
    async def load_trait_db(self) -> pd.DataFrame:
        if self._cached_df is not None:
            return self._cached_df
        
        docs = self.collection.stream()
        data = []
        for doc in docs:
            data.append(doc.to_dict())
        
        if not data:
            print("Warning: No trait reference data found in Firestore 'trait_references' collection.")
            return pd.DataFrame()
        
        self._cached_df = pd.DataFrame(data)
        print(f"✅ Loaded {len(self._cached_df)} trait references from Firestore.")
        return self._cached_df
    
    async def get(self, trait_id: str) -> Optional[dict]:
        """Get a single trait by ID."""
        doc = self.collection.document(trait_id).get()
        if doc.exists:
            return doc.to_dict()
        return None