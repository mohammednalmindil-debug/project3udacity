# Coworking Analytics Deployment Script (PowerShell)
# This script automates the deployment process for the coworking analytics application

Write-Host "Starting Coworking Analytics Deployment..." -ForegroundColor Green

# Check if kubectl is available
try {
    kubectl version --client | Out-Null
    Write-Host "✓ kubectl is available" -ForegroundColor Green
} catch {
    Write-Host "Error: kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if connected to a Kubernetes cluster
try {
    kubectl cluster-info | Out-Null
    Write-Host "✓ Kubernetes cluster connection verified" -ForegroundColor Green
} catch {
    Write-Host "Error: Not connected to a Kubernetes cluster" -ForegroundColor Red
    exit 1
}

# Deploy PostgreSQL
Write-Host "Deploying PostgreSQL database..." -ForegroundColor Yellow
kubectl apply -f pvc.yaml
kubectl apply -f pv.yaml
kubectl apply -f postgresql-deployment.yaml
kubectl apply -f postgresql-service.yaml

Write-Host "Waiting for PostgreSQL pod to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=postgresql --timeout=300s

Write-Host "✓ PostgreSQL deployment completed" -ForegroundColor Green

# Deploy application configurations
Write-Host "Deploying application configurations..." -ForegroundColor Yellow
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

Write-Host "✓ Application configurations deployed" -ForegroundColor Green

# Deploy analytics application
Write-Host "Deploying analytics application..." -ForegroundColor Yellow
kubectl apply -f coworking-deployment.yaml

Write-Host "Waiting for analytics application to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l service=coworking --timeout=300s

Write-Host "✓ Analytics application deployment completed" -ForegroundColor Green

# Display service information
Write-Host ""
Write-Host "Deployment Summary:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Services:" -ForegroundColor White
kubectl get svc

Write-Host ""
Write-Host "Pods:" -ForegroundColor White
kubectl get pods

Write-Host ""
Write-Host "To access the application:" -ForegroundColor Cyan
Write-Host "1. Get the external IP: kubectl get svc coworking" -ForegroundColor White
Write-Host "2. Test health check: curl http://<EXTERNAL_IP>:5153/health_check" -ForegroundColor White
Write-Host "3. Test daily usage report: curl http://<EXTERNAL_IP>:5153/api/reports/daily_usage" -ForegroundColor White
Write-Host "4. Test user visits report: curl http://<EXTERNAL_IP>:5153/api/reports/user_visits" -ForegroundColor White

Write-Host ""
Write-Host "Deployment completed successfully!" -ForegroundColor Green
