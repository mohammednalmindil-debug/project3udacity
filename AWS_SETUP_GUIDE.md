# AWS Setup and Deployment Guide

## AWS Resources Created

### 1. ECR Repository

- **Name**: coworking-analytics
- **URI**: 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics
- **Region**: us-east-1

### 2. IAM Resources

- **Policy**: CoworkingAnalyticsCodeBuildPolicy
- **Role**: CoworkingAnalyticsCodeBuildRole
- **Permissions**: ECR push/pull, CloudWatch Logs

### 3. CodeBuild Project

- **Name**: coworking-analytics-build
- **Environment**: Amazon Linux 2 with Docker support
- **Build Spec**: buildspec.yaml
- **Service Role**: CoworkingAnalyticsCodeBuildRole

## Manual Docker Build and Push (if Docker is available)

If you have Docker installed locally, you can build and push the image manually:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767398149973.dkr.ecr.us-east-1.amazonaws.com

# Build the image
cd analytics
docker build -t coworking-analytics .

# Tag for ECR
docker tag coworking-analytics:latest 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest

# Push to ECR
docker push 767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest
```

## CodeBuild Manual Trigger

To manually trigger a build:

```bash
aws codebuild start-build --project-name coworking-analytics-build
```

## GitHub Integration

To connect your GitHub repository to CodeBuild:

1. Go to AWS CodeBuild Console
2. Select the `coworking-analytics-build` project
3. Edit the source configuration
4. Connect to your GitHub repository
5. Set up webhook for automatic builds

## Verification Commands

### Check ECR Repository

```bash
aws ecr describe-repositories --repository-names coworking-analytics
```

### List Images in ECR

```bash
aws ecr list-images --repository-name coworking-analytics
```

### Check CodeBuild Project

```bash
aws codebuild batch-get-projects --names coworking-analytics-build
```

### View Build History

```bash
aws codebuild list-builds-for-project --project-name coworking-analytics-build
```

## Kubernetes Deployment

Once the Docker image is available in ECR, deploy to Kubernetes:

```bash
# Deploy PostgreSQL
kubectl apply -f pvc.yaml
kubectl apply -f pv.yaml
kubectl apply -f postgresql-deployment.yaml
kubectl apply -f postgresql-service.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgresql --timeout=300s

# Deploy application configurations
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# Deploy analytics application
kubectl apply -f coworking-deployment.yaml

# Wait for application to be ready
kubectl wait --for=condition=ready pod -l service=coworking --timeout=300s
```

## Testing the Application

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

## CloudWatch Monitoring

To enable CloudWatch Container Insights:

1. Install CloudWatch agent on your Kubernetes cluster
2. Configure Container Insights
3. View logs in CloudWatch Console under "Container Insights"

## Cleanup

To remove all AWS resources:

```bash
# Delete CodeBuild project
aws codebuild delete-project --name coworking-analytics-build

# Delete IAM role and policy
aws iam detach-role-policy --role-name CoworkingAnalyticsCodeBuildRole --policy-arn arn:aws:iam::767398149973:policy/CoworkingAnalyticsCodeBuildPolicy
aws iam delete-role --role-name CoworkingAnalyticsCodeBuildRole
aws iam delete-policy --policy-arn arn:aws:iam::767398149973:policy/CoworkingAnalyticsCodeBuildPolicy

# Delete ECR repository (this will delete all images)
aws ecr delete-repository --repository-name coworking-analytics --force
```
