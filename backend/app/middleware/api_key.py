import os
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

class APIKeyMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, api_key: str = None):
        super().__init__(app)
        self.api_key = api_key or os.getenv("API_KEY", "secure-api-key-2025") # Default value for local testing
        if not self.api_key:
            raise ValueError("API_KEY environment variable must be set")

    async def dispatch(self, request: Request, call_next):
        # Log the request for debugging
        print(f"Request to: {request.url.path}")
        print(f"Headers: {dict(request.headers)}")
        
        # Skip API key check for health endpoint
        if request.url.path == "/health":
            return await call_next(request)
        
        # Check for API key in header
        api_key = request.headers.get("X-API-Key")
        if not api_key or api_key != self.api_key:
            print(f"API Key validation failed. Expected: {self.api_key}, Got: {api_key}")
            raise HTTPException(
                status_code=401, 
                detail="Invalid or missing API key"
            )
        
        return await call_next(request)