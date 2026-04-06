#!/usr/bin/env bash
# Build all frontend frameworks and deploy to homelab server.
#
# Usage:
#   ./scripts/deploy-frontend.sh [production|staging]
#
# Prerequisites:
#   - SSH access to homelab server
#   - Node.js installed locally
#   - courier-service-core built locally
#   - Homelab infrastructure set up (deploy-infra.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-production}"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

FRONTEND_DIR="${REPO_ROOT}/../courier-service-frontend"

# Determine paths based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
  BUILDS_DIR="frontend-builds/staging"
  BASE_PREFIX="/staging/courier-service/frontend"
  API_BASE_URL="/staging/courier-service/api"
else
  BUILDS_DIR="frontend-builds/prod"
  BASE_PREFIX="/courier-service/frontend"
  API_BASE_URL="/courier-service/api"
fi

echo "=== Deploying Frontend to Homelab ($ENVIRONMENT) ==="
echo "Host: $HOMELAB_HOST"
echo "Base prefix: $BASE_PREFIX"
echo ""

# Build and upload each framework
for FRAMEWORK in react vue svelte; do
  echo "── Building $FRAMEWORK ──"
  cd "$FRONTEND_DIR"

  npm run "use:${FRAMEWORK}"
  VITE_API_BASE_URL="$API_BASE_URL" npx vite build --base="${BASE_PREFIX}/${FRAMEWORK}/"

  echo "── Uploading $FRAMEWORK to homelab ──"
  rsync -az --delete \
    dist/ \
    "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/${BUILDS_DIR}/${FRAMEWORK}/"

  echo "✓ $FRAMEWORK uploaded"
  echo ""
done

# Reload host Nginx to pick up any config changes
echo "── Reloading Nginx ──"
ssh "${HOMELAB_USER}@${HOMELAB_HOST}" "sudo nginx -t && sudo systemctl reload nginx"

echo ""
echo "=== Frontend deployment complete ($ENVIRONMENT) ==="
echo ""
echo "Framework URLs:"
echo "  https://$HOMELAB_DOMAIN${BASE_PREFIX}/react/"
echo "  https://$HOMELAB_DOMAIN${BASE_PREFIX}/vue/"
echo "  https://$HOMELAB_DOMAIN${BASE_PREFIX}/svelte/"
