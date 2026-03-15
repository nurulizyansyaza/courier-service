#!/usr/bin/env bash
# Build, push Docker image to ECR, and update ECS Fargate service.
#
# Usage:
#   ./scripts/deploy-api.sh [staging|production]
#
# Prerequisites:
#   - AWS CLI configured with credentials
#   - Docker running locally
#   - CloudFormation API stack already deployed
#   - All 4 repos cloned in the same parent directory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$REPO_ROOT/.." && pwd)"
ENVIRONMENT="${1:-staging}"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

STACK_NAME="${API_STACK_NAME}"

# Get stack outputs
ECR_URI=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ECRRepositoryUri'].OutputValue" \
  --output text \
  --region "$AWS_REGION")

CLUSTER_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ECSClusterName'].OutputValue" \
  --output text \
  --region "$AWS_REGION")

SERVICE_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ECSServiceName'].OutputValue" \
  --output text \
  --region "$AWS_REGION")

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_TAG="$(git -C "$REPO_ROOT" rev-parse --short HEAD)-$(date +%Y%m%d%H%M%S)"

echo "=== Deploying API to ECS Fargate ==="
echo "ECR: $ECR_URI"
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Image tag: $IMAGE_TAG"
echo ""

# Authenticate Docker with ECR
echo "── Logging into ECR ──"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Build from project root (needs all repos as context)
echo "── Building Docker image ──"
docker build \
  -f "$REPO_ROOT/Dockerfile" \
  -t "$ECR_URI:$IMAGE_TAG" \
  -t "$ECR_URI:latest" \
  "$PROJECT_ROOT"

# Push to ECR
echo "── Pushing to ECR ──"
docker push "$ECR_URI:$IMAGE_TAG"
docker push "$ECR_URI:latest"

# Force new deployment (pulls latest image)
echo "── Updating ECS service ──"
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --force-new-deployment \
  --region "$AWS_REGION" \
  --no-cli-pager > /dev/null

echo ""
echo "=== API deployment initiated ==="
echo "ECS is rolling out the new task. Monitor with:"
echo "  aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $AWS_REGION --query 'services[0].deployments'"

API_URL=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayURL'].OutputValue" \
  --output text \
  --region "$AWS_REGION")
echo "API URL: $API_URL"
echo "Health: $API_URL/api/health"
