#!/bin/bash

# AWS Setup Verification Script
# This script verifies that all AWS resources are properly configured

echo "Verifying AWS Setup for Coworking Analytics..."
echo "=============================================="

# Check AWS CLI configuration
echo "1. Checking AWS CLI configuration..."
aws sts get-caller-identity
if [ $? -eq 0 ]; then
    echo "✓ AWS CLI is configured correctly"
else
    echo "✗ AWS CLI configuration failed"
    exit 1
fi

# Check ECR repository
echo ""
echo "2. Checking ECR repository..."
aws ecr describe-repositories --repository-names coworking-analytics --region us-east-1
if [ $? -eq 0 ]; then
    echo "✓ ECR repository 'coworking-analytics' exists"
else
    echo "✗ ECR repository not found"
fi

# Check CodeBuild project
echo ""
echo "3. Checking CodeBuild project..."
aws codebuild batch-get-projects --names coworking-analytics-build --region us-east-1
if [ $? -eq 0 ]; then
    echo "✓ CodeBuild project 'coworking-analytics-build' exists"
else
    echo "✗ CodeBuild project not found"
fi

# Check IAM role
echo ""
echo "4. Checking IAM role..."
aws iam get-role --role-name CoworkingAnalyticsCodeBuildRole
if [ $? -eq 0 ]; then
    echo "✓ IAM role 'CoworkingAnalyticsCodeBuildRole' exists"
else
    echo "✗ IAM role not found"
fi

# Check IAM policy
echo ""
echo "5. Checking IAM policy..."
aws iam get-policy --policy-arn arn:aws:iam::767398149973:policy/CoworkingAnalyticsCodeBuildPolicy
if [ $? -eq 0 ]; then
    echo "✓ IAM policy 'CoworkingAnalyticsCodeBuildPolicy' exists"
else
    echo "✗ IAM policy not found"
fi

echo ""
echo "Verification completed!"
echo ""
echo "Next steps:"
echo "1. Push your code to GitHub repository"
echo "2. Connect GitHub repository to CodeBuild project"
echo "3. Trigger a build to create Docker image in ECR"
echo "4. Deploy to Kubernetes using the provided YAML files"
