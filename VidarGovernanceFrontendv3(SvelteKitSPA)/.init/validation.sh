#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/vidar-governance-frontend-v3-241585-241643/VidarGovernanceFrontendv3(SvelteKitSPA)"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/tmp" "$WORKSPACE/tmp/logs"
export NODE_ENV=development
export CI=true
PREVIEW_LOG="$WORKSPACE/tmp/logs/preview.log"
PREVIEW_PID=0
cleanup(){
  if [ "$PREVIEW_PID" -ne 0 ]; then
    pkill -P "$PREVIEW_PID" >/dev/null 2>&1 || true
    kill "$PREVIEW_PID" 2>/dev/null || true
    wait "$PREVIEW_PID" 2>/dev/null || true
  fi
}
trap 'cleanup; exit' INT TERM EXIT
# Build
if [ -x node_modules/.bin/vite ]; then
  node_modules/.bin/vite build --silent >"$PREVIEW_LOG" 2>&1 || { echo 'vite build failed' >&2; tail -n 200 "$PREVIEW_LOG" 2>/dev/null || true; exit 3; }
else
  echo 'vite not installed locally' >&2; exit 4
fi
# Start preview
node_modules/.bin/vite preview --port 5173 --strictPort >"$PREVIEW_LOG" 2>&1 &
PREVIEW_PID=$!
# record pid file for external stop
echo "$PREVIEW_PID" > "$WORKSPACE/tmp/preview.pid"
# Probe with capped exponential backoff
attempt=0
max=15
delay=1
ready=0
HTTP_STATUS="000"
while [ $attempt -lt $max ]; do
  HTTP_STATUS=$(curl -s -o "$WORKSPACE/tmp/vidar_preview_body" -w "%{http_code}" --max-time 3 http://127.0.0.1:5173/ || echo 000)
  if [ "$HTTP_STATUS" != "000" ] && [ "$HTTP_STATUS" -ge 200 ] 2>/dev/null; then ready=1; break; fi
  attempt=$((attempt+1))
  sleep $delay
  delay=$((delay*2))
  if [ $delay -gt 5 ]; then delay=5; fi
done
if [ $ready -ne 1 ]; then
  echo "Preview did not start; tail of log:" >&2
  tail -n 200 "$PREVIEW_LOG" >&2 || true
  echo "node: $(node -v || true); npm: $(npm -v || true)" >&2
  cleanup
  exit 5
fi
# Capture evidence
head -c 200 "$WORKSPACE/tmp/vidar_preview_body" > "$WORKSPACE/tmp/vidar_preview_snippet" || true
echo "preview_status=$HTTP_STATUS"
echo "snippet=$WORKSPACE/tmp/vidar_preview_snippet"
# Clean up server
cleanup
rm -f "$WORKSPACE/tmp/preview.pid" || true
