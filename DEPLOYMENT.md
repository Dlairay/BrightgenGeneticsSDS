# Bloomie Application Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Bloomie child genetic profiling application, including setting up Google Cloud infrastructure, Firestore database, and Cloud Run deployment.

## Prerequisites

### Required Tools
- **Google Cloud SDK (gcloud)**: [Install Guide](https://cloud.google.com/sdk/docs/install)
- **Python 3.11+**: For running backend scripts
- **Flutter SDK**: For building the mobile app ([Install Guide](https://flutter.dev/docs/get-started/install))
- **Git**: For version control

### Google Cloud Requirements
- A Google Cloud Project with billing enabled
- Owner or Editor role on the project
- APIs that will be enabled by the setup script:
  - Firestore API
  - Cloud Run API
  - Cloud Build API
  - Artifact Registry API
  - Vertex AI API

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd <repository-directory>
git checkout submission  # Use the submission branch with merged code
```

### 2. Run the Automated Setup Script
```bash
chmod +x setup_infrastructure.sh
./setup_infrastructure.sh
```

The script will:
1. Configure your Google Cloud project
2. Enable required APIs
3. Create Firestore database
4. Set up service accounts with proper permissions
5. Initialize Firestore with reference data
6. Deploy the backend to Cloud Run
7. Generate all necessary configuration files

### 3. Configure Frontend
After running the setup script, update the Flutter frontend to use your Cloud Run URL:

```dart
// In bloomie_frontend/lib/services/api_service.dart
static const bool useLocalhost = false;  // Set to false for production
static const String cloudRunUrl = 'YOUR_CLOUD_RUN_URL';  // Update with your URL from setup script
```

## Manual Setup (Alternative)

If you prefer to set up manually or need to customize the deployment:

### Step 1: Set Up Google Cloud Project
```bash
# Set your project ID
export PROJECT_ID="your-project-id"
export REGION="us-central1"

# Configure gcloud
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable firestore.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable aiplatform.googleapis.com
```

### Step 2: Create Firestore Database
```bash
# Create Firestore in Native mode
gcloud firestore databases create \
    --location=$REGION \
    --type=firestore-native
```

### Step 3: Create Service Account
```bash
# Create service account
gcloud iam service-accounts create bloomie-sa \
    --display-name="Bloomie Cloud Run Service Account"

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:bloomie-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/datastore.user"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:bloomie-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"
```

### Step 4: Configure Backend Environment
Create `backend/.env` file:
```env
# Google Cloud Configuration
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1
GOOGLE_GENAI_USE_VERTEXAI=true

# Firestore Configuration (optional prefix)
FIRESTORE_COLLECTION_PREFIX=

# Authentication
JWT_SECRET_KEY=your-secret-key-here  # Generate with: openssl rand -hex 32
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API Security
API_KEY=secure-api-key-2025

# Service Configuration
SERVICE_NAME=child-profiling-api
```

### Step 5: Initialize Firestore Data
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Upload reference data
python scripts/upload_reference_data.py
python scripts/update_immunity_suggestions.py
```

### Step 6: Deploy to Cloud Run
```bash
cd backend

# Deploy with all environment variables
gcloud run deploy child-profiling-api \
    --source . \
    --region us-central1 \
    --platform managed \
    --allow-unauthenticated \
    --service-account bloomie-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --set-env-vars "GOOGLE_CLOUD_PROJECT=${PROJECT_ID},GOOGLE_CLOUD_LOCATION=us-central1,GOOGLE_GENAI_USE_VERTEXAI=true,FIRESTORE_COLLECTION_PREFIX=veetwo_,JWT_SECRET_KEY=your-secret-key,API_KEY=secure-api-key-2025" \
    --memory 1Gi \
    --cpu 1 \
    --timeout 60 \
    --min-instances 0 \
    --max-instances 10
```

## Environment Variables Explained

### Backend (.env file)

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_CLOUD_PROJECT` | Your GCP project ID | `my-project-123` |
| `GOOGLE_CLOUD_LOCATION` | GCP region for services | `us-central1` |
| `GOOGLE_GENAI_USE_VERTEXAI` | Use Vertex AI for LLM | `true` |
| `FIRESTORE_COLLECTION_PREFIX` | Optional prefix for Firestore collections | `` (empty) |
| `JWT_SECRET_KEY` | Secret for JWT tokens | Generate with `openssl rand -hex 32` |
| `API_KEY` | API key for service access | `secure-api-key-2025` |

### Frontend Configuration

In `bloomie_frontend/lib/services/api_service.dart`:

```dart
// Toggle between local and production
static const bool useLocalhost = false;  // false for production
static const String cloudRunUrl = 'https://your-service-url.run.app';
static const String localUrl = 'http://localhost:8000';
```

## Local Development

### Running Backend Locally
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Running Frontend Locally
```bash
cd bloomie_frontend

# Ensure useLocalhost = true in api_service.dart
flutter clean
flutter pub get
flutter run
```

## Testing the Deployment

### 1. Test Backend Health
```bash
# Replace with your Cloud Run URL
curl https://your-service-url.run.app/health
```

### 2. Test API Authentication
```bash
curl -H "X-API-Key: secure-api-key-2025" \
     https://your-service-url.run.app/auth/test
```

### 3. Test Frontend Connection
1. Update `api_service.dart` with your Cloud Run URL
2. Set `useLocalhost = false`
3. Run the Flutter app
4. Try logging in or registering

## Firestore Collections Structure

The application uses the following Firestore collections:

- `users` - User accounts
- `children` - Child profiles and genetic data
- `logs` - Weekly check-in logs
- `conversations` - Dr. Bloom chat sessions
- `medical_visit_logs` - Medical consultation logs
- `trait_references` - Genetic trait database
- `immunity_suggestions` - Immunity recommendations
- `growth_milestones` - Growth and development milestones

## Troubleshooting

### Common Issues

#### 1. Firestore Permission Denied
- Ensure service account has `roles/datastore.user` role
- Check that `GOOGLE_CLOUD_PROJECT` is correct

#### 2. Cloud Run Deployment Fails
- Verify billing is enabled on your project
- Check that all APIs are enabled
- Ensure Dockerfile is present in backend directory

#### 3. Frontend Can't Connect to Backend
- Verify `useLocalhost` flag is set correctly
- Check that API_KEY matches between frontend and backend
- Ensure Cloud Run service allows unauthenticated access

#### 4. Vertex AI Errors
- Ensure Vertex AI API is enabled
- Check that service account has `roles/aiplatform.user` role
- Verify region supports Vertex AI

### Checking Logs
```bash
# View Cloud Run logs
gcloud run services logs read child-profiling-api --region us-central1

# Stream logs
gcloud run services logs tail child-profiling-api --region us-central1
```

## Security Considerations

1. **Never commit `.env` files** to version control
2. **Rotate JWT secrets** regularly
3. **Use strong API keys** and rotate them periodically
4. **Enable Cloud Run authentication** for production
5. **Set up Cloud Armor** for DDoS protection
6. **Enable VPC Service Controls** for additional security

## Updating the Deployment

### Update Backend Code
```bash
cd backend
gcloud run deploy child-profiling-api --source .
```

### Update Environment Variables
```bash
gcloud run services update child-profiling-api \
    --update-env-vars KEY=value
```

### Update Frontend
1. Make changes to Flutter code
2. Update version in `pubspec.yaml`
3. Build and deploy:
```bash
flutter build web  # For web deployment
flutter build apk  # For Android
flutter build ios  # For iOS
```

## Monitoring and Maintenance

### View Metrics
```bash
# View Cloud Run metrics
gcloud run services describe child-profiling-api --region us-central1

# View Firestore usage
gcloud firestore operations list
```

### Backup Firestore
```bash
gcloud firestore export gs://your-backup-bucket/backup-$(date +%Y%m%d)
```

### Cost Optimization
- Set `--min-instances 0` to scale to zero when not in use
- Use `--max-instances` to limit scaling
- Monitor usage in Google Cloud Console

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Cloud Run logs
3. Verify all environment variables are set correctly
4. Ensure all Google Cloud APIs are enabled

## Next Steps

After successful deployment:
1. Set up monitoring and alerting
2. Configure custom domain (optional)
3. Set up CI/CD pipeline
4. Implement backup strategy
5. Configure SSL certificates (handled automatically by Cloud Run)