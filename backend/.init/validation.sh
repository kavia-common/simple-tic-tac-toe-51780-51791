#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-tic-tac-toe-51780-51791/backend"
cd "$WORKSPACE"
# skip redundant install if node_modules exists
if [ ! -d node_modules ]; then
  if [ -f package-lock.json ] && [ "$(npm -v | cut -d. -f1)" -ge 7 ]; then
    npm ci --no-audit --prefer-offline --no-fund || { echo 'npm ci failed' >&2; exit 3; }
  else
    npm i --no-audit --prefer-offline --no-fund || { echo 'npm i failed' >&2; exit 4; }
  fi
fi
# determine PORT from .env via node (dotenv must be in deps)
PORT=$(node -e "try{require('dotenv').config(); console.log(process.env.PORT||3000)}catch(e){console.log(3000)}")
export PORT
# start app in background
node ./src/index.js &
SERVER_PID=$!
TMPFILE=$(mktemp /tmp/health_resp.XXXXXX)
cleanup() { kill "$SERVER_PID" >/dev/null 2>&1 || true; wait "$SERVER_PID" 2>/dev/null || true; rm -f "$TMPFILE" || true; }
trap 'cleanup' EXIT
# wait for health with retries
TRIES=15
SLEEP=1
for i in $(seq 1 $TRIES); do
  if curl -sS --fail "http://127.0.0.1:${PORT}/health" -m 2 -o "$TMPFILE"; then
    # produce valid JSON: escape health body
    HEALTH_BODY=$(python3 - <<'PY'
import json,sys
with open(sys.argv[1],'r') as f:
    print(json.dumps(f.read()))
PY
"$TMPFILE")
    printf '{"validation":"success","pid":%d,"health":%s}\n' "$SERVER_PID" "$HEALTH_BODY"
    cleanup
    exit 0
  fi
  sleep $SLEEP
done
echo 'validation failed: health endpoint not reachable' >&2
cleanup
exit 6
