# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Running the Application
```bash
# Start the FastAPI server locally
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Environment Setup
```bash
# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Deployment
```bash
# Deploy veetwo branch to Google Cloud Run
./deploy-veetwo.sh

# Manual deployment with environment variables
gcloud run deploy child-profiling-api-veetwo \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "JWT_SECRET_KEY=veetwo-secret-key-2025,API_KEY=veetwo-api-key-2025,GOOGLE_CLOUD_PROJECT=arboreal-totem-455008-d4,GOOGLE_CLOUD_LOCATION=us-central1,GOOGLE_GENAI_USE_VERTEXAI=true,FIRESTORE_COLLECTION_PREFIX=veetwo_" \
  --memory 1Gi
```

## System Overview

This is a **Child Genetic Profiling System** that provides personalized developmental recommendations and medical consultation features based on genetic analysis. The system uses FastAPI backend with a single-page frontend and integrates with Google Cloud services.

### Core Purpose
- **Genetic Analysis**: Upload genetic reports to create child profiles
- **Weekly Check-ins**: Track development with personalized recommendations (Cognitive & Behavioral archetype)
- **Medical Consultation**: Dr. Bloom AI for medical concerns and doctor visit logs (Immunity & Resilience archetype)
- **Immunity Tracking**: Specialized immunity & resilience monitoring and medical logs
- **Growth Milestones**: Age-based nutritional and developmental roadmap (Growth & Development archetype)

## Architecture

### Backend Structure
```
app/
├── api/              # FastAPI route handlers
│   ├── auth.py       # User authentication (login/register)
│   ├── children.py   # Child management & check-ins
│   ├── chatbot.py    # Dr. Bloom conversation system
│   ├── immunity.py   # Immunity dashboard & suggestions
│   ├── growth_milestones.py # Growth & development roadmap
│   └── medical_logs.py # Medical visit logs
├── core/             # Core configuration
│   ├── config.py     # Environment & settings
│   ├── security.py   # JWT authentication
│   ├── database.py   # Firestore client
│   └── utils.py      # Utility functions
├── services/         # Business logic layer
│   ├── auth_service.py
│   ├── child_service.py
│   ├── chatbot_service.py
│   ├── immunity_service.py
│   └── genetic_report_parser.py
├── repositories/     # Data access layer
│   ├── base_repository.py      # Collection prefix handling
│   ├── user_repository.py
│   ├── child_repository.py
│   ├── trait_repository.py
│   ├── chatbot_repository.py
│   ├── immunity_suggestion_repository.py
│   └── medical_log_repository.py
├── agents/           # AI agents using Google ADK
│   ├── planner_agent/          # Weekly check-in recommendations
│   ├── chatbot_agent/          # Dr. Bloom conversation
│   └── medical_visit_agent.py  # Medical log generation
├── models/           # Data models
├── schemas/          # Pydantic request/response schemas
└── middleware/       # API key authentication
```

### Database Collections (Firestore)
All collections use `veetwo_` prefix for multi-tenancy:

- **`veetwo_users`** - User accounts
- **`veetwo_children`** - Child profiles and genetic data
- **`veetwo_logs`** - Weekly check-in logs (entry_type: "initial", "checkin")
- **`veetwo_conversations`** - Dr. Bloom chat sessions
- **`veetwo_medical_visit_logs`** - Medical consultation logs for doctor visits
- **`veetwo_trait_references`** - Genetic trait database
- **`veetwo_immunity_suggestions`** - Immunity & resilience recommendations
- **`veetwo_growth_milestones`** - Age-based nutritional and developmental milestones

## User Flows (Frontend)

### 1. Authentication Flow
```
Login Screen → Dashboard
     ↓
Register Screen → Dashboard
```
**Key Functions**: `login()`, `register()`, `showLogin()`, `showRegister()`

### 2. Child Management Flow
```
Dashboard → Add Child → Upload Genetic Report → Initial Check-in → Dashboard
     ↓
Child Cards displayed with action buttons
```
**Key Functions**: `showAddChild()`, `uploadGeneticReport()`, `handleFileSelect()`

### 3. Weekly Check-in Flow
```
Dashboard → Click "Weekly Check-in" → Questions Screen → Submit Answers → Results Screen
     ↓                                      ↓                    ↓
Get Questions (/children/{id}/check-in) → Answer Questions → Submit (/children/{id}/check-in)
```
**Key Functions**: `startCheckIn()`, `submitCheckIn()`, `showQuestion()`, `nextQuestion()`
**Entry Types**: "initial" (first), "checkin" (subsequent)

### 4. Dr. Bloom Medical Consultation Flow
```
Dashboard → "Consult Dr. Bloom" → Setup Screen → Chat Interface → Complete → Medical Summary
     ↓                               ↓              ↓             ↓
Start Session → Send Initial Concern → Chat Back/Forth → Generate Medical Logs
```
**Key Functions**: `openDrBloomConsultation()`, `startDrBloomChat()`, `sendChatMessage()`, `completeDrBloomSession()`
**Purpose**: Medical consultations only, creates logs for doctor visits

### 5. Immunity Dashboard Flow
```
Dashboard → "Immunity & Resilience" → Immunity Dashboard
     ↓                                        ↓
Load Child Immunity Data → Display Suggestions + Medical Logs
```
**Key Functions**: `viewImmunityDashboard()`, `displayImmunityDashboard()`
**Shows**: Genetic-based suggestions + medical visit logs

### 6. Growth Milestones Roadmap Flow
```
Dashboard → "Growth & Development" → Growth Roadmap → Overview/Current/Full Roadmap
     ↓                                     ↓              ↓
Load Growth Genes → Calculate Age-based Milestones → Display Timeline with Food Recommendations
```
**Key Functions**: `viewGrowthMilestones()`, `showGrowthTab()`, `displayGrowthContent()`
**Views**: Overview stats, Current age focus, Complete timeline roadmap
**Shows**: Age-based nutritional guidance and developmental milestones

### 7. History & Data Views
```
Dashboard → "View History" → Recommendations History
     ↓
Dashboard → "View Traits" → Child's Genetic Traits
```
**Key Functions**: `viewRecommendations()`, `viewTraits()`

## Key API Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration

### Child Management
- `GET /children` - List user's children
- `POST /children/upload-genetic-report` - Upload genetic report + create child
- `GET /children/{id}/check-in` - Get weekly check-in questions
- `POST /children/{id}/check-in` - Submit check-in answers
- `GET /children/{id}/recommendations-history` - Get recommendation history
- `GET /children/{id}/traits` - Get child's genetic traits

### Dr. Bloom Medical Consultation
- `POST /children/{id}/dr-bloom/start` - Start medical consultation
- `POST /chatbot/conversations/{session_id}/messages` - Send chat message
- `POST /children/{id}/dr-bloom/complete` - Complete consultation & generate medical logs

### Immunity & Resilience
- `GET /immunity/{id}/dashboard` - Get immunity dashboard data
- `GET /immunity/{id}/suggestions` - Get personalized immunity suggestions
- `GET /immunity/{id}/traits` - Get immunity-related genetic traits

### Growth & Development Milestones
- `GET /growth-milestones/{id}/overview` - Get milestone overview and progress summary
- `GET /growth-milestones/{id}/current` - Get current age-specific milestones
- `GET /growth-milestones/{id}/roadmap` - Get complete growth milestone roadmap

### Medical Logs
- `GET /medical-logs/{id}` - Get medical visit logs
- `GET /medical-logs/{id}/log/{log_id}` - Get specific medical log
- `GET /medical-logs/{id}/by-trait/{trait}` - Get logs by immunity trait

## Data Flow Architecture

### 1. Weekly Check-in System
```
Genetic Report → Initial Log → Weekly Questions → Answered → New Recommendations → Saved to veetwo_logs
     ↓              ↓             ↓               ↓              ↓
Parse Traits → Match to DB → Generate Questions → Process Answers → AI Agent Creates Entry
```
**Entry Types**: "initial", "checkin"
**Agent**: `planner_agent` - Creates developmental recommendations

### 2. Medical Consultation System
```
Dr. Bloom Chat → Medical Discussion → Regex Detection → Medical Agent → Doctor Visit Log
     ↓                ↓                    ↓              ↓             ↓
Chat Interface → Text Analysis → Find Medical Topics → Generate Structure → Save to medical_visit_logs
```
**Purpose**: Create structured logs for actual doctor visits
**Agent**: `medical_visit_agent` - Creates medical documentation

### 3. Immunity System
```
Genetic Traits → Filter Immunity → Match Suggestions → Display Dashboard
     ↓              ↓                  ↓                ↓
Child Profile → Archetype Filter → Database Lookup → UI Presentation + Medical Logs
```
**Data Sources**: Genetic traits + immunity suggestions CSV + medical logs

## Key Features

### 1. Multi-Tenancy
- All Firestore collections use `veetwo_` prefix
- Environment variable: `FIRESTORE_COLLECTION_PREFIX=veetwo_`
- Allows multiple deployments without data conflicts

### 2. AI Agent System
- **Planner Agent**: Weekly developmental recommendations
- **Dr. Bloom Agent**: Medical consultation chat
- **Medical Visit Agent**: Structured medical logs
- Uses Google ADK (Agent Development Kit)

### 3. Genetic Profiling
- Upload JSON/PDF genetic reports
- Parse and match traits to recommendation database
- Filter by archetype (Cognitive & Behavioral, Immunity & Resilience)

### 4. Dual-Purpose Logging
- **Weekly Logs** (`veetwo_logs`): Development tracking
- **Medical Logs** (`veetwo_medical_visit_logs`): Doctor visit preparation

### 5. Image Support
- Dr. Bloom accepts images for medical consultation
- Base64 encoding for API transport
- Supports symptoms, rashes, injuries

## Environment Configuration

### Local Development (.env)
```bash
FIRESTORE_COLLECTION_PREFIX=veetwo_
JWT_SECRET_KEY=my-very-secret-key
API_KEY=secure-api-key-2025
GOOGLE_CLOUD_PROJECT=arboreal-totem-455008-d4
GOOGLE_CLOUD_LOCATION=us-central1
GOOGLE_GENAI_USE_VERTEXAI=true
GOOGLE_APPLICATION_CREDENTIALS=servicekey.json
```

### Production (Cloud Run)
- **Service URL**: https://child-profiling-api-veetwo-[hash].us-central1.run.app
- **API Key**: veetwo-api-key-2025 (required in X-API-Key header)
- **Collections**: All prefixed with `veetwo_`

## Security & Authentication

### API Security
- **API Key Middleware**: All endpoints (except /health) require X-API-Key header
- **JWT Authentication**: User sessions with bearer tokens
- **CORS**: Configured for cross-origin requests

### Data Privacy
- Dr. Bloom conversations deleted after medical log generation
- Medical logs stored separately for doctor visits
- User data isolated by JWT authentication

## Dependencies

### Core
- **FastAPI** - Web framework
- **Google Cloud Firestore** - Database
- **Google ADK/GenAI** - AI agent framework
- **JWT/Passlib** - Authentication
- **Pydantic** - Data validation

### AI & Processing
- **Google Gemini** - LLM for AI agents
- **Pandas** - Data processing
- **Regex** - Medical topic detection

## Development Notes

### Important Patterns
1. **Repository Pattern**: All database access through repositories with base class
2. **Service Layer**: Business logic separated from API handlers
3. **Agent System**: AI functionality isolated in agent classes
4. **Collection Prefixing**: Multi-tenancy through collection naming

### Key Design Decisions
1. **Separation of Concerns**: Weekly check-ins vs. medical consultations
2. **Medical Focus**: Dr. Bloom only creates medical logs, not development logs
3. **Trait Filtering**: Different archetypes for different features
4. **Firestore Structure**: Separate collections for different log types

### Error Handling
- Comprehensive logging throughout the system
- Graceful fallbacks for AI agent failures
- User-friendly error messages in frontend

## Frontend UI/UX Design Notes

### Growth & Development Roadmap (Future Implementation)
The roadmap should be displayed as an interactive winding path/road with:

- **Child Avatar**: Always anchored at the "current month" on the path
  - Animates forward as months pass (or on scroll)
  
- **Milestone Stops**: Cards pop up from the road at each checkpoint
  - Each checkpoint represents the current age range blocks (0-1, 1-3, 3-5, etc.)
  - Cards display:
    - Age range (e.g., "Ages 1-3")
    - Status (Completed/Current/Upcoming)
    - List of trait-based recommendations containing:
      - Trait name & gene ID
      - Focus description
      - Food examples as pills/tags
  
- **Visual Design**: Winding road/path metaphor with milestones as stops along the journey

### Immunity & Resilience Dashboard (Future Implementation)
The dashboard should have two main widgets:

**Widget 1 - Trait Recommendations (Top)**:
- Contains sub-widgets for each immunity trait
- Each trait widget displays:
  - Trait name as header
  - Two sections: "Provide" (✅) and "Avoid" (❌)
  - List items under each section
  - Expandable dropdown button to view rationale/explanation
  - Clean card-based design with clear visual separation

**Widget 2 - Medical Visit Logs (Bottom)**:
- Displays chronological medical consultation logs
- Shows recent Dr. Bloom consultations
- Each log entry includes:
  - Date and primary concerns
  - Emergency indicators (if any)
  - Questions for doctor
  - Traits discussed

### Latest Recommendations Widget System (Completed)
A new backend feature and frontend widget system has been implemented for quick overview of latest recommendations:

**Backend Endpoints:**
- `GET /children/{child_id}/latest-recommendations` - Concise overview with tldr summaries
- `GET /children/{child_id}/latest-recommendations-detail` - Full details of latest recommendations only

**Key Features:**
- Uses new `tldr` field in recommendations for 5-10 word summaries (e.g. "memory games and puzzles")
- Planner agent updated to generate tldr summaries in addition to full activity descriptions
- Frontend widget shows child name, last check-in date, and concise trait actions
- "View Details" button shows full descriptions without entire history
- Backwards compatible with existing logs (falls back to combined goal+activity)

**Frontend Implementation:**
- Dashboard widget with compact trait + action display
- Separate detail screen for latest recommendations only
- Clean separation from full history feature

### Mobile App Dashboard Design (In Progress)

**8 Core Features:**
1. **Overview widget** - Latest recommendations summary (✓ implemented)
2. **Weekly check-in button** - Start questionnaire (✓ implemented) 
3. **Growth & development roadmap** - Winding path UI planned (✓ backend ready)
4. **Immunity & resilience dashboard** - Trait widgets + medical logs (✓ implemented)
5. **Dr. Bloom consult** - AI medical consultation (✓ implemented)
6. **View genetic profile stats** - Trait overview (✓ implemented as "View Traits")
7. **Behavior & cognitive history** - Full recommendation history (✓ implemented)
8. **Switch between profiles** - Netflix-like selection (not in web version)

**Mobile Navigation Structure:**
- **Bottom nav bar** with 3 buttons:
  - Chatbot button
  - Home button (dashboard)  
  - Switch profiles button

**Critical Design Issue to Fix:**
ChatGPT's mockup merged the overview widget's "View Details" button with the "Weekly Check-in" feature. These should be separate:
- **Overview Widget**: Shows latest recommendations + "View Details" button → opens latest recommendation details
- **Weekly Check-in**: Separate prominent card/button → starts new questionnaire

**Next Steps:**
- Merge ChatGPT's mobile dashboard design with existing frontend.html code
- Implement card-based layout for the 8 core features
- Maintain separation between overview widget and weekly check-in functionality
- All backend endpoints already exist and working

## Code Cleanup (Completed)

**Dead Code Removed:**
- `scripts/cleanup_old_reference.py` - Old cleanup script for incorrect reference structure
- `scripts/cleanup_wrong_reference.py` - Wrong reference cleanup script
- `scripts/migrate_veetwo_to_main.py` - Outdated veetwo migration script
- `deploy-veetwo.sh` - Outdated deployment script for veetwo branch (replaced by stable backend)

**Essential Scripts Kept (CI/CD Pipeline):**
- `scripts/upload_reference_data.py` - Main script to upload CSV data to Firestore
- `scripts/migrate_to_bloomie.py` - Migration to new bloomie structure  
- `scripts/update_immunity_suggestions.py` - Update immunity suggestions in Firestore
- `scripts/generate_immunity_regex.py` - Generates regex patterns for immunity traits (moved from root)
- `database/` folder - All CSV reference data files

**App Structure:** All files in the `app/` directory are actively used and clean.

Note: Frontend will be migrated to Dart/Flutter later. Current implementation uses the existing structure.