#!/bin/bash
# AURA Social – Backend Deployment Script for Cloud Run
# High-resource Configuration (4 vCPU, 8 GiB RAM, Min Instances = 1, Max Instances = 5)
# Optimized to fit project quota limits (Max 20 vCPU / 40 GiB RAM per region)

# Set configuration variables
PROJECT_ID=$(gcloud config get-value project)
SERVICE_NAME="aura-api"
REGION="asia-southeast1"

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: No Google Cloud Project ID detected. Please run 'gcloud config set project [PROJECT_ID]' first."
  exit 1
fi

echo "🚀 Deploying AURA Social Backend to Cloud Run..."
echo "📦 Project ID: $PROJECT_ID"
echo "🔧 Service: $SERVICE_NAME"
echo "📍 Region: $REGION"
echo "🔥 Configuration: 4 vCPU, 8 GiB RAM, Min Instances: 1, Max Instances: 5"

# 1. Build and push image using Cloud Builds
echo "⚡ Building and pushing Docker image to Container Registry..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME:latest .

if [ $? -ne 0 ]; then
  echo "❌ Build failed. Exiting deployment."
  exit 1
fi

# 2. Deploy to Cloud Run with high-resource settings
echo "🌐 Deploying to Cloud Run with high-resource configurations..."
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --cpu=4 \
  --memory=8Gi \
  --min-instances=1 \
  --max-instances=5 \
  --concurrency=80 \
  --set-env-vars ENVIRONMENT=production

if [ $? -eq 0 ]; then
  echo "🎉 Deployment successful!"
else
  echo "❌ Cloud Run deployment failed."
  exit 1
fi
