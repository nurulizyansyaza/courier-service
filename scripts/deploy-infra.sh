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

# Helper: delete stack if in ROLLBACK_COMPLETE state (can't update, must recreate)
cleanup_failed_stack() {
  local stack_name="$1"
  local region="$2"
  local status
  status=$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$region" \
    --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "DOES_NOT_EXIST")
  if [ "$status" = "ROLLBACK_COMPLETE" ]; then
    echo "  Stack $stack_name is in ROLLBACK_COMPLETE — deleting before redeploy..."
    aws cloudformation delete-stack --stack-name "$stack_name" --region "$region"
    aws cloudformation wait stack-delete-complete --stack-name "$stack_name" --region "$region"
    echo "  Deleted."
  fi
}

# Frontend stack (us-east-1 required for CloudFront WAF CLOUDFRONT scope)
echo "── Deploying Frontend Stack (us-east-1, required for CloudFront WAF) ──"
cleanup_failed_stack "$FRONTEND_STACK_NAME" "$FRONTEND_REGION"
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
cleanup_failed_stack "$API_STACK_NAME" "$AWS_REGION"
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
