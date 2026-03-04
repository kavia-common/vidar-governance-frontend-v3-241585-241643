#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/vidar-governance-frontend-v3-241585-241643/VidarGovernanceFrontendv3(SvelteKitSPA)"
cd "$WORKSPACE"
if [ -x node_modules/.bin/vitest ]; then
  node_modules/.bin/vitest --run --reporter verbose
else
  echo 'vitest not installed locally; skipping tests' >&2; exit 0
fi
