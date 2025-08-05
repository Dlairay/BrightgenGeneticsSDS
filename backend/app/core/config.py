import os
from typing import Optional
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    jwt_secret_key: str = os.getenv("JWT_SECRET_KEY")
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    base_dir: str = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    data_dir: str = os.path.join(base_dir, "data")
    
    google_application_credentials: Optional[str] = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    gcp_project_id: Optional[str] = os.getenv("GCP_PROJECT_ID")
    firestore_collection_prefix: str = os.getenv("FIRESTORE_COLLECTION_PREFIX", "")
    
    class Config:
        env_file = ".env"
        extra = "allow"  # Allow extra environment variables


settings = Settings()