#!/usr/bin/env bash
# Deploy or update CloudFormation stacks for a given environment.
#
# Usage:
#   ./scripts/deploy-infra.sh [staging|production]
#
# Prerequisites:
#   - AWS CLI configured with credentials
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-staging}"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

echo "=== Deploying Infrastructure ($ENVIRONMENT) ==="
echo "Region: $AWS_REGION"
echo ""

# Frontend stack (must deploy in us-east-1 for CloudFront WAF, or use REGIONAL scope)
# Note: The frontend WAF uses CLOUDFRONT scope which requires us-east-1.
# If your AWS_REGION is not us-east-1, you have two options:
#   1. Deploy the frontend stack to us-east-1
#   2. Change the WAF scope to REGIONAL and remove it from CloudFront
echo "── Deploying Frontend Stack (us-east-1, required for CloudFront WAF) ──"
aws cloudformation deploy \
  --template-file "$REPO_ROOT/infra/cloudformation/frontend-stack.yml" \
  --stack-name "$FRONTEND_STACK_NAME" \
  --parameter-overrides \
    Environment="$ENVIRONMENT" \
    ActiveFramework="$ACTIVE_FRAMEWORK" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --region "$FRONTEND_REGION"

FRONTEND_URL=$(aws cloudformation describe-stacks \
  --stack-name "$FRONTEND_STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendURL'].OutputValue" \
  --output text \
  --region "$FRONTEND_REGION")
echo "✓ Frontend: $FRONTEND_URL"
echo ""

echo "── Deploying API Stack ──"
aws cloudformation deploy \
  --template-file "$REPO_ROOT/infra/cloudformation/api-stack.yml" \
  --stack-name "$API_STACK_NAME" \
  --parameter-overrides \
    Environment="$ENVIRONMENT" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --region "$AWS_REGION"

API_URL=$(aws cloudformation describe-stacks \
  --stack-name "$API_STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayURL'].OutputValue" \
  --output text \
  --region "$AWS_REGION")
echo "✓ API: $API_URL"
echo ""

echo "=== Infrastructure deployment complete ==="
echo ""
echo "Next steps:"
echo "  1. Deploy API:      ./scripts/deploy-api.sh $ENVIRONMENT"
echo "  2. Deploy Frontend: ./scripts/deploy-frontend.sh $ENVIRONMENT"
echo "  3. Switch framework: ./scripts/switch-framework.sh react|vue|svelte $ENVIRONMENT"
