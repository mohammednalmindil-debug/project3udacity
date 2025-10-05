# Kubernetes Deployments

This directory contains all Kubernetes configuration files and deployment specifications for the Coworking Analytics application.

## File Organization

### Database Configuration
- `pvc.yaml` - PostgreSQL PersistentVolumeClaim
- `pv.yaml` - PostgreSQL PersistentVolume  
- `postgresql-deployment.yaml` - PostgreSQL database deployment
- `postgresql-service.yaml` - PostgreSQL database service

### Application Configuration
- `configmap.yaml` - Non-sensitive environment variables
- `secret.yaml` - Sensitive environment variables (database password)
- `coworking-deployment.yaml` - Analytics application deployment

### CI/CD Pipeline
- `buildspec-working.yaml` - **Working CodeBuild configuration** (use this one)
- `buildspec.yaml` - Original buildspec (had parsing issues)
- `buildspec-fixed.yaml` - Attempted fix (still had issues)
- `buildspec-minimal.yaml` - Minimal version (still had issues)
- `buildspec-new.yaml` - Alternative version (still had issues)

## Deployment Order

Deploy the files in the following order:

1. **Database Setup:**
   ```bash
   kubectl apply -f pvc.yaml
   kubectl apply -f pv.yaml
   kubectl apply -f postgresql-deployment.yaml
   kubectl apply -f postgresql-service.yaml
   ```

2. **Application Configuration:**
   ```bash
   kubectl apply -f configmap.yaml
   kubectl apply -f secret.yaml
   ```

3. **Application Deployment:**
   ```bash
   kubectl apply -f coworking-deployment.yaml
   ```

## Verification Commands

After deployment, verify with:
```bash
kubectl get pods
kubectl get svc
kubectl describe svc postgresql-service
kubectl describe deployment coworking
```

## Docker Images

The application uses Docker images from ECR:
- `767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest`
- `767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:1.0.0`

## Screenshots

The following screenshots demonstrate successful deployment:
- `AWS CodeBuild pipeline.jpg` - Successful CI/CD pipeline
- `AWS ECR repository.jpg` - Docker images in ECR
- `kubectl get svc.jpg` - Kubernetes services
- `kubectl get pods.jpg` - Running pods
- `kubectl-describe-svc-database.jpg` - Database service details
- `kubectl describe deployment frontend.jpg` - Frontend deployment
- `kubectl describe deployment backend.jpg` - Backend deployment

