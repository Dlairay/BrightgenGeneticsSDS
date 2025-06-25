import os
import pandas as pd
import json
from config import  DATA_DIR, PROFILES_DIR

def _get_profile_path(child_id: str) -> str:
    """
    Generate the file path for a child's profile based on their ID.
    """
    return os.path.join(PROFILES_DIR, f"child_{child_id}")

def get_child_log(child_id: str) -> str:
    """
    Get the log for child.
    """
    if _get_profile_path(child_id) is None:
        raise ValueError(f"Profile path for child {child_id} does not exist.")
    else:
        logs_fp = os.path.join(_get_profile_path(child_id), "logs.json")
        with open(logs_fp, 'r', encoding='utf-8') as f:
            logs_data = json.load(f)
    return logs_data


if __name__ == "__main__":
    print("Profile path for child '001':", _get_profile_path("001"))
    print("Child log for '001':", get_child_log("001"))