# PowerShell script to deploy enhanced Flask application to Kubernetes
# This script will deploy the application with periodic database logging

param(
    [Parameter(Mandatory=$false)]
    [string]$ClusterType = "local",  # "local" or "eks"
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = ""
)

Write-Host "Deploying Enhanced Flask Application with Periodic Database Logging" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green

# Function to check if kubectl is available
function Test-Kubectl {
    try {
        kubectl version --client --short
        return $true
    }
    catch {
        Write-Host "kubectl not found. Please install kubectl first." -ForegroundColor Red
        return $false
    }
}

# Function to check cluster connection
function Test-ClusterConnection {
    try {
        $nodes = kubectl get nodes --no-headers
        if ($nodes) {
            Write-Host "✓ Cluster connection successful" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "✗ No nodes found in cluster" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Cannot connect to cluster" -ForegroundColor Red
        return $false
    }
}

# Function to wait for pods to be ready
function Wait-ForPods {
    param(
        [string]$LabelSelector,
        [int]$TimeoutSeconds = 300
    )
    
    Write-Host "Waiting for pods with label '$LabelSelector' to be ready..." -ForegroundColor Yellow
    try {
        kubectl wait --for=condition=ready pod -l $LabelSelector --timeout=${TimeoutSeconds}s
        Write-Host "✓ Pods are ready" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Timeout waiting for pods" -ForegroundColor Red
        return $false
    }
}

# Main deployment function
function Deploy-Application {
    Write-Host "`nStep 1: Deploying Database Infrastructure" -ForegroundColor Cyan
    
    # Deploy persistent storage
    Write-Host "Creating persistent volume and claim..." -ForegroundColor Yellow
    kubectl apply -f deployments/pvc.yaml
    kubectl apply -f deployments/pv.yaml
    
    # Deploy PostgreSQL
    Write-Host "Deploying PostgreSQL database..." -ForegroundColor Yellow
    kubectl apply -f deployments/postgresql-deployment.yaml
    kubectl apply -f deployments/postgresql-service.yaml
    
    # Wait for database
    if (-not (Wait-ForPods -LabelSelector "app=postgresql" -TimeoutSeconds 300)) {
        Write-Host "Database deployment failed" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`nStep 2: Deploying Application Configuration" -ForegroundColor Cyan
    
    # Deploy configuration
    Write-Host "Applying configuration and secrets..." -ForegroundColor Yellow
    kubectl apply -f deployments/configmap.yaml
    kubectl apply -f deployments/secret.yaml
    
    Write-Host "`nStep 3: Deploying Enhanced Application" -ForegroundColor Cyan
    
    # Deploy application
    Write-Host "Deploying Flask application with periodic logging..." -ForegroundColor Yellow
    kubectl apply -f deployments/coworking-deployment.yaml
    
    # Wait for application
    if (-not (Wait-ForPods -LabelSelector "service=coworking" -TimeoutSeconds 300)) {
        Write-Host "Application deployment failed" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`nStep 4: Verifying Deployment" -ForegroundColor Cyan
    
    # Check pod status
    Write-Host "Checking pod status..." -ForegroundColor Yellow
    kubectl get pods -l service=coworking
    
    # Check service
    Write-Host "Checking service status..." -ForegroundColor Yellow
    kubectl get svc coworking
    
    # Get external IP
    try {
        $externalIP = kubectl get svc coworking -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        if ($externalIP) {
            Write-Host "✓ Application accessible at: http://$externalIP:5153" -ForegroundColor Green
        }
        else {
            Write-Host "⚠ External IP not yet assigned. Check with: kubectl get svc coworking" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠ Could not get external IP" -ForegroundColor Yellow
    }
    
    return $true
}

# Function to show monitoring commands
function Show-MonitoringCommands {
    Write-Host "`nStep 5: Monitoring Commands" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    Write-Host "`nTo view application logs:" -ForegroundColor White
    Write-Host "kubectl logs -l service=coworking -f" -ForegroundColor Gray
    
    Write-Host "`nTo view CloudWatch logs:" -ForegroundColor White
    Write-Host "aws logs tail /aws/containerinsights/coworking-project/application --follow --region us-east-1" -ForegroundColor Gray
    
    Write-Host "`nTo test health check:" -ForegroundColor White
    Write-Host "curl http://`$SERVICE_IP:5153/health_check" -ForegroundColor Gray
    
    Write-Host "`nTo test API endpoints:" -ForegroundColor White
    Write-Host "curl http://`$SERVICE_IP:5153/api/reports/daily_usage" -ForegroundColor Gray
    Write-Host "curl http://`$SERVICE_IP:5153/api/reports/user_visits" -ForegroundColor Gray
    
    Write-Host "`nExpected periodic logs (every 30 seconds):" -ForegroundColor White
    Write-Host "[2025-10-05 16:55:30,123] INFO in app: Database connected successfully" -ForegroundColor Gray
    Write-Host "[2025-10-05 16:55:30,125] INFO in app: Fetched 150 records from tokens table" -ForegroundColor Gray
    Write-Host "[2025-10-05 16:55:30,127] INFO in app: Fetched 25 records from users table" -ForegroundColor Gray
}

# Main execution
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check kubectl
if (-not (Test-Kubectl)) {
    Write-Host "Please install kubectl first:" -ForegroundColor Red
    Write-Host "Invoke-WebRequest -Uri 'https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe' -OutFile 'kubectl.exe'" -ForegroundColor Gray
    Write-Host "Move-Item kubectl.exe C:\Windows\System32\" -ForegroundColor Gray
    exit 1
}

# Configure cluster connection
if ($ClusterType -eq "eks") {
    if (-not $ClusterName) {
        Write-Host "Please provide cluster name for EKS deployment" -ForegroundColor Red
        Write-Host "Usage: .\deploy.ps1 -ClusterType eks -ClusterName your-cluster-name" -ForegroundColor Gray
        exit 1
    }
    Write-Host "Configuring EKS cluster connection..." -ForegroundColor Yellow
    aws eks update-kubeconfig --region us-east-1 --name $ClusterName
}
else {
    Write-Host "Using local cluster (Docker Desktop)" -ForegroundColor Yellow
    kubectl config use-context docker-desktop
}

# Check cluster connection
if (-not (Test-ClusterConnection)) {
    Write-Host "Cannot connect to cluster. Please check your configuration." -ForegroundColor Red
    exit 1
}

# Deploy application
if (Deploy-Application) {
    Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Your enhanced Flask application with periodic database logging is now running." -ForegroundColor Green
    
    Show-MonitoringCommands
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Monitor CloudWatch logs for periodic database entries" -ForegroundColor White
    Write-Host "2. Test all API endpoints" -ForegroundColor White
    Write-Host "3. Verify logs appear every 30 seconds" -ForegroundColor White
    Write-Host "4. Document results for Udacity project review" -ForegroundColor White
}
else {
    Write-Host "`n❌ Deployment failed. Check the error messages above." -ForegroundColor Red
    Write-Host "Use these commands to troubleshoot:" -ForegroundColor Yellow
    Write-Host "kubectl get pods --all-namespaces" -ForegroundColor Gray
    Write-Host "kubectl describe pod -l service=coworking" -ForegroundColor Gray
    Write-Host "kubectl logs -l service=coworking --previous" -ForegroundColor Gray
}