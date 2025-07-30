# Deployment Guide

This document provides instructions for deploying the Child Genetic Profiling API to Google Cloud Run.

## Prerequisites

1. **Google Cloud SDK installed and authenticated**
   ```bash
   gcloud auth login
   gcloud config set project arboreal-totem-455008-d4
   ```

2. **Required files in the backend directory:**
   - `Dockerfile` - Container configuration
   - `requirements.txt` - Python dependencies
   - `servicekey.json` - Google Cloud service account credentials (local only)
   - `.env` - Environment variables (local only)

## Environment Variables

The following environment variables are required for Cloud Run deployment:

### Required Variables:
- `JWT_SECRET_KEY` - Secret key for JWT token generation
- `API_KEY` - API key for authentication middleware
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
gcloud run deploy child-profiling-api \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "JWT_SECRET_KEY=my-very-secret-key,API_KEY=secure-api-key-2025,GOOGLE_CLOUD_PROJECT=arboreal-totem-455008-d4,GOOGLE_CLOUD_LOCATION=us-central1,GOOGLE_GENAI_USE_VERTEXAI=true" \
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

- **FastAPI backend** with JWT authentication
- **Dr. Bloom chatbot** integration using Google ADK
- **Firestore database** for data persistence
- **Google Vertex AI** for LLM capabilities
- **API key middleware** for request authentication

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