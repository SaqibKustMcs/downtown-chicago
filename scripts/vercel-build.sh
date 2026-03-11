#!/usr/bin/env bash
# Single script for Vercel: install Flutter and build web in the same shell
# so "flutter" is on PATH when "flutter build web" runs.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Install Flutter if not present (Vercel may cache .flutter_sdk)
if [ ! -x ".flutter_sdk/bin/flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 .flutter_sdk
fi
export PATH="$ROOT/.flutter_sdk/bin:$PATH"

# Ensure we have dependencies and build
flutter doctor -v || true
flutter pub get
flutter build web

echo "Build complete: build/web"
