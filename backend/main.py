import logging
import os

# Set environment variable to suppress Google ADK logs
os.environ['GRPC_VERBOSITY'] = 'ERROR'
os.environ['GLOG_minloglevel'] = '2'

# Suppress Google ADK verbose logs BEFORE importing anything else
logging.basicConfig(level=logging.WARNING, format='%(message)s')  # Only show warnings and errors

# Completely silence Google ADK loggers
for logger_name in [
    'google_adk', 'google.adk', 'google_genai', 'google.genai',
    'google_adk.google.adk.models.registry', 'google.adk.models.registry',
    'google_adk.google.adk.models', 'google.adk.models'
]:
    logging.getLogger(logger_name).setLevel(logging.CRITICAL)
    logging.getLogger(logger_name).disabled = True

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from app.api import auth, children, chatbot, medical_logs, immunity, growth_milestones
from app.middleware.api_key import APIKeyMiddleware

logger = logging.getLogger(__name__)

app = FastAPI(title="Child Genetic Profiling API", version="2.0.0")

print("🚀 Child Genetic Profiling API v2.0.0 starting...")

# Add middlewares
app.add_middleware(APIKeyMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API routes
app.include_router(auth.router)
app.include_router(children.router)
app.include_router(chatbot.router)
app.include_router(medical_logs.router)
app.include_router(immunity.router)
app.include_router(growth_milestones.router, prefix="/growth-milestones", tags=["Growth Milestones"])

print("✅ API ready - all routes and middlewares configured")


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)