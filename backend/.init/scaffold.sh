#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-tic-tac-toe-51780-51791/backend"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/src"
PKG_JSON="$WORKSPACE/package.json"
PKG_LOCK="$WORKSPACE/package-lock.json"
if [ ! -f "$PKG_JSON" ]; then
  cat > "$PKG_JSON" <<'JSON'
{
  "name": "simple-tic-tac-toe",
  "version": "0.1.0",
  "private": true,
  "engines": { "node": ">=18" },
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon --watch src --exec node src/index.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.22",
    "jest": "^29.6.1"
  }
}
JSON
fi
if [ ! -f "$PKG_LOCK" ]; then
  npm i --package-lock-only --no-audit --no-fund || { echo 'package-lock generation failed' >&2; exit 6; }
fi
if [ ! -f "$WORKSPACE/src/index.js" ]; then
  cat > "$WORKSPACE/src/index.js" <<'NODE'
const express = require('express');
require('dotenv').config();
const app = express();
app.use(express.json());
const PORT = process.env.PORT || 3000;
let server = null;
let games = {};
app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.post('/game', (req, res) => {
  const id = Date.now().toString();
  games[id] = { board: Array(9).fill(null), turn: 'X', id };
  res.status(201).json(games[id]);
});
app.get('/game/:id', (req, res) => {
  const g = games[req.params.id];
  if (!g) return res.status(404).json({ error: 'not found' });
  res.json(g);
});
function start(listenPort = PORT) {
  if (server) return Promise.resolve(server);
  return new Promise((resolve, reject) => {
    server = app.listen(listenPort, () => resolve(server));
    server.on('error', err => reject(err));
  });
}
function stop() {
  if (!server) return Promise.resolve();
  return new Promise(resolve => server.close(() => { server = null; resolve(); }));
}
process.on('SIGTERM', () => { try { stop().finally(() => process.exit(0)); } catch (e) { process.exit(0); } });
process.on('SIGINT', () => { try { stop().finally(() => process.exit(0)); } catch (e) { process.exit(0); } });
process.on('unhandledRejection', (err) => { console.error('unhandledRejection', err); process.exit(1); });
module.exports = { start, stop };
if (require.main === module) start();
NODE
fi
if [ ! -f "$WORKSPACE/.env" ]; then echo "PORT=3000" > "$WORKSPACE/.env"; fi
if [ ! -f "$WORKSPACE/.gitignore" ]; then cat > "$WORKSPACE/.gitignore" <<'GI'
node_modules
.env
GI
fi
if [ ! -w "$WORKSPACE" ]; then sudo chown "$(id -u):$(id -g)" "$WORKSPACE" || true; fi
