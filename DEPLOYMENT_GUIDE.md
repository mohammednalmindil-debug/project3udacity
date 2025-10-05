# Kubernetes Deployment Guide for Enhanced Flask Application

## Overview

This guide will help you deploy the updated Flask application with periodic database logging to your Kubernetes cluster.

## Prerequisites

### 1. Install Required Tools

**Install kubectl:**
```powershell
# Download kubectl for Windows
Invoke-WebRequest -Uri "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe" -OutFile "kubectl.exe"
Move-Item kubectl.exe C:\Windows\System32\
```

**Install Docker Desktop:**
- Download from: https://www.docker.com/products/docker-desktop/
- Enable Kubernetes in Docker Desktop settings

### 2. Configure kubectl

**For EKS cluster:**
```powershell
aws eks update-kubeconfig --region us-east-1 --name your-cluster-name
```

**For local cluster (Docker Desktop):**
```powershell
kubectl config use-context docker-desktop
```

## Deployment Steps

### Step 1: Verify Cluster Connection
```powershell
kubectl get nodes
kubectl get pods --all-namespaces
```

### Step 2: Deploy Database Infrastructure
```powershell
# Apply persistent volume and claim
kubectl apply -f deployments/pvc.yaml
kubectl apply -f deployments/pv.yaml

# Deploy PostgreSQL
kubectl apply -f deployments/postgresql-deployment.yaml
kubectl apply -f deployments/postgresql-service.yaml

# Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgresql --timeout=300s
```

### Step 3: Deploy Application Configuration
```powershell
# Apply configuration and secrets
kubectl apply -f deployments/configmap.yaml
kubectl apply -f deployments/secret.yaml
```

### Step 4: Deploy Enhanced Application
```powershell
# Deploy the updated application with periodic logging
kubectl apply -f deployments/coworking-deployment.yaml

# Wait for application to be ready
kubectl wait --for=condition=ready pod -l service=coworking --timeout=300s
```

### Step 5: Verify Deployment
```powershell
# Check pod status
kubectl get pods -l service=coworking

# Check service
kubectl get svc coworking

# Get external IP
kubectl get svc coworking -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Monitoring Periodic Database Logging

### 1. Check Application Logs
```powershell
# Get pod name
$podName = kubectl get pods -l service=coworking -o jsonpath='{.items[0].metadata.name}'

# View application logs
kubectl logs $podName -f
```

### 2. Monitor CloudWatch Logs
```powershell
# View CloudWatch logs
aws logs tail /aws/containerinsights/coworking-project/application --follow --region us-east-1

# Filter for database logs
aws logs filter-log-events --log-group-name /aws/containerinsights/coworking-project/application --filter-pattern "Database connected successfully" --region us-east-1
```

## Expected Log Output

Once deployed, you should see periodic logs every 30 seconds:

```
[2025-10-05 16:55:30,123] INFO in app: Database connected successfully
[2025-10-05 16:55:30,125] INFO in app: Fetched 150 records from tokens table
[2025-10-05 16:55:30,127] INFO in app: Fetched 25 records from users table
[2025-10-05 16:55:30,130] INFO in app: Daily visits data: {'2025-10-05': 45, '2025-10-04': 38}
[2025-10-05 16:55:30,132] INFO in app: Recent activity: 12 tokens created in last hour
```

## Testing Endpoints

### Health Check
```powershell
# Get service IP
$serviceIP = kubectl get svc coworking -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Test health check
curl http://$serviceIP:5153/health_check

# Test readiness check
curl http://$serviceIP:5153/readiness_check
```

### API Endpoints
```powershell
# Test daily usage API
curl http://$serviceIP:5153/api/reports/daily_usage

# Test user visits API
curl http://$serviceIP:5153/api/reports/user_visits
```

## Troubleshooting

### Common Issues

**1. Pod not starting:**
```powershell
kubectl describe pod -l service=coworking
kubectl logs -l service=coworking --previous
```

**2. Database connection issues:**
```powershell
# Check database pod
kubectl get pods -l app=postgresql
kubectl logs -l app=postgresql

# Check database service
kubectl get svc postgresql-service
```

**3. Image pull issues:**
```powershell
# Check if image exists in ECR
aws ecr describe-images --repository-name coworking-analytics --region us-east-1
```

### Debug Commands

```powershell
# Get detailed pod information
kubectl describe pod -l service=coworking

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top pods -l service=coworking
```

## Cleanup (if needed)

```powershell
# Delete application
kubectl delete -f deployments/coworking-deployment.yaml

# Delete database
kubectl delete -f deployments/postgresql-deployment.yaml
kubectl delete -f deployments/postgresql-service.yaml

# Delete storage
kubectl delete -f deployments/pvc.yaml
kubectl delete -f deployments/pv.yaml
```

## Next Steps

1. **Deploy the application** using the steps above
2. **Monitor CloudWatch logs** for periodic database entries
3. **Test all endpoints** to ensure functionality
4. **Verify periodic logging** appears every 30 seconds
5. **Document the results** for your Udacity project review

The enhanced application will now provide clear evidence of database connectivity and periodic data access in your CloudWatch logs, satisfying your project reviewer's requirements.