# Deployment Guide

This document provides instructions for deploying the Child Genetic Profiling API to Google Cloud Run.

## Latest Codebase Features

This deployment includes the complete stable backend with:
- **8 Core Features**: Weekly check-ins, growth roadmap, immunity dashboard, Dr. Bloom consultation, etc.
- **Latest Recommendations Widget**: Quick overview with tldr summaries
- **Bloomie Database Structure**: Nested Firestore collections (`bloomie/reference/*`, `bloomie/data/*`)
- **Performance Optimizations**: Pre-computed data, optimized medical log queries
- **Clean Architecture**: Latest recommendations, medical logs, growth milestones

## Prerequisites

1. **Google Cloud SDK installed and authenticated**
   ```bash
   gcloud auth login
   gcloud config set project arboreal-totem-455008-d4
   ```

2. **Required files in the backend directory:**
   - `Dockerfile` - Container configuration
   - `requirements.txt` - Python dependencies (bcrypt==3.2.2 for passlib compatibility)
   - `servicekey.json` - Google Cloud service account credentials (local only)
   - `.env` - Environment variables (local only)

## Environment Variables

The following environment variables are required for Cloud Run deployment:

### Required Variables:
- `JWT_SECRET_KEY` - Secret key for JWT token generation (get from `.env` file)
- `API_KEY` - API key for authentication middleware (get from `.env` file)
- `GOOGLE_CLOUD_PROJECT` - Google Cloud project ID (`arboreal-totem-455008-d4`)
- `GOOGLE_CLOUD_LOCATION` - Google Cloud location (`us-central1`)
- `GOOGLE_GENAI_USE_VERTEXAI` - Set to `true` for Vertex AI integration

### NOT needed on Cloud Run:
- `GOOGLE_APPLICATION_CREDENTIALS` - Cloud Run uses default service account
- `GOOGLE_API_KEY` - Not needed when using Vertex AI

## Deployment Commands

### Deploy to Existing Service

```bash
# Navigate to backend directory
cd /Users/ray/Desktop/sds/backend

# Deploy to the existing child-profiling-api service
# Get JWT_SECRET_KEY and API_KEY values from the .env file first
gcloud run deploy child-profiling-api \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "JWT_SECRET_KEY=<value-from-.env>,API_KEY=<value-from-.env>,GOOGLE_CLOUD_PROJECT=arboreal-totem-455008-d4,GOOGLE_CLOUD_LOCATION=us-central1,GOOGLE_GENAI_USE_VERTEXAI=true" \
  --memory 1Gi
```

### Service Information

- **Service Name**: `child-profiling-api`
- **Region**: `us-central1`
- **URL**: `https://child-profiling-api-271271835247.us-central1.run.app`
- **Memory**: 1GB
- **Authentication**: Disabled (allow-unauthenticated)

## Deployment Process

1. **Build Phase**: Cloud Run builds the Docker container using the provided Dockerfile
2. **Deploy Phase**: The container is deployed to the Cloud Run service
3. **Update Phase**: Traffic is automatically routed to the new revision

## Verification

After deployment, verify the service is working:

```bash
# Check health endpoint
curl https://child-profiling-api-271271835247.us-central1.run.app/health

# Expected response: {"status":"healthy"}
```

## Frontend Configuration

Update the frontend to use the deployed API:

```javascript
// In frontend.html
const API_BASE = 'https://child-profiling-api-271271835247.us-central1.run.app';
```

## Monitoring and Logs

View deployment logs and service status:

```bash
# View service details
gcloud run services describe child-profiling-api --region us-central1

# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=child-profiling-api" --limit 50 --format="table(timestamp,textPayload)"

# List all services
gcloud run services list --region us-central1
```

## Troubleshooting

### Common Issues:

1. **Port 8000 in use locally**
   ```bash
   # Kill uvicorn processes
   pkill -f uvicorn
   
   # Find and kill processes using port 8000
   lsof -i :8000
   kill -9 <PID>
   ```

2. **Environment variables not set**
   - Ensure all required env vars are included in the deploy command
   - Check Cloud Run console for environment variable configuration

3. **Build failures**
   - Verify `requirements.txt` is up to date
   - Check that all imports are available in the codebase
   - Ensure no syntax errors in Python files

4. **Permission errors**
   - Verify service account has necessary permissions
   - Check that Firestore and Vertex AI APIs are enabled

## Architecture

The deployment includes:

- **FastAPI backend** with JWT authentication and API key middleware
- **8 Core Features**: Overview widget, weekly check-ins, growth roadmap, immunity dashboard, Dr. Bloom, genetic profile, history, profile switching
- **AI Agents**: Planner agent (recommendations), Dr. Bloom agent (medical consultation), Medical visit agent (structured logs)
- **Bloomie Database Structure**: `bloomie/reference/*` (static data), `bloomie/data/*` (user data)
- **Performance Features**: Pre-computed immunity and roadmap data, optimized medical log queries
- **Latest Recommendations System**: tldr summaries, quick overview widget, detailed view

### Key Endpoints:
- `/children/{id}/latest-recommendations` - Quick overview with tldr
- `/children/{id}/latest-recommendations-detail` - Full latest details only
- `/immunity/{id}/dashboard` - Pre-computed immunity data + fresh medical logs
- `/growth-milestones/{id}/roadmap` - Pre-computed growth roadmap
- `/children/{id}/dr-bloom/*` - Medical consultation system

## Security Notes

- Service uses Cloud Run's default service account
- JWT tokens are signed with the provided secret key
- API key authentication is enforced on all endpoints except `/health`
- Firestore access is controlled by IAM permissions

## Updates and Maintenance

To update the deployment:

1. Make changes to the codebase
2. Test locally with `uvicorn main:app --reload --host 0.0.0.0 --port 8000`
3. Run the deployment command above
4. Verify the health endpoint responds correctly

The deployment process is idempotent - running the same command multiple times will update the existing service.

## Database Migration Notes

If updating the database structure:

1. **Upload Reference Data**: Use `scripts/upload_reference_data.py` to upload CSV data to Firestore
2. **Migrate to Bloomie**: Use `scripts/migrate_to_bloomie.py` for structural changes
3. **Update Immunity Data**: Use `scripts/update_immunity_suggestions.py` for immunity suggestions
4. **Regenerate All**: Use `scripts/regenerate_all_from_genetics.py` for complete CI/CD pipeline (requires OpenAI API key)

## Performance Monitoring

The latest codebase includes performance timing:
- Check logs for `⏱️ GET /path - XXXms` entries to monitor API response times
- Medical log queries are optimized with proper indexing
- Pre-computed data reduces load times for immunity and roadmap features

## Code Quality

✅ **Clean Codebase**: Dead code removed, only essential migration scripts kept
✅ **Latest Features**: All 8 core features implemented and tested
✅ **Performance Optimized**: Pre-computed data, optimized queries
✅ **Production Ready**: Stable backend ready to replace previous API container