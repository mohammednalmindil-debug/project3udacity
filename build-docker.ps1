# Manual Docker Build Script for Coworking Analytics
# This script builds and pushes the Docker image to ECR

Write-Host "Starting Manual Docker Build Process..." -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if Docker is available
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is available" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not running" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Login to ECR
Write-Host ""
Write-Host "Logging in to Amazon ECR..." -ForegroundColor Yellow
$loginCommand = "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767398149973.dkr.ecr.us-east-1.amazonaws.com"
Invoke-Expression $loginCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Successfully logged in to ECR" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to login to ECR" -ForegroundColor Red
    exit 1
}

# Build the Docker image
Write-Host ""
Write-Host "Building Docker image..." -ForegroundColor Yellow
Set-Location analytics
docker build -t coworking-analytics .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Docker image built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to build Docker image" -ForegroundColor Red
    exit 1
}

# Tag images for ECR
Write-Host ""
Write-Host "Tagging images for ECR..." -ForegroundColor Yellow
docker tag coworking-analytics:latest 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest
docker tag coworking-analytics:latest 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:1.0.0

Write-Host "✓ Images tagged successfully" -ForegroundColor Green

# Push images to ECR
Write-Host ""
Write-Host "Pushing images to ECR..." -ForegroundColor Yellow
docker push 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest
docker push 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:1.0.0

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Images pushed successfully to ECR" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to push images to ECR" -ForegroundColor Red
    exit 1
}

# Verify images in ECR
Write-Host ""
Write-Host "Verifying images in ECR..." -ForegroundColor Yellow
aws ecr list-images --repository-name coworking-analytics --region us-east-1

Write-Host ""
Write-Host "Docker build and push completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Set up a Kubernetes cluster (EKS recommended)" -ForegroundColor White
Write-Host "2. Deploy PostgreSQL: kubectl apply -f pvc.yaml pv.yaml postgresql-deployment.yaml postgresql-service.yaml" -ForegroundColor White
Write-Host "3. Deploy application: kubectl apply -f configmap.yaml secret.yaml coworking-deployment.yaml" -ForegroundColor White
Write-Host "4. Test endpoints and take screenshots for submission" -ForegroundColor White

Set-Location ..


