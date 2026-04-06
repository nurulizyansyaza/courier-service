#!/usr/bin/env bash
# Switch the active frontend framework by updating the CloudFront origin path.
#
# Usage:
#   ./scripts/switch-framework.sh react|vue|svelte [staging|production]
#
# This updates the CloudFront distribution's origin path to point to
# the specified framework's S3 prefix, then creates an invalidation.
set -euo pipefail

FRAMEWORK="${1:?Usage: switch-framework.sh <react|vue|svelte> [staging|production]}"
ENVIRONMENT="${2:-staging}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

if [[ "$FRAMEWORK" != "react" && "$FRAMEWORK" != "vue" && "$FRAMEWORK" != "svelte" ]]; then
  echo "Error: framework must be react, vue, or svelte"
  exit 1
fi

STACK_NAME="${FRONTEND_STACK_NAME}"
# Frontend stack is deployed in us-east-1 (required for CloudFront WAF)
FRONTEND_REGION="us-east-1"

DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendDistributionId'].OutputValue" \
  --output text \
  --region "$FRONTEND_REGION")

echo "=== Switching to $FRAMEWORK ==="
echo "Distribution: $DISTRIBUTION_ID"

# Get current config
ETAG=$(aws cloudfront get-distribution-config \
  --id "$DISTRIBUTION_ID" \
  --query "ETag" --output text)

aws cloudfront get-distribution-config \
  --id "$DISTRIBUTION_ID" \
  --query "DistributionConfig" > /tmp/cf-dist-config.json

# Update origin path to the selected framework
python3 -c "
import json, sys
with open('/tmp/cf-dist-config.json') as f:
    config = json.load(f)
config['Origins']['Items'][0]['OriginPath'] = '/${FRAMEWORK}'
with open('/tmp/cf-dist-config.json', 'w') as f:
    json.dump(config, f)
"

# Apply updated config
aws cloudfront update-distribution \
  --id "$DISTRIBUTION_ID" \
  --distribution-config "file:///tmp/cf-dist-config.json" \
  --if-match "$ETAG" \
  --no-cli-pager > /dev/null

# Invalidate cache so the switch takes effect immediately
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --no-cli-pager > /dev/null

rm -f /tmp/cf-dist-config.json

echo "✓ Switched to $FRAMEWORK"

FRONTEND_URL=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendURL'].OutputValue" \
  --output text \
  --region "$FRONTEND_REGION")
echo "URL: $FRONTEND_URL"
