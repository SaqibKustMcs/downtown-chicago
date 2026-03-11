#!/usr/bin/env bash
# Build Flutter web locally and deploy only build/web (no Flutter on Vercel).
# Usage: ./scripts/deploy-vercel.sh [--prod]
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Building Flutter web (HTML renderer)..."
flutter build web --web-renderer html

echo "==> Adding vercel.json for SPA routing..."
cp "$ROOT/config/vercel-build-web.json" "$ROOT/build/web/vercel.json"

echo "==> Deploying build/web to Vercel..."
cd "$ROOT/build/web"
vercel "$@"

echo "==> Done. Run 'vercel --prod' from build/web to promote to production."
