#!/bin/bash

# Coworking Analytics Deployment Script
# This script automates the deployment process for the coworking analytics application

set -e

echo "Starting Coworking Analytics Deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if connected to a Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Not connected to a Kubernetes cluster"
    exit 1
fi

echo "✓ Kubernetes cluster connection verified"

# Deploy PostgreSQL
echo "Deploying PostgreSQL database..."
kubectl apply -f pvc.yaml
kubectl apply -f pv.yaml
kubectl apply -f postgresql-deployment.yaml
kubectl apply -f postgresql-service.yaml

echo "Waiting for PostgreSQL pod to be ready..."
kubectl wait --for=condition=ready pod -l app=postgresql --timeout=300s

echo "✓ PostgreSQL deployment completed"

# Deploy application configurations
echo "Deploying application configurations..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

echo "✓ Application configurations deployed"

# Deploy analytics application
echo "Deploying analytics application..."
kubectl apply -f coworking-deployment.yaml

echo "Waiting for analytics application to be ready..."
kubectl wait --for=condition=ready pod -l service=coworking --timeout=300s

echo "✓ Analytics application deployment completed"

# Display service information
echo ""
echo "Deployment Summary:"
echo "==================="
echo "Services:"
kubectl get svc

echo ""
echo "Pods:"
kubectl get pods

echo ""
echo "To access the application:"
echo "1. Get the external IP: kubectl get svc coworking"
echo "2. Test health check: curl http://<EXTERNAL_IP>:5153/health_check"
echo "3. Test daily usage report: curl http://<EXTERNAL_IP>:5153/api/reports/daily_usage"
echo "4. Test user visits report: curl http://<EXTERNAL_IP>:5153/api/reports/user_visits"

echo ""
echo "Deployment completed successfully!"


