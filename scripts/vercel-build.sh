#!/usr/bin/env bash
# Vercel: install Flutter and build web in one shell so "flutter" is on PATH.
# On failure, build locally and deploy build/web (see DEPLOY_VERCEL.md).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Checking for Flutter..."
if [ ! -x ".flutter_sdk/bin/flutter" ]; then
  echo "==> Installing Flutter (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 .flutter_sdk || { echo "ERROR: git clone failed"; exit 1; }
fi
export PATH="$ROOT/.flutter_sdk/bin:$PATH"

echo "==> Flutter version: $(flutter --version 2>/dev/null | head -1)"
flutter doctor -v || true
echo "==> Getting dependencies..."
flutter pub get || { echo "ERROR: flutter pub get failed"; exit 1; }

echo "==> Building web (HTML renderer)..."
if flutter build web --web-renderer html; then
  echo "==> Build complete: build/web"
  exit 0
fi

echo "ERROR: flutter build web failed (exit $?). Try building locally: flutter build web --web-renderer html && deploy build/web"
exit 1
