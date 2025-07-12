from google.cloud import firestore
from typing import Optional

_db_instance: Optional[firestore.Client] = None


def get_db() -> firestore.Client:
    global _db_instance
    if _db_instance is None:
        _db_instance = firestore.Client()
        print(f"Firestore Client initialized. Project ID: {_db_instance.project}")
    return _db_instance