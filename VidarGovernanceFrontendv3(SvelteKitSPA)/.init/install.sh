#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/vidar-governance-frontend-v3-241585-241643/VidarGovernanceFrontendv3(SvelteKitSPA)"
cd "$WORKSPACE"
OWNER=${SUDO_USER:-${USER:-$(id -un 2>/dev/null || echo root)}}
# persist env idempotently
sudo sh -c 'cat >/etc/profile.d/vidar_frontend_env.sh <<"EOF"
export NODE_ENV=development
export CI=true
EOF
' || true
export NODE_ENV=development
if [ ! -f package.json ]; then echo "package.json missing; run scaffold step first" >&2; exit 2; fi
# If yarn lock and yarn present prefer yarn frozen install
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
  yarn install --frozen-lockfile --silent || { echo 'yarn install failed' >&2; exit 3; }
  if [ "$(id -u)" -eq 0 ]; then sudo chown -R "$OWNER":"$OWNER" "$WORKSPACE/node_modules" || true; fi
  exit 0
fi
# If npm lock exists use npm ci
if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
  npm ci --prefer-offline --no-audit --no-fund --silent || { echo 'npm ci failed' >&2; exit 4; }
  if [ "$(id -u)" -eq 0 ]; then sudo chown -R "$OWNER":"$OWNER" "$WORKSPACE/node_modules" || true; fi
  exit 0
fi
# No lockfile: add recommended devDependencies only if absent
recommend=("vite@^5.0.0" "svelte@^4.0.0" "@sveltejs/vite-plugin-svelte@^2.0.0" "typescript@^5.0.0" "vitest@^1.0.0" "jsdom@^21.0.0" "esbuild@^0.18.0")
for pkg in "${recommend[@]}"; do
  name=${pkg%%@*}
  if node -e "try{const p=require('./package.json'); if((p.dependencies&&p.dependencies['$name'])||(p.devDependencies&&p.devDependencies['$name'])) process.exit(0); process.exit(1)}catch(e){process.exit(0)}" >/dev/null 2>&1; then
    true
  else
    npm i -D --no-audit --no-fund --no-save "$pkg" >/dev/null 2>&1 || true
  fi
done
# Install to generate package-lock.json deterministically
npm install --no-audit --no-fund --silent || { echo 'npm install failed' >&2; exit 5; }
if [ -f package-lock.json ]; then echo 'lockfile generated'; fi
if [ "$(id -u)" -eq 0 ]; then sudo chown -R "$OWNER":"$OWNER" "$WORKSPACE/node_modules" || true; fi
# Optional Playwright installation
if [ "${INSTALL_PLAYWRIGHT:-0}" = "1" ]; then
  sudo apt-get update -q && sudo apt-get install -y -qq libnss3 libatk1.0-0 libatk-bridge2.0-0 libx11-xcb1 libxss1 libasound2 libxcomposite1 libxrandr2 libxdamage1 libgbm1 || true
  npm i -D --no-audit --no-fund --silent playwright || { echo 'playwright install failed' >&2; exit 7; }
  if ! ./node_modules/.bin/playwright install --with-deps; then echo 'playwright browser install failed; check logs' >&2; exit 8; fi
fi
# Verify local binaries (non-fatal)
if [ -x node_modules/.bin/vite ]; then node_modules/.bin/vite --version || true; else echo 'vite not found in node_modules' >&2; fi
if [ -x node_modules/.bin/vitest ]; then node_modules/.bin/vitest --version || true; fi
