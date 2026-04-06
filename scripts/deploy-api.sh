#!/usr/bin/env bash
# Build Docker image and deploy API to homelab server.
#
# Usage:
#   ./scripts/deploy-api.sh [production|staging]
#
# Prerequisites:
#   - SSH access to homelab server
#   - Docker running locally and on homelab
#   - All 4 repos cloned in the same parent directory
#   - Homelab infrastructure set up (deploy-infra.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$REPO_ROOT/.." && pwd)"
ENVIRONMENT="${1:-production}"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

# Determine which container to deploy
if [[ "$ENVIRONMENT" == "staging" ]]; then
  CONTAINER_NAME="courier-api-staging"
  API_PORT=3001
  BASE_PATH=""
else
  CONTAINER_NAME="courier-api"
  API_PORT=3000
  BASE_PATH=""
fi

IMAGE_TAG="courier-service-api:$(date +%Y%m%d%H%M%S)"
IMAGE_LATEST="courier-service-api:latest"

echo "=== Deploying API to Homelab ($ENVIRONMENT) ==="
echo "Host: $HOMELAB_HOST"
echo "Container: $CONTAINER_NAME"
echo "Image tag: $IMAGE_TAG"
echo ""

# Build Docker image locally
echo "── Building Docker image ──"
docker build \
  -f "$REPO_ROOT/Dockerfile" \
  -t "$IMAGE_TAG" \
  -t "$IMAGE_LATEST" \
  "$PROJECT_ROOT"

# Save and transfer image to homelab
echo "── Transferring image to homelab ──"
docker save "$IMAGE_LATEST" | ssh "${HOMELAB_USER}@${HOMELAB_HOST}" "docker load"

echo "✓ Image transferred"
echo ""

# Copy latest Docker Compose and config files
echo "── Updating configuration ──"
scp "$REPO_ROOT/docker-compose.prod.yml" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/docker-compose.prod.yml"
scp "$REPO_ROOT/Dockerfile" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/Dockerfile"
scp "$REPO_ROOT/infra/nginx/nginx.conf" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/infra/nginx/nginx.conf"

# Restart API service on homelab
echo "── Restarting $CONTAINER_NAME ──"
ssh "${HOMELAB_USER}@${HOMELAB_HOST}" bash -s <<EOF
  set -euo pipefail
  cd "$HOMELAB_DEPLOY_PATH/courier-service"
  docker compose -f docker-compose.prod.yml up -d --no-deps "$CONTAINER_NAME"
  echo "Waiting for health check..."
  sleep 5
  docker compose -f docker-compose.prod.yml ps "$CONTAINER_NAME"
EOF

echo ""
echo "=== API deployment complete ($ENVIRONMENT) ==="
echo "Health check: https://$HOMELAB_DOMAIN/api/health"
