#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-tic-tac-toe-51780-51791/backend"
cd "$WORKSPACE"
# Ensure npm present
command -v npm >/dev/null 2>&1 || { echo 'npm not found' >&2; exit 2; }
# npx may be optional
command -v npx >/dev/null 2>&1 || true
NPM_MAJOR=$(npm -v | cut -d. -f1 || echo 0)
# If package.json was created by our scaffolding step, scaffold step leaves .scaffolded file.
REGEN_LOCK=0
if [ -f package.json ] && [ -f .scaffolded ]; then REGEN_LOCK=1; fi
# idempotent skip: if node_modules present and lockfile exists, skip install
if [ -d node_modules ] && [ -f package-lock.json ]; then
  echo 'skipping install (node_modules exists)'
  exit 0
fi
# If package.json was scaffolded and lockfile missing or we want to validate, regenerate lockfile in dry-run manner
if [ "$REGEN_LOCK" -eq 1 ]; then
  # attempt to regenerate package-lock.json without modifying node_modules (use --package-lock-only)
  npm i --package-lock-only --no-audit --prefer-offline --no-fund >/dev/null 2>&1 || {
    echo 'warning: regenerating package-lock.json failed' >&2
    # continue to attempt install below
  }
fi
# Install dependencies: use npm ci when lockfile present and npm >=7, otherwise npm i
if [ -f package-lock.json ] && [ "${NPM_MAJOR:-0}" -ge 7 ]; then
  npm ci --no-audit --prefer-offline --no-fund || { echo 'npm ci failed' >&2; exit 4; }
else
  if [ -f package-lock.json ] && [ "${NPM_MAJOR:-0}" -lt 7 ]; then
    echo "npm v${NPM_MAJOR} <7: falling back to npm i (lockfile present)" >&2
  fi
  npm i --no-audit --prefer-offline --no-fund || { echo 'npm i failed' >&2; exit 5; }
fi
# Verify required modules loadable
node -e "require('express'); require('dotenv');" >/dev/null 2>&1 || { echo 'dependency verification failed' >&2; exit 6; }
# Success
echo 'dependencies installed and verified'
