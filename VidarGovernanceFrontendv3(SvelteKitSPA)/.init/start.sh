#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/vidar-governance-frontend-v3-241585-241643/VidarGovernanceFrontendv3(SvelteKitSPA)"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/tmp" "$WORKSPACE/tmp/logs"
export NODE_ENV=development
PREVIEW_LOG="$WORKSPACE/tmp/logs/preview.log"
: >"$PREVIEW_LOG"
if [ -x node_modules/.bin/vite ]; then
  node_modules/.bin/vite preview --port 5173 --strictPort >"$PREVIEW_LOG" 2>&1 &
  echo $! > "$WORKSPACE/tmp/preview.pid"
else
  echo 'vite not installed locally' >&2; exit 4
fi
