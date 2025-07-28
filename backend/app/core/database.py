from google.cloud import firestore
from typing import Optional
import os

_db_instance: Optional[firestore.Client] = None


def get_db() -> firestore.Client:
    global _db_instance
    if _db_instance is None:
        # For Cloud Run, use default credentials (automatic)
        # For local development, use service account key if available
        credentials_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
        if credentials_path and os.path.exists(credentials_path):
            print(f"Using service account credentials from: {credentials_path}")
            _db_instance = firestore.Client()
        else:
            # Cloud Run or other environment with default credentials
            print("Using default Google Cloud credentials")
            _db_instance = firestore.Client()
        print(f"Firestore Client initialized. Project ID: {_db_instance.project}")
    return _db_instance