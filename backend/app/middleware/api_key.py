import os
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

class APIKeyMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, api_key: str = None):
        super().__init__(app)
        self.api_key = api_key or os.getenv("API_KEY", "secure-api-key-2025") # Default value for local testing
        if not self.api_key:
            raise ValueError("API_KEY environment variable must be set")

    async def dispatch(self, request: Request, call_next):
        import time
        start_time = time.time()
        
        # Skip API key check for public endpoints
        public_paths = [
            "/health",
            "/docs",
            "/redoc",
            "/openapi.json",
            "/",
            "/auth/login",
            "/auth/register"
        ]
        
        if request.url.path in public_paths:
            return await call_next(request)
        
        # Check for API key in header
        api_key = request.headers.get("X-API-Key")
        
        if not api_key or api_key != self.api_key:
            return JSONResponse(
                status_code=401,
                content={"detail": "Invalid or missing API key"}
            )
        
        response = await call_next(request)
        
        # Log performance timing
        end_time = time.time()
        duration = (end_time - start_time) * 1000  # Convert to milliseconds
        print(f"⏱️ {request.method} {request.url.path} - {duration:.2f}ms")
        
        return response