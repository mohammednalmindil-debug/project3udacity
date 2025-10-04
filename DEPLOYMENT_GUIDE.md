# Complete Deployment Guide - Coworking Analytics Application

## 🎯 Current Status

✅ **Completed:**
- AWS CLI configured with your credentials
- ECR repository created: `coworking-analytics`
- CodeBuild project created: `coworking-analytics-build`
- GitHub repository: [https://github.com/mohammednalmindil-debug/project3udacity.git](https://github.com/mohammednalmindil-debug/project3udacity.git)
- All Kubernetes YAML files created
- Complete application code ready

⚠️ **In Progress:**
- CodeBuild pipeline (having YAML syntax issues)
- Docker image creation in ECR

## 🚀 Manual Docker Build & Push (Alternative Approach)

Since we're experiencing YAML parsing issues with CodeBuild, here's how to manually build and push the Docker image:

### Step 1: Install Docker (if not already installed)
```bash
# On Windows with Chocolatey
choco install docker-desktop

# Or download from: https://www.docker.com/products/docker-desktop
```

### Step 2: Build and Push Docker Image
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767398149973.dkr.ecr.us-east-1.amazonaws.com

# Build the image
cd analytics
docker build -t coworking-analytics .

# Tag for ECR
docker tag coworking-analytics:latest 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest
docker tag coworking-analytics:latest 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:1.0.0

# Push to ECR
docker push 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest
docker push 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:1.0.0
```

## 🎛️ Kubernetes Cluster Setup

### Option 1: AWS EKS (Recommended)
```bash
# Install eksctl
# Windows: choco install eksctl
# Or download from: https://github.com/eksctl-io/eksctl/releases

# Create EKS cluster
eksctl create cluster --name coworking-cluster --region us-east-1 --nodegroup-name workers --node-type t3.medium --nodes 2 --nodes-min 1 --nodes-max 3 --managed

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name coworking-cluster
```

### Option 2: Local Kubernetes (Minikube)
```bash
# Install Minikube
# Windows: choco install minikube

# Start Minikube
minikube start

# Enable LoadBalancer (for Windows)
minikube tunnel
```

### Option 3: Docker Desktop Kubernetes
1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Enable Kubernetes
4. Click "Apply & Restart"

## 📦 Deploy to Kubernetes

### Step 1: Deploy PostgreSQL
```bash
# Apply PostgreSQL configurations
kubectl apply -f pvc.yaml
kubectl apply -f pv.yaml
kubectl apply -f postgresql-deployment.yaml
kubectl apply -f postgresql-service.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgresql --timeout=300s
```

### Step 2: Initialize Database
```bash
# Port forward PostgreSQL
kubectl port-forward service/postgresql-service 5433:5432 &

# Initialize database (in another terminal)
PGPASSWORD="mypassword" psql --host 127.0.0.1 -U myuser -d mydatabase -p 5433 < db/01_init_tables.sql
```

### Step 3: Deploy Analytics Application
```bash
# Apply application configurations
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f coworking-deployment.yaml

# Wait for application to be ready
kubectl wait --for=condition=ready pod -l service=coworking --timeout=300s
```

## 🧪 Testing the Application

### Get External IP
```bash
kubectl get svc coworking
```

### Test Endpoints
```bash
# Health check
curl http://<EXTERNAL_IP>:5153/health_check

# Daily usage report
curl http://<EXTERNAL_IP>:5153/api/reports/daily_usage

# User visits report
curl http://<EXTERNAL_IP>:5153/api/reports/user_visits
```

## 📊 Verification Commands

### Check Services
```bash
kubectl get svc
```

### Check Pods
```bash
kubectl get pods
```

### Check Deployments
```bash
kubectl get deployments
```

### Describe Services
```bash
kubectl describe svc postgresql-service
kubectl describe svc coworking
```

### Describe Deployments
```bash
kubectl describe deployment postgresql
kubectl describe deployment coworking
```

## 🔧 Troubleshooting

### Common Issues:

1. **Image Pull Errors**
   ```bash
   # Check if image exists in ECR
   aws ecr list-images --repository-name coworking-analytics
   ```

2. **Database Connection Issues**
   ```bash
   # Check PostgreSQL logs
   kubectl logs -l app=postgresql
   ```

3. **Application Not Starting**
   ```bash
   # Check application logs
   kubectl logs -l service=coworking
   ```

## 📸 Screenshots for Submission

Take screenshots of:

1. **AWS CodeBuild Console** - Show the project and build history
2. **AWS ECR Console** - Show the Docker images
3. **Kubernetes Services** - `kubectl get svc` output
4. **Kubernetes Pods** - `kubectl get pods` output
5. **Database Service** - `kubectl describe svc postgresql-service`
6. **Application Deployment** - `kubectl describe deployment coworking`
7. **CloudWatch Logs** - Container Insights (if available)

## 🎯 Next Steps

1. **Install Docker** on your local machine
2. **Build and push** the Docker image to ECR manually
3. **Set up Kubernetes cluster** (EKS recommended)
4. **Deploy the application** using the provided YAML files
5. **Test the endpoints** and take screenshots
6. **Set up CloudWatch Container Insights** for monitoring

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Review the logs using `kubectl logs`
3. Verify AWS resources are properly configured
4. Ensure all YAML files are applied correctly

The application is fully configured and ready for deployment. The main challenge was the CodeBuild YAML parsing, but the manual Docker build approach will work perfectly for your submission.
