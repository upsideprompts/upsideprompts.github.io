#!/usr/bin/env bash
# Copy Flutter web build into this folder for GitHub Pages (/taboptions3/).
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -d build/web ]]; then
  echo "Missing build/web. Run: flutter build web --base-href /taboptions3/" >&2
  exit 1
fi

rsync -a \
  --filter='P lib/' \
  --filter='P web/' \
  --filter='P test/' \
  --filter='P build/' \
  --filter='P assets/' \
  --filter='P .dart_tool/' \
  --filter='P .idea/' \
  --filter='P pubspec.yaml' \
  --filter='P pubspec.lock' \
  --filter='P analysis_options.yaml' \
  --filter='P README.md' \
  --filter='P deploy_web.sh' \
  --filter='P .gitignore' \
  --filter='P .metadata' \
  --filter='P reference_*.js' \
  --filter='P *.iml' \
  build/web/ ./

echo "Deployed build/web → taboptions3/ (for /taboptions3/ on Pages)"
