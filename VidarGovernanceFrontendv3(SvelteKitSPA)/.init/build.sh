#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/vidar-governance-frontend-v3-241585-241643/VidarGovernanceFrontendv3(SvelteKitSPA)"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/tmp" "$WORKSPACE/tmp/logs"
PREVIEW_LOG="$WORKSPACE/tmp/logs/preview.log"
# Ensure local vite is present
if [ -x node_modules/.bin/vite ]; then
  node_modules/.bin/vite build --silent >"$PREVIEW_LOG" 2>&1 || { echo 'vite build failed' >&2; tail -n 200 "$PREVIEW_LOG" 2>/dev/null || true; exit 3; }
else
  echo 'vite not installed locally' >&2; exit 4
fi
