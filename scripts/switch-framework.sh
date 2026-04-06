#!/usr/bin/env bash
# Switch the default frontend framework on the homelab.
#
# Usage:
#   ./scripts/switch-framework.sh react|vue|svelte [production|staging]
#
# This updates the Nginx config to redirect the bare frontend URL to the
# selected framework, then reloads Nginx.
set -euo pipefail

FRAMEWORK="${1:?Usage: switch-framework.sh <react|vue|svelte> [production|staging]}"
ENVIRONMENT="${2:-production}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$REPO_ROOT/infra/env/${ENVIRONMENT}.env"

if [[ "$FRAMEWORK" != "react" && "$FRAMEWORK" != "vue" && "$FRAMEWORK" != "svelte" ]]; then
  echo "Error: framework must be react, vue, or svelte"
  exit 1
fi

echo "=== Switching default framework to $FRAMEWORK ($ENVIRONMENT) ==="

# Update the Nginx config's default framework redirect
# Redirects /frontend/ → /frontend/<framework>/
sed -i.bak \
  "s|return 302 \(.*/frontend/\)[a-z]*/;|return 302 \1${FRAMEWORK}/;|g" \
  "$REPO_ROOT/infra/nginx/nginx.conf"
rm -f "$REPO_ROOT/infra/nginx/nginx.conf.bak"

# Copy updated config to homelab and reload
scp "$REPO_ROOT/infra/nginx/nginx.conf" \
  "${HOMELAB_USER}@${HOMELAB_HOST}:${HOMELAB_DEPLOY_PATH}/courier-service/infra/nginx/nginx.conf"

ssh "${HOMELAB_USER}@${HOMELAB_HOST}" "sudo nginx -t && sudo systemctl reload nginx"

echo "✓ Switched to $FRAMEWORK"
if [[ "$ENVIRONMENT" == "staging" ]]; then
  echo "URL: https://$HOMELAB_DOMAIN/frontend/${FRAMEWORK}/"
else
  echo "URL: https://$HOMELAB_DOMAIN/frontend/${FRAMEWORK}/"
fi
