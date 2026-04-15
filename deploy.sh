#!/usr/bin/env bash
# Deploy kokoro-docs to Cloudflare Pages.
#
# Prerequisites:
#   - CLOUDFLARE_EMAIL and CLOUDFLARE_API_KEY must be set in env.
#   - Python 3 with mkdocs-material installed (`pip install mkdocs-material`).
#   - npx available (wrangler is resolved at runtime, no global install needed).
#
# Usage:
#   ./deploy.sh            Deploy current working tree.
#   ./deploy.sh --clean    Clean build before deploying.
#
# Result: site is live at https://docs.happykokoro.com/ (and kokoro-docs.pages.dev/).

set -euo pipefail

cd "$(dirname "$0")"

if [[ -z "${CLOUDFLARE_EMAIL:-}" ]] || [[ -z "${CLOUDFLARE_API_KEY:-}" ]]; then
  echo "error: CLOUDFLARE_EMAIL and CLOUDFLARE_API_KEY must be set" >&2
  exit 1
fi

MKDOCS_ARGS=()
if [[ "${1:-}" == "--clean" ]]; then
  MKDOCS_ARGS+=("--clean")
fi

echo ">> Building MkDocs site..."
python3 -m mkdocs build "${MKDOCS_ARGS[@]}"

echo ">> Deploying to Cloudflare Pages (project: kokoro-docs)..."
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
npx --yes wrangler pages deploy site \
  --project-name kokoro-docs \
  --branch main \
  --commit-hash "${COMMIT_HASH}" \
  --commit-dirty=true

echo ""
echo ">> Done. Verifying..."
sleep 3
if curl -sfI https://kokoro-docs.pages.dev/ | head -1 | grep -q "200"; then
  echo ">> https://kokoro-docs.pages.dev/ is 200 OK"
fi
if curl -sfI https://docs.happykokoro.com/ | head -1 | grep -q "200"; then
  echo ">> https://docs.happykokoro.com/ is 200 OK"
fi
