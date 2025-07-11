import os
import json
from typing import List, Dict, Tuple, Any, Union # Added Union for get_derived_age
from dotenv import load_dotenv
import pandas as pd
from google.cloud import firestore
import datetime

load_dotenv()

# Initialize Firestore Client
db = firestore.Client()
print(f"Firestore Client in childprofile.py initialized. Project ID: {db.project}")


# ----- Helper function for recursive timestamp conversion -----
def _convert_firestore_timestamps_to_strings(obj: Any) -> Any:
    """
    Recursively converts Firestore DatetimeWithNanoseconds objects to ISO 8601 strings
    within dictionaries and lists.
    """
    if isinstance(obj, datetime.datetime):
        return obj.isoformat()
    elif isinstance(obj, dict):
        return {k: _convert_firestore_timestamps_to_strings(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [_convert_firestore_timestamps_to_strings(elem) for elem in obj]
    else:
        return obj

# NEW: Function to load trait data from Firestore
async def load_trait_db_from_firestore() -> pd.DataFrame:
    """Loads trait reference data from Firestore into a pandas DataFrame."""
    collection_ref = db.collection("trait_references") # Use your new collection name
    docs = collection_ref.stream()
    
    data = []
    for doc in docs:
        data.append(doc.to_dict())
    
    if not data:
        print("Warning: No trait reference data found in Firestore 'trait_references' collection.")
        return pd.DataFrame() # Return empty DataFrame if no data

    df = pd.DataFrame(data)
    print(f"✅ Loaded {len(df)} trait references from Firestore.")
    return df

# ----- ChildProfile class definition -----

class ChildProfile:
    def __init__(self, child_id: str, trait_db: pd.DataFrame):
        self.child_id = child_id
        self.trait_db = trait_db # This will now be a DataFrame loaded from Firestore
        self.profile_doc_ref = db.collection('profiles').document(str(self.child_id))

    @classmethod
    def create_from_report(
        cls,
        profile_data: Dict,
        trait_db: pd.DataFrame,
    ) -> "ChildProfile":
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
            # Query the in-memory trait_db DataFrame
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
        logs_ref = self.profile_doc_ref.collection('logs').order_by(
            'timestamp', direction=firestore.Query.ASCENDING
        )
        logs = [doc.to_dict() for doc in logs_ref.stream()]
        print(f"DEBUG (ChildProfile.load_logs): Retrieved {len(logs)} logs for Child ID {self.child_id} from Firestore.")
        return logs

    def save_log(self, log_entry: Dict):
        """
        Appends a log entry, but ensures only one 'initial' entry exists.
        """
        logs_collection_ref = self.profile_doc_ref.collection('logs')

        log_entry_to_save = log_entry.copy()

        if log_entry_to_save.get('entry_type') == 'initial':
            initial_logs = logs_collection_ref.where('entry_type', '==', 'initial').stream()
            if any(true for true in initial_logs):
                print("⚠️ Initial log entry already exists in Firestore; skipping append.")
                return

        log_entry_to_save['timestamp'] = firestore.SERVER_TIMESTAMP
        
        logs_collection_ref.add(log_entry_to_save)
        print(f"✅ Successfully saved log for Child ID {self.child_id} to Firestore.")

    def to_json(self) -> Dict:
        report_data = self.load_report()
        traits_data = self.load_traits()
        logs_data = self.load_logs() 

        report_data_converted = _convert_firestore_timestamps_to_strings(report_data)
        traits_data_converted = _convert_firestore_timestamps_to_strings(traits_data)
        logs_data_converted = _convert_firestore_timestamps_to_strings(logs_data)

        return {
            "child_id": self.child_id,
            "report": report_data_converted,
            "traits": traits_data_converted,
            "logs": logs_data_converted
        }
    
    def get_derived_age(self) -> Union[int, None]:
        """
        Derives the current age of the child from their birthday stored in the report.
        Returns None if birthday is not found or cannot be parsed.
        """
        report_data = self.load_report()
        birthday_str = report_data.get("birthday")
        if birthday_str:
            try:
                # Assuming birthday is in 'YYYY-MM-DD' format
                birth_date = datetime.datetime.strptime(birthday_str, '%Y-%m-%d').date()
                today = datetime.date.today()
                age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
                return age
            except ValueError:
                print(f"Warning: Could not parse birthday '{birthday_str}' from report. Cannot derive age.")
                return None
        return None


# ----- High-level wrapper function -----

async def create_child_profile(sample_json_path: str) -> Tuple[ChildProfile, Dict]:
    """
    High-level wrapper: given a sample JSON filepath,
    - loads trait reference and profile data from Firestore
    - creates and saves a ChildProfile using Firestore
    - generates (once) and saves the initial log using agent.py
    - returns the ChildProfile and Entry objects
    """
    from config import DATA_DIR
    from planner_agent.agent import LogGenerationService 

    # Load trait_db from Firestore instead of CSV
    trait_db = await load_trait_db_from_firestore() # Await this asynchronous call

    if trait_db.empty:
        raise RuntimeError("Trait reference data could not be loaded from Firestore. Cannot create child profile.")

    with open(sample_json_path, "r") as f:
        profile_data = json.load(f)

    child = ChildProfile.create_from_report(
        profile_data,
        trait_db,
    )

    traits_data = child.load_traits()
    
    log_service = LogGenerationService()
    
    # Get derived age and gender from the child profile for the agent
    derived_age = child.get_derived_age()
    gender = profile_data.get("gender") # Gender is directly in the report data

    entry = await log_service.generate_initial_log(
        traits_data, 
        derived_age=derived_age, 
        gender=gender
    )
    
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
