#!/bin/bash

# Bloomie Infrastructure Setup Script
# This script sets up the complete infrastructure for the Bloomie application
# including Firestore database and Cloud Run deployment

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Bloomie Infrastructure Setup Script  ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Function to read environment variables
read_env_var() {
    local var_name=$1
    local prompt=$2
    local default=$3
    local current_value=""
    
    # Try to read from .env file if it exists
    if [ -f "backend/.env" ]; then
        current_value=$(grep "^${var_name}=" backend/.env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
    fi
    
    if [ -n "$current_value" ]; then
        echo -e "${YELLOW}Current ${var_name}: ${current_value}${NC}"
        read -p "Keep this value? (Y/n): " keep_value
        if [[ $keep_value =~ ^[Nn]$ ]]; then
            current_value=""
        else
            echo "$current_value"
            return
        fi
    fi
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        value=${value:-$default}
    else
        read -p "$prompt: " value
        while [ -z "$value" ]; do
            echo -e "${RED}This field is required${NC}"
            read -p "$prompt: " value
        done
    fi
    echo "$value"
}

# Step 1: Collect configuration
echo -e "${YELLOW}Step 1: Configuration${NC}"
echo "Please provide the following information:"
echo ""

PROJECT_ID=$(read_env_var "GOOGLE_CLOUD_PROJECT" "Enter your Google Cloud Project ID" "")
REGION=$(read_env_var "GOOGLE_CLOUD_LOCATION" "Enter your preferred region" "us-central1")
SERVICE_NAME=$(read_env_var "SERVICE_NAME" "Enter Cloud Run service name" "child-profiling-api")
COLLECTION_PREFIX=$(read_env_var "FIRESTORE_COLLECTION_PREFIX" "Enter Firestore collection prefix (or leave empty)" "")
JWT_SECRET=$(read_env_var "JWT_SECRET_KEY" "Enter JWT secret key (or press enter to generate)" "")
API_KEY=$(read_env_var "API_KEY" "Enter API key for service access" "secure-api-key-2025")

# Generate JWT secret if not provided
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -hex 32)
    echo -e "${GREEN}Generated JWT secret: ${JWT_SECRET}${NC}"
fi

# Step 2: Set the project
echo ""
echo -e "${YELLOW}Step 2: Setting up Google Cloud Project${NC}"
gcloud config set project $PROJECT_ID

# Step 3: Enable required APIs
echo ""
echo -e "${YELLOW}Step 3: Enabling required Google Cloud APIs${NC}"
apis=(
    "firestore.googleapis.com"
    "run.googleapis.com"
    "cloudbuild.googleapis.com"
    "artifactregistry.googleapis.com"
    "aiplatform.googleapis.com"
)

for api in "${apis[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api --quiet
done

# Step 4: Create Firestore database
echo ""
echo -e "${YELLOW}Step 4: Setting up Firestore${NC}"
echo "Checking if Firestore database exists..."

# Check if Firestore is already created
if gcloud firestore databases list --format="value(name)" 2>/dev/null | grep -q "(default)"; then
    echo -e "${GREEN}Firestore database already exists${NC}"
else
    echo "Creating Firestore database in Native mode..."
    gcloud firestore databases create \
        --location=$REGION \
        --type=firestore-native \
        --quiet
fi

# Step 5: Create service account for Cloud Run
echo ""
echo -e "${YELLOW}Step 5: Setting up Service Account${NC}"
SERVICE_ACCOUNT="${SERVICE_NAME}-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL &>/dev/null; then
    echo -e "${GREEN}Service account already exists${NC}"
else
    echo "Creating service account..."
    gcloud iam service-accounts create $SERVICE_ACCOUNT \
        --display-name="Cloud Run Service Account for ${SERVICE_NAME}"
fi

# Grant necessary permissions
echo "Granting permissions to service account..."
roles=(
    "roles/datastore.user"
    "roles/aiplatform.user"
    "roles/logging.logWriter"
)

for role in "${roles[@]}"; do
    echo "Granting $role..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
        --role="$role" \
        --quiet &>/dev/null
done

# Step 6: Create .env file for backend
echo ""
echo -e "${YELLOW}Step 6: Creating backend .env file${NC}"
cat > backend/.env << EOF
# Google Cloud Configuration
GOOGLE_CLOUD_PROJECT=${PROJECT_ID}
GOOGLE_CLOUD_LOCATION=${REGION}
GOOGLE_GENAI_USE_VERTEXAI=true

# Firestore Configuration
FIRESTORE_COLLECTION_PREFIX=${COLLECTION_PREFIX}

# Authentication
JWT_SECRET_KEY=${JWT_SECRET}
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API Security
API_KEY=${API_KEY}

# Service Configuration
SERVICE_NAME=${SERVICE_NAME}
SERVICE_ACCOUNT_EMAIL=${SERVICE_ACCOUNT_EMAIL}
EOF

echo -e "${GREEN}.env file created at backend/.env${NC}"

# Step 7: Initialize Firestore with reference data
echo ""
echo -e "${YELLOW}Step 7: Initializing Firestore with reference data${NC}"
echo "This will upload the CSV reference data to Firestore..."

cd backend
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
else
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
fi

echo "Installing dependencies..."
pip install -q -r requirements.txt

echo "Uploading reference data to Firestore..."
python scripts/upload_reference_data.py
python scripts/update_immunity_suggestions.py

cd ..

# Step 8: Create Dockerfile for Cloud Run
echo ""
echo -e "${YELLOW}Step 8: Creating Dockerfile${NC}"
cat > backend/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Run the application
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT}
EOF

echo -e "${GREEN}Dockerfile created${NC}"

# Step 9: Create .gcloudignore
echo ""
echo -e "${YELLOW}Step 9: Creating .gcloudignore${NC}"
cat > backend/.gcloudignore << 'EOF'
.gcloudignore
.git
.gitignore
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
venv/
.env
.venv
env/
ENV/
.pytest_cache/
.coverage
htmlcov/
.DS_Store
*.log
servicekey.json
scripts/test_*.py
test_*.py
README.md
*.md
EOF

echo -e "${GREEN}.gcloudignore created${NC}"

# Step 10: Deploy to Cloud Run
echo ""
echo -e "${YELLOW}Step 10: Deploying to Cloud Run${NC}"
read -p "Do you want to deploy to Cloud Run now? (y/N): " deploy_now

if [[ $deploy_now =~ ^[Yy]$ ]]; then
    cd backend
    
    echo "Building and deploying to Cloud Run..."
    gcloud run deploy $SERVICE_NAME \
        --source . \
        --region $REGION \
        --platform managed \
        --service-account $SERVICE_ACCOUNT_EMAIL \
        --allow-unauthenticated \
        --set-env-vars "GOOGLE_CLOUD_PROJECT=${PROJECT_ID},GOOGLE_CLOUD_LOCATION=${REGION},GOOGLE_GENAI_USE_VERTEXAI=true,FIRESTORE_COLLECTION_PREFIX=${COLLECTION_PREFIX},JWT_SECRET_KEY=${JWT_SECRET},API_KEY=${API_KEY}" \
        --memory 1Gi \
        --cpu 1 \
        --timeout 60 \
        --min-instances 0 \
        --max-instances 10
    
    # Get the service URL
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format='value(status.url)')
    
    cd ..
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Deployment Complete!                 ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}Cloud Run Service URL: ${SERVICE_URL}${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Update bloomie_frontend/lib/services/api_service.dart with your Cloud Run URL"
    echo "2. Test the API: curl ${SERVICE_URL}/health"
    echo ""
else
    echo ""
    echo -e "${YELLOW}To deploy later, run:${NC}"
    echo "cd backend"
    echo "gcloud run deploy $SERVICE_NAME \\"
    echo "    --source . \\"
    echo "    --region $REGION \\"
    echo "    --platform managed \\"
    echo "    --service-account $SERVICE_ACCOUNT_EMAIL \\"
    echo "    --allow-unauthenticated \\"
    echo "    --set-env-vars \"GOOGLE_CLOUD_PROJECT=${PROJECT_ID},GOOGLE_CLOUD_LOCATION=${REGION},GOOGLE_GENAI_USE_VERTEXAI=true,FIRESTORE_COLLECTION_PREFIX=${COLLECTION_PREFIX},JWT_SECRET_KEY=${JWT_SECRET},API_KEY=${API_KEY}\" \\"
    echo "    --memory 1Gi"
fi

echo ""
echo -e "${GREEN}Configuration saved in backend/.env${NC}"
echo -e "${YELLOW}Keep this file secure and do not commit it to version control!${NC}"