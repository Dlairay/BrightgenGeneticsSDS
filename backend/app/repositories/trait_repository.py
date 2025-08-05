import pandas as pd
from typing import Optional

from app.repositories.base_repository import BaseRepository


class TraitRepository(BaseRepository):
    def __init__(self):
        super().__init__()
        self.collection = self.get_collection("trait_references")
        self._cached_df: Optional[pd.DataFrame] = None
    
    async def load_trait_db(self, force_reload: bool = False) -> pd.DataFrame:
        if self._cached_df is not None and not force_reload:
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