import os
import json
from typing import List, Dict, Literal, Tuple
from dotenv import load_dotenv

import pandas as pd
import vertexai
from vertexai.generative_models import GenerativeModel, Part
from pydantic import BaseModel, ValidationError

# Load environment variables
dotenv_path = os.getenv("DOTENV_PATH")
if dotenv_path:
    load_dotenv(dotenv_path)
else:
    load_dotenv()

# ----- Pydantic schema definitions -----

class Recommendation(BaseModel):
    trait: str
    goal: str
    activity: str

class Entry(BaseModel):
    entry_type: Literal["checkin", "emergency", "initial"]
    interpreted_traits: List[str]
    recommendations: List[Recommendation]
    summary: str
    followup_questions: List[str]

# ----- ChildProfile class definition -----

class ChildProfile:
    def __init__(self, child_id: str, data_root: str, trait_db: pd.DataFrame):
        self.child_id = child_id
        self.data_root = data_root
        self.trait_db = trait_db
        # use child_id directly for folder
        self.profile_dir = os.path.join(data_root, child_id)
        os.makedirs(self.profile_dir, exist_ok=True)
        self.report_fp = os.path.join(self.profile_dir, "report.json")
        self.traits_fp = os.path.join(self.profile_dir, "traits.json")
        self.logs_fp = os.path.join(self.profile_dir, "logs.json")

    @classmethod
    def create_from_report(
        cls,
        profile_data: Dict,
        trait_db: pd.DataFrame,
        data_root: str
    ) -> "ChildProfile":
        child = cls(profile_data["child_id"], data_root, trait_db)
        child.save_report(profile_data)
        child.match_and_save_traits()
        return child

    def load_report(self) -> Dict:
        with open(self.report_fp) as f:
            return json.load(f)

    def save_report(self, data: Dict):
        with open(self.report_fp, "w") as f:
            json.dump(data, f, indent=2)

    def load_traits(self) -> List[Dict]:
        with open(self.traits_fp) as f:
            return json.load(f)

    def save_traits(self, traits: List[Dict]):
        with open(self.traits_fp, "w") as f:
            json.dump(traits, f, indent=2)

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
        if not os.path.exists(self.logs_fp):
            return []
        with open(self.logs_fp) as f:
            return json.load(f)

    def save_log(self, log_entry: Dict):
        """
        Appends a log entry, but ensures only one 'initial' entry exists.
        """
        logs = self.load_logs()
        if log_entry.get('entry_type') == 'initial':
            for existing in logs:
                if existing.get('entry_type') == 'initial':
                    print("⚠️ Initial log entry already exists; skipping append.")
                    return
        logs.append(log_entry)
        with open(self.logs_fp, "w") as f:
            json.dump(logs, f, indent=2)

    def to_json(self) -> Dict:
        return {
            "child_id": self.child_id,
            "report": self.load_report(),
            "traits": self.load_traits(),
            "logs": self.load_logs()
        }

# ----- GenAI integration and utilities -----

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")
LOCATION = os.getenv("GOOGLE_CLOUD_LOCATION")
GOOGLE_GENAI_USE_VERTEXAI = os.getenv("GOOGLE_GENAI_USE_VERTEXAI", "true").lower() == "true"

SYSTEM_INSTRUCTION = (
    "You are a JSON-only assistant. Output exactly one JSON object matching the schema provided. "
    "Do not wrap in markdown or add extra text."
)

def create_prompt(traits: List[Dict]) -> str:
    schema_example = {
        "entry_type": "initial",
        "interpreted_traits": ["trait1", "trait2"],
        "recommendations": [
            {"trait": "example_trait", "goal": "example_goal", "activity": "example_activity"}
        ],
        "summary": "A summary of the log entry.",
        "followup_questions": ["Question 1?", "Question 2?"]
    }
    return (
        f"{SYSTEM_INSTRUCTION}\n"
        f"Based on these genotype-derived traits:\n{json.dumps(traits, indent=2)}\n"
        f"Identify relevant phenotypes and recommendations, then output exactly one JSON matching this schema:\n"
        f"{json.dumps(schema_example, indent=2)}"
    )

def strip_code_fences(text: str) -> str:
    if text.startswith("```"):
        newline_pos = text.find("\n")
        if newline_pos != -1:
            text = text[newline_pos+1:]
        if text.rstrip().endswith("```"):
            text = text.rstrip()[:-3]
    return text.strip()


def generate_log(
    model_name: str = "gemini-2.0-flash",
    traits: List[Dict] = None
) -> Entry:
    prompt = create_prompt(traits or [])
    vertexai.init(project=PROJECT_ID, location=LOCATION)
    model = GenerativeModel(model_name)
    response = model.generate_content([Part.from_text(prompt)])
    cleaned = strip_code_fences(response.text)
    try:
        obj = json.loads(cleaned)
    except json.JSONDecodeError as e:
        print("❌ Invalid JSON after cleaning:", e)
        print(cleaned)
        raise
    try:
        return Entry(**obj)
    except ValidationError as e:
        print("❌ Schema validation failed:")
        print(e.json())
        raise


def create_child_profile(sample_json_path: str) -> Tuple[ChildProfile, Entry]:
    """
    High-level wrapper: given a sample JSON filepath,
    - loads trait reference and profile data
    - creates and saves a ChildProfile
    - generates (once) and saves the initial log
    - returns the ChildProfile and Entry objects
    """
    from config import DATA_DIR, PROFILES_DIR

    trait_csv = os.path.join(DATA_DIR, "Genotype_Trait_Reference.csv")
    trait_db = pd.read_csv(trait_csv)

    with open(sample_json_path, "r") as f:
        profile_data = json.load(f)

    child = ChildProfile.create_from_report(
        profile_data,
        trait_db,
        data_root=PROFILES_DIR
    )

    traits_fp = os.path.join(PROFILES_DIR, profile_data['child_id'], "traits.json")
    with open(traits_fp, "r") as f:
        traits_data = json.load(f)

    entry = generate_log(traits=traits_data)
    child.save_log(entry.model_dump())

    return child, entry


if __name__ == "__main__":
    from config import DATA_DIR
    default_json = os.path.join(DATA_DIR, "sample_upload.json")
    child, entry = create_child_profile(default_json)
    print(json.dumps(child.to_json(), indent=2))
    print("✅ Initial log entry:")
    print(entry.model_dump_json(indent=2))
