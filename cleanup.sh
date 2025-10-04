#!/bin/bash

# Coworking Analytics Cleanup Script
# This script removes all deployed resources

set -e

echo "Starting cleanup of Coworking Analytics deployment..."

# Remove analytics application
echo "Removing analytics application..."
kubectl delete -f coworking-deployment.yaml --ignore-not-found=true

# Remove configurations
echo "Removing application configurations..."
kubectl delete -f configmap.yaml --ignore-not-found=true
kubectl delete -f secret.yaml --ignore-not-found=true

# Remove PostgreSQL
echo "Removing PostgreSQL database..."
kubectl delete -f postgresql-service.yaml --ignore-not-found=true
kubectl delete -f postgresql-deployment.yaml --ignore-not-found=true
kubectl delete -f pvc.yaml --ignore-not-found=true
kubectl delete -f pv.yaml --ignore-not-found=true

echo "✓ Cleanup completed successfully!"

# Display remaining resources
echo ""
echo "Remaining resources:"
kubectl get all
