#!/usr/bin/env bash
# Initial setup for homelab server. Run once to prepare the server.
#
# Usage:
#   ./scripts/deploy-infra.sh [production|staging]
#
# Prerequisites:
#   - SSH access to homelab server
#   - Docker and Docker Compose installed on homelab
#   - Host Nginx installed on homelab
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-production}"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

echo "=== Setting Up Homelab Infrastructure ($ENVIRONMENT) ==="
echo "Host: $HOMELAB_HOST"
echo "Deploy path: $HOMELAB_DEPLOY_PATH"
echo ""

# Create directory structure on homelab
echo "── Creating directory structure on homelab ──"
ssh "${HOMELAB_USER}@${HOMELAB_HOST}" bash -s <<EOF
  set -euo pipefail

  # Create project directories
  sudo mkdir -p "$HOMELAB_DEPLOY_PATH"/{courier-service,courier-service-core,courier-service-api,courier-service-cli,courier-service-frontend}

  # Frontend builds: separate prod and staging directories
  sudo mkdir -p "$HOMELAB_DEPLOY_PATH/frontend-builds/prod"/{react,vue,svelte}
  sudo mkdir -p "$HOMELAB_DEPLOY_PATH/frontend-builds/staging"/{react,vue,svelte}

  # Static pages (landing page, CLI docs)
  sudo mkdir -p "$HOMELAB_DEPLOY_PATH/static"

  # Infrastructure configs
  sudo mkdir -p "$HOMELAB_DEPLOY_PATH/courier-service/infra"/{nginx,env}

  # Set ownership
  sudo chown -R ${HOMELAB_USER}:${HOMELAB_USER} "$HOMELAB_DEPLOY_PATH"

  # Verify Docker is available
  docker --version
  docker compose version

  echo "✓ Directory structure created"
EOF

echo ""
echo "── Copying infrastructure files ──"

# Copy Nginx snippet
scp "$REPO_ROOT/infra/nginx/nginx.conf" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/infra/nginx/nginx.conf"

# Copy environment configs
scp "$REPO_ROOT/infra/env/${ENVIRONMENT}.env" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/infra/env/${ENVIRONMENT}.env"

# Copy Docker files
scp "$REPO_ROOT/docker-compose.prod.yml" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/docker-compose.prod.yml"

scp "$REPO_ROOT/Dockerfile" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/Dockerfile"

# Copy static pages
scp "$REPO_ROOT/static/index.html" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/static/index.html"
scp "$REPO_ROOT/static/index-staging.html" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/static/index-staging.html"
scp "$REPO_ROOT/static/cli.html" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/static/cli.html"
scp "$REPO_ROOT/static/cli-staging.html" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/static/cli-staging.html"

echo "✓ Infrastructure files copied"
echo ""

# Include Nginx snippet in host Nginx (informational)
echo "=== Homelab infrastructure setup complete ==="
echo ""
echo "IMPORTANT: Include the Nginx snippet in your host Nginx config:"
echo ""
echo "  # In your nurulizyansyaza.com server block:"
echo "  include ${HOMELAB_DEPLOY_PATH}/courier-service/infra/nginx/nginx.conf;"
echo ""
echo "  Then reload Nginx: sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "Next steps:"
echo "  1. Deploy API:       ./scripts/deploy-api.sh $ENVIRONMENT"
echo "  2. Deploy Frontend:  ./scripts/deploy-frontend.sh $ENVIRONMENT"
echo "  3. Switch framework: ./scripts/switch-framework.sh react|vue|svelte $ENVIRONMENT"
echo ""
echo "Production URL:  https://$HOMELAB_DOMAIN/courier-service/"
echo "Staging URL:     https://$HOMELAB_DOMAIN/staging/courier-service/"
