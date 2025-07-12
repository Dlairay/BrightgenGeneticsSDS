from datetime import timedelta
from typing import Optional

from app.core.config import settings
from app.core.security import verify_password, get_password_hash, create_access_token
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate, UserLogin, Token


class AuthService:
    def __init__(self):
        self.user_repo = UserRepository()
    
    async def register(self, user_data: UserCreate) -> Token:
        existing_user = await self.user_repo.get_user_by_email(user_data.email)
        if existing_user:
            raise ValueError("Email already registered")
        
        hashed_password = get_password_hash(user_data.password)
        user_doc = {
            "name": user_data.name,
            "email": user_data.email,
            "password": hashed_password
        }
        
        user_id = await self.user_repo.create_user(user_doc)
        
        access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
        access_token = create_access_token(
            data={"sub": user_id}, expires_delta=access_token_expires
        )
        
        return Token(access_token=access_token, token_type="bearer")
    
    async def login(self, user_data: UserLogin) -> Token:
        user_result = await self.user_repo.get_user_by_email(user_data.email)
        if not user_result:
            raise ValueError("Invalid credentials")
        
        user_id, user_doc = user_result
        
        if not verify_password(user_data.password, user_doc["password"]):
            raise ValueError("Invalid credentials")
        
        access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
        access_token = create_access_token(
            data={"sub": user_id}, expires_delta=access_token_expires
        )
        
        return Token(access_token=access_token, token_type="bearer")