# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Running the Application
```bash
# Start the FastAPI server
python main.py
# Or with uvicorn directly
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Environment Setup
```bash
# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Testing
```bash
# Run test script
python test.py
```

## Architecture Overview

This is a FastAPI-based backend for a child genetic profiling system that analyzes genetic data and provides personalized recommendations.

### Core Components

1. **main.py** - FastAPI application with endpoints for:
   - User authentication (register/login with JWT)
   - Child profile management
   - Genetic report upload and processing
   - Check-in questions and responses
   - Profile retrieval

2. **childprofile.py** - Core data model and Firestore integration:
   - `ChildProfile` class manages child data in Firestore
   - Handles trait matching against genetic markers
   - Manages logs and recommendations
   - Integrates with Google Firestore for persistence

3. **planner_agent/agent.py** - AI agent system using Google ADK:
   - `LogGenerationService` generates personalized recommendations
   - Creates follow-up questions based on traits
   - Manages session-based interactions
   - Uses Pydantic models for data validation

### Key Dependencies

- **FastAPI** - Web framework
- **Google Cloud Firestore** - Database
- **Google ADK/GenAI** - AI agent framework
- **JWT/Passlib** - Authentication
- **Pydantic** - Data validation

### Data Flow

1. User uploads genetic report JSON → Creates ChildProfile
2. System matches genetic markers to traits in Firestore
3. AI agent generates initial recommendations and questions
4. User submits check-in answers → Agent generates follow-up content
5. All data persisted in Firestore collections: `profiles`, `users`, `user_children`, `trait_references`

### Environment Configuration

Requires:
- `servicekey.json` - Google Cloud service account credentials
- JWT_SECRET_KEY environment variable for authentication
- Properly configured Google Cloud project with Firestore enabled