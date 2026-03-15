#!/usr/bin/env bash
# Deploy frontend builds (React, Vue, Svelte) to S3 and invalidate CloudFront.
#
# Usage:
#   ./scripts/deploy-frontend.sh [staging|production]
#
# Prerequisites:
#   - AWS CLI configured with credentials
#   - Frontend built locally or in CI (all 3 frameworks)
#   - CloudFormation frontend stack already deployed
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-staging}"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

STACK_NAME="${FRONTEND_STACK_NAME}"
# Frontend stack is deployed in us-east-1 (required for CloudFront WAF CLOUDFRONT scope)
FRONTEND_REGION="us-east-1"
FRONTEND_DIR="${REPO_ROOT}/../courier-service-frontend"

# Get stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendBucketName'].OutputValue" \
  --output text \
  --region "$FRONTEND_REGION")

DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendDistributionId'].OutputValue" \
  --output text \
  --region "$FRONTEND_REGION")

echo "=== Deploying Frontend to S3 ==="
echo "Bucket: $BUCKET_NAME"
echo "Distribution: $DISTRIBUTION_ID"
echo ""

# Build and upload each framework
for FRAMEWORK in react vue svelte; do
  echo "── Building $FRAMEWORK ──"
  cd "$FRONTEND_DIR"

  npm run "use:${FRAMEWORK}"
  npm run build

  echo "── Uploading $FRAMEWORK to s3://$BUCKET_NAME/$FRAMEWORK/ ──"
  aws s3 sync dist/ "s3://$BUCKET_NAME/$FRAMEWORK/" \
    --delete \
    --region "$FRONTEND_REGION" \
    --cache-control "public, max-age=31536000, immutable" \
    --exclude "index.html"

  # index.html should not be cached aggressively
  aws s3 cp dist/index.html "s3://$BUCKET_NAME/$FRAMEWORK/index.html" \
    --region "$FRONTEND_REGION" \
    --cache-control "public, max-age=0, must-revalidate" \
    --content-type "text/html"

  echo "✓ $FRAMEWORK uploaded"
  echo ""
done

# Invalidate CloudFront cache
echo "── Invalidating CloudFront cache ──"
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --no-cli-pager

echo ""
echo "=== Frontend deployment complete ==="
FRONTEND_URL=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendURL'].OutputValue" \
  --output text \
  --region "$FRONTEND_REGION")
echo "URL: $FRONTEND_URL"
