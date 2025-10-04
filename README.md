# Coworking Analytics Application

A containerized Flask-based analytics application deployed on Kubernetes with PostgreSQL database, automated CI/CD pipeline using AWS CodeBuild, and container registry management through Amazon ECR.

## Architecture Overview

This application follows a microservices architecture with the following components:

- **PostgreSQL Database**: Persistent data storage with Kubernetes-managed volumes
- **Flask Analytics API**: RESTful service providing usage reports and health checks
- **Docker Containerization**: Multi-stage builds with security best practices
- **AWS CodeBuild Pipeline**: Automated build, test, and deployment to ECR
- **Kubernetes Orchestration**: Scalable deployment with ConfigMaps and Secrets

## Technology Stack

- **Backend**: Python 3.11, Flask 2.3.3, psycopg2-binary
- **Database**: PostgreSQL 15+ with persistent storage
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes with LoadBalancer services
- **CI/CD**: AWS CodeBuild with semantic versioning
- **Registry**: Amazon ECR for container image storage
- **Monitoring**: CloudWatch Container Insights

## Deployment Process

### Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl connected to your Kubernetes cluster
- Docker installed and running
- PostgreSQL client tools (psql)

### Database Setup

1. Apply PostgreSQL configurations in order:

   ```bash
   kubectl apply -f pvc.yaml
   kubectl apply -f pv.yaml
   kubectl apply -f postgresql-deployment.yaml
   kubectl apply -f postgresql-service.yaml
   ```

2. Initialize database with seed data:
   ```bash
   kubectl port-forward service/postgresql-service 5433:5432 &
   PGPASSWORD="mypassword" psql --host 127.0.0.1 -U myuser -d mydatabase -p 5433 < db/01_init_tables.sql
   ```

### Application Deployment

1. The `coworking-deployment.yaml` is already configured with the ECR image URI: `767398149973.dkr.ecr.us-east-1.amazonaws.com/coworking-analytics:latest`
2. Apply Kubernetes configurations:
   ```bash
   kubectl apply -f configmap.yaml
   kubectl apply -f secret.yaml
   kubectl apply -f coworking-deployment.yaml
   ```

### CI/CD Pipeline

The CodeBuild pipeline automatically triggers on repository updates, building Docker images with semantic versioning and pushing to ECR.

**AWS Configuration:**

- **Account ID**: 767398149973
- **Region**: us-east-1
- **ECR Repository**: coworking-analytics
- **CodeBuild Project**: coworking-analytics-build

**Environment Variables Configured:**

- `AWS_ACCOUNT_ID`: 767398149973
- `AWS_DEFAULT_REGION`: us-east-1
- `IMAGE_REPO_NAME`: coworking-analytics

## API Endpoints

- `GET /health_check`: Application health status
- `GET /readiness_check`: Kubernetes readiness probe
- `GET /api/reports/daily_usage`: Daily check-in analytics
- `GET /api/reports/user_visits`: User visit statistics

## Resource Optimization

### AWS Instance Recommendations

**Recommended Instance Type**: `t3.medium` or `t3.large`

- **CPU**: 2-4 vCPUs sufficient for moderate traffic
- **Memory**: 4-8 GB RAM for PostgreSQL and application
- **Storage**: GP3 EBS volumes for better price-performance ratio
- **Network**: Enhanced networking for improved throughput

### Cost Optimization Strategies

1. **Right-sizing**: Use AWS Compute Optimizer to identify optimal instance sizes
2. **Spot Instances**: Deploy non-critical workloads on Spot instances for up to 90% savings
3. **Reserved Instances**: Commit to 1-3 year terms for predictable workloads
4. **Auto Scaling**: Implement horizontal pod autoscaling based on CPU/memory metrics
5. **Storage Optimization**: Use EBS GP3 with provisioned IOPS only when needed

## Monitoring and Logging

CloudWatch Container Insights provides comprehensive monitoring of:

- Container performance metrics
- Application logs and errors
- Resource utilization trends
- Health check status

## Security Considerations

- Non-root user execution in containers
- Secrets management through Kubernetes Secrets
- Network policies for pod-to-pod communication
- Regular security scanning of container images
- RBAC policies for cluster access control

## Scaling and High Availability

The deployment supports horizontal scaling through Kubernetes replica sets. For production environments, consider:

- Multi-AZ deployment across availability zones
- Database read replicas for improved performance
- Application load balancing with multiple replicas
- Persistent volume replication for data durability

## Troubleshooting

Common issues and solutions:

- **Database Connection**: Verify ConfigMap and Secret values
- **Image Pull Errors**: Check ECR permissions and image URI
- **Health Check Failures**: Review application logs and database connectivity
- **Resource Constraints**: Monitor CPU and memory limits in deployment

## Release Management

New releases are deployed through the automated CI/CD pipeline. The build process:

1. Triggers on code commits to main branch
2. Builds Docker image with semantic versioning
3. Pushes to ECR with both versioned and latest tags
4. Updates Kubernetes deployment with new image

To deploy changes, simply push to the repository and monitor the CodeBuild pipeline for successful completion.
