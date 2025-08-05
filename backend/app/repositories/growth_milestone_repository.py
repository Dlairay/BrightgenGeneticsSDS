from typing import List, Dict, Optional
from app.repositories.base_repository import BaseRepository


class GrowthMilestoneRepository(BaseRepository):
    """Repository for growth milestone data access."""
    
    def __init__(self):
        super().__init__()
        self.collection_name = "growth_milestones"
    
    async def load_all_milestones(self) -> List[Dict]:
        """Load all growth milestones from Firestore."""
        try:
            collection_ref = self.get_collection(self.collection_name)
            docs = collection_ref.stream()
            
            milestones = []
            for doc in docs:
                milestone_data = doc.to_dict()
                milestone_data['id'] = doc.id
                milestones.append(milestone_data)
            
            if not milestones:
                print("⚠️ No growth milestones found in Firestore")
                return []
            
            print(f"✅ Loaded {len(milestones)} growth milestones from Firestore")
            return milestones
            
        except Exception as e:
            print(f"❌ Error loading growth milestones: {e}")
            return []
    
    async def get_milestones_for_age_range(self, age_start: int, age_end: int) -> List[Dict]:
        """Get milestones for a specific age range."""
        try:
            collection_ref = self.get_collection(self.collection_name)
            
            # Query milestones that overlap with the age range
            docs = collection_ref.where('age_start', '<=', age_end).where('age_end', '>=', age_start).stream()
            
            milestones = []
            for doc in docs:
                milestone_data = doc.to_dict()
                milestone_data['id'] = doc.id
                milestones.append(milestone_data)
            
            return milestones
            
        except Exception as e:
            print(f"❌ Error getting milestones for age range {age_start}-{age_end}: {e}")
            return []
    
    async def get_milestones_for_gene(self, gene_id: str) -> List[Dict]:
        """Get all milestones for a specific gene."""
        try:
            collection_ref = self.get_collection(self.collection_name)
            docs = collection_ref.where('gene_id', '==', gene_id).stream()
            
            milestones = []
            for doc in docs:
                milestone_data = doc.to_dict()
                milestone_data['id'] = doc.id
                milestones.append(milestone_data)
            
            return milestones
            
        except Exception as e:
            print(f"❌ Error getting milestones for gene {gene_id}: {e}")
            return []
    
    async def get_milestones_for_genes_and_age(self, gene_ids: List[str], current_age: int) -> List[Dict]:
        """Get milestones for specific genes that are relevant for current age."""
        try:
            collection_ref = self.get_collection(self.collection_name)
            
            milestones = []
            for gene_id in gene_ids:
                # Get milestones for this gene where current_age falls within age_start and age_end
                docs = collection_ref.where('gene_id', '==', gene_id)\
                                  .where('age_start', '<=', current_age)\
                                  .where('age_end', '>=', current_age)\
                                  .stream()
                
                for doc in docs:
                    milestone_data = doc.to_dict()
                    milestone_data['id'] = doc.id
                    milestones.append(milestone_data)
            
            return milestones
            
        except Exception as e:
            print(f"❌ Error getting milestones for genes {gene_ids} at age {current_age}: {e}")
            return []
    
    async def save_milestone(self, milestone_data: Dict) -> str:
        """Save a milestone to Firestore."""
        try:
            collection_ref = self.get_collection(self.collection_name)
            doc_ref = collection_ref.add(milestone_data)
            milestone_id = doc_ref[1].id
            print(f"✅ Saved milestone with ID: {milestone_id}")
            return milestone_id
            
        except Exception as e:
            print(f"❌ Error saving milestone: {e}")
            raise
    
    async def update_milestone(self, milestone_id: str, update_data: Dict) -> bool:
        """Update an existing milestone."""
        try:
            collection_ref = self.get_collection(self.collection_name)
            doc_ref = collection_ref.document(milestone_id)
            doc_ref.update(update_data)
            print(f"✅ Updated milestone {milestone_id}")
            return True
            
        except Exception as e:
            print(f"❌ Error updating milestone {milestone_id}: {e}")
            return False
    
    async def delete_milestone(self, milestone_id: str) -> bool:
        """Delete a milestone."""
        try:
            collection_ref = self.get_collection(self.collection_name)
            collection_ref.document(milestone_id).delete()
            print(f"✅ Deleted milestone {milestone_id}")
            return True
            
        except Exception as e:
            print(f"❌ Error deleting milestone {milestone_id}: {e}")
            return False