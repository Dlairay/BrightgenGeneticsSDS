import os
import json
from typing import List, Dict, Tuple, Any
from dotenv import load_dotenv
import pandas as pd
from google.cloud import firestore # Import firestore
import datetime # Import datetime for type checking

load_dotenv()

# Initialize Firestore Client
db = firestore.Client()

# ----- Helper function for recursive timestamp conversion -----
def _convert_firestore_timestamps_to_strings(obj: Any) -> Any:
    """
    Recursively converts Firestore DatetimeWithNanoseconds objects to ISO 8601 strings
    within dictionaries and lists.
    """
    if isinstance(obj, datetime.datetime): # DatetimeWithNanoseconds is a subclass of datetime.datetime
        return obj.isoformat()
    elif isinstance(obj, dict):
        return {k: _convert_firestore_timestamps_to_strings(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [_convert_firestore_timestamps_to_strings(elem) for elem in obj]
    else:
        return obj

# ----- ChildProfile class definition -----

class ChildProfile:
    def __init__(self, child_id: str, trait_db: pd.DataFrame): # Removed data_root
        self.child_id = child_id
        self.trait_db = trait_db
        # Reference to the Firestore document for this child's profile
        self.profile_doc_ref = db.collection('profiles').document(str(self.child_id))
        # Ensure the document exists (implicitly created on first write)
        
        # No more local file paths

    @classmethod
    def create_from_report(
        cls,
        profile_data: Dict,
        trait_db: pd.DataFrame,
        # data_root: str # Removed data_root from classmethod
    ) -> "ChildProfile":
        # Pass only necessary arguments to __init__
        child = cls(profile_data["child_id"], trait_db) 
        child.save_report(profile_data)
        child.match_and_save_traits()
        return child

    def load_report(self) -> Dict:
        doc = self.profile_doc_ref.get()
        if doc.exists:
            return doc.to_dict().get("report", {})
        return {}

    def save_report(self, data: Dict):
        # Firestore set with merge=True will create the document if it doesn't exist
        self.profile_doc_ref.set({"report": data}, merge=True)
        print(f"✅ Successfully saved report for Child ID {self.child_id} to Firestore.")

    def load_traits(self) -> List[Dict]:
        doc = self.profile_doc_ref.get()
        if doc.exists:
            return doc.to_dict().get("traits", [])
        return []

    def save_traits(self, traits: List[Dict]):
        self.profile_doc_ref.set({"traits": traits}, merge=True)
        print(f"✅ Successfully saved traits for Child ID {self.child_id} to Firestore.")

    def match_traits(self) -> List[Dict]:
        profile = self.load_report()
        matched = []
        for entry in profile.get("genotype_profile", []):
            rs = entry.get("rs_id")
            genotype = entry.get("genotype")
            rows = self.trait_db[
                (self.trait_db["rs_id"] == rs) &
                (self.trait_db["genotype"] == genotype)
            ]
            for _, row in rows.iterrows():
                matched.append(row.to_dict())
        return matched

    def match_and_save_traits(self) -> List[Dict]:
        traits = self.match_traits()
        self.save_traits(traits)
        return traits

    def load_logs(self) -> List[Dict]:
        # Read from the 'logs' subcollection
        logs_ref = self.profile_doc_ref.collection('logs').order_by(
            'timestamp', direction=firestore.Query.ASCENDING
        )
        logs = [doc.to_dict() for doc in logs_ref.stream()]
        
        # The recursive conversion function in to_json will handle timestamps
        return logs

    def save_log(self, log_entry: Dict):
        """
        Appends a log entry, but ensures only one 'initial' entry exists.
        """
        logs_collection_ref = self.profile_doc_ref.collection('logs')

        # Make a copy of the log_entry to avoid modifying the original dictionary
        log_entry_to_save = log_entry.copy()

        if log_entry_to_save.get('entry_type') == 'initial':
            # Check for existing initial entries in Firestore
            initial_logs = logs_collection_ref.where('entry_type', '==', 'initial').stream()
            if any(true for true in initial_logs):
                print("⚠️ Initial log entry already exists in Firestore; skipping append.")
                return

        # Add a server-side timestamp for ordering.
        log_entry_to_save['timestamp'] = firestore.SERVER_TIMESTAMP
        
        # Save the log entry as a new document in the subcollection
        logs_collection_ref.add(log_entry_to_save)
        print(f"✅ Successfully saved log for Child ID {self.child_id} to Firestore.")

    def to_json(self) -> Dict:
        # Retrieve data from Firestore (now using Firestore methods)
        report_data = self.load_report()
        traits_data = self.load_traits()
        logs_data = self.load_logs() 

        # Apply the recursive conversion to all data structures before returning
        report_data_converted = _convert_firestore_timestamps_to_strings(report_data)
        traits_data_converted = _convert_firestore_timestamps_to_strings(traits_data)
        logs_data_converted = _convert_firestore_timestamps_to_strings(logs_data)

        return {
            "child_id": self.child_id,
            "report": report_data_converted,
            "traits": traits_data_converted,
            "logs": logs_data_converted
        }


# ----- High-level wrapper function -----

async def create_child_profile(sample_json_path: str) -> Tuple[ChildProfile, Dict]:
    """
    High-level wrapper: given a sample JSON filepath,
    - loads trait reference and profile data
    - creates and saves a ChildProfile using Firestore
    - generates (once) and saves the initial log using agent.py
    - returns the ChildProfile and Entry objects
    """
    from config import DATA_DIR # PROFILES_DIR is no longer needed here if ChildProfile handles paths
    from planner_agent.agent import LogGenerationService

    trait_csv = os.path.join(DATA_DIR, "Genotype_Trait_Reference.csv")
    trait_db = pd.read_csv(trait_csv)

    with open(sample_json_path, "r") as f:
        profile_data = json.load(f)

    # Initialize ChildProfile without data_root
    child = ChildProfile.create_from_report(
        profile_data,
        trait_db,
        # data_root=PROFILES_DIR # Removed this
    )

    traits_data = child.load_traits()
    
    # Use the agent service to generate the initial log
    log_service = LogGenerationService()
    entry = await log_service.generate_initial_log(traits_data)
    
    # Pass the entry to child's save_log which now handles Firestore saving
    child.save_log(entry)

    return child, entry


if __name__ == "__main__":
    import asyncio
    from config import DATA_DIR
    
    async def main():
        default_json = os.path.join(DATA_DIR, "sample_upload.json")
        child, entry = await create_child_profile(default_json)
        print(json.dumps(child.to_json(), indent=2))
        print("✅ Initial log entry:")
        print(json.dumps(entry, indent=2))
    
    asyncio.run(main())