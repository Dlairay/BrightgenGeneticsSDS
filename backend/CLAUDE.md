# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Running the Application
```bash
# Start the FastAPI server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Environment Setup
```bash
# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Architecture Overview

This is a FastAPI-based backend for a child genetic profiling system with clean layered architecture.

### Folder Structure
```
app/
├── api/              # API route handlers
├── core/             # Core configuration and security
├── models/           # Data models
├── services/         # Business logic layer
├── repositories/     # Database access layer
├── schemas/          # Pydantic request/response schemas
└── agents/           # AI agent logic
```

### Core Components

1. **API Layer** (`app/api/`):
   - `auth.py` - Authentication endpoints
   - `children.py` - Child management, check-ins, emergency reports

2. **Service Layer** (`app/services/`):
   - `auth_service.py` - Authentication business logic
   - `child_service.py` - Child profile and check-in logic

3. **Repository Layer** (`app/repositories/`):
   - `user_repository.py` - User data access
   - `child_repository.py` - Child profile data access
   - `trait_repository.py` - Genetic trait data access

4. **Core** (`app/core/`):
   - `config.py` - Application configuration
   - `security.py` - JWT authentication
   - `database.py` - Firestore client

5. **AI Agents** (`app/agents/planner_agent/`):
   - `agent.py` - LogGenerationService for recommendations

### Key Features

- **Weekly Check-ins**: Smart logic handling emergency follow-ups
- **Emergency Check-ins**: Image upload with base64 conversion
- **Recommendations History**: Chronological view of past advice
- **Genetic Profiling**: Upload and analysis of genetic reports

### Key Dependencies

- **FastAPI** - Web framework
- **Google Cloud Firestore** - Database
- **Google ADK/GenAI** - AI agent framework
- **JWT/Passlib** - Authentication
- **Pydantic** - Data validation

### Environment Configuration

Requires:
- `servicekey.json` - Google Cloud service account credentials
- Environment variables for JWT and Google APIs
- Properly configured Google Cloud project with Firestore enabled