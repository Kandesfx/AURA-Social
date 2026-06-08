# AURA Social – Backend Deployment Script for Cloud Run (PowerShell)
# High-resource Configuration (4 vCPU, 8 GiB RAM, Min Instances = 1, Max Instances = 5)
# Optimized to fit project quota limits (Max 20 vCPU / 40 GiB RAM per region)

$ProjectId = gcloud config get-value project 2>$null

if ([string]::IsNullOrEmpty($ProjectId) -or $ProjectId.Contains("(unset)")) {
    Write-Error "❌ Error: No Google Cloud Project ID detected. Please run 'gcloud config set project [PROJECT_ID]' first."
    Exit
}

$ServiceName = "aura-api"
$Region = "asia-southeast1"

Write-Host "🚀 Deploying AURA Social Backend to Cloud Run..." -ForegroundColor Cyan
Write-Host "📦 Project ID: $ProjectId"
Write-Host "🔧 Service: $ServiceName"
Write-Host "📍 Region: $Region"
Write-Host "🔥 Configuration: 4 vCPU, 8 GiB RAM, Min Instances: 1, Max Instances: 5" -ForegroundColor Yellow

# 1. Build and push image using Cloud Builds
Write-Host "⚡ Building and pushing Docker image to Container Registry..." -ForegroundColor Green
gcloud builds submit --tag gcr.io/${ProjectId}/${ServiceName}:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Build failed. Exiting deployment."
    Exit
}

# 2. Deploy to Cloud Run with high-resource settings
Write-Host "🌐 Deploying to Cloud Run with high-resource configurations..." -ForegroundColor Green
gcloud run deploy $ServiceName `
  --image gcr.io/${ProjectId}/${ServiceName}:latest `
  --region $Region `
  --platform managed `
  --allow-unauthenticated `
  --cpu=4 `
  --memory=8Gi `
  --min-instances=1 `
  --max-instances=5 `
  --concurrency=80 `
  --set-env-vars ENVIRONMENT=production

if ($LASTEXITCODE -eq 0) {
    Write-Host "🎉 Deployment successful!" -ForegroundColor Green
} else {
    Write-Error "❌ Cloud Run deployment failed."
}
