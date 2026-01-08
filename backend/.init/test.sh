#!/usr/bin/env bash
set -euo pipefail
# Run the architect-provided test setup: create __tests__/health.test.js and run npm test
WORKSPACE="/home/kavia/workspace/code-generation/simple-tic-tac-toe-51780-51791/backend"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/__tests__"
cat > "$WORKSPACE/__tests__/health.test.js" <<'TEST'
require('dotenv').config();
const http = require('http');
const app = require('../src/index.js');
const PORT = Number(process.env.PORT || 3000);
let stopped = false;
async function waitForHealth(port, tries = 20, delay = 200) {
  for (let i = 0; i < tries; i++) {
    try {
      await new Promise((resolve, reject) => {
        const req = http.get({ hostname: '127.0.0.1', port, path: '/health', timeout: 1000 }, res => {
          let data = '';
          res.on('data', c => data += c);
          res.on('end', () => {
            // fully consumed body before checking
            if (res.statusCode === 200) return resolve(data);
            reject(new Error('non-200'));
          });
        });
        req.on('error', reject);
        req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
      });
      return;
    } catch (e) {
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw new Error('health check timeout');
}
let serverObj;
beforeAll(async () => {
  // start should return a promise that resolves when server starts (or an object with server)
  serverObj = await app.start(PORT);
  await waitForHealth(PORT, 20, 200);
});
afterAll(async () => {
  // ensure cleanup runs; tolerate missing stop implementation
  if (!stopped) {
    try { await app.stop(); } catch (e) { /* ignore */ }
    stopped = true;
  }
});
test('health endpoint responds with ok', async () => {
  const body = await new Promise((resolve, reject) => {
    const req = http.get({ hostname: '127.0.0.1', port: PORT, path: '/health' }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve({ status: res.statusCode, body: d }));
    });
    req.on('error', reject);
  });
  expect(body.status).toBe(200);
  const parsed = JSON.parse(body.body);
  expect(parsed.status).toBe('ok');
}, 20000);
TEST

# Run tests using local jest via npm script for portability
npm run test --silent || { echo 'tests failed' >&2; exit 5; }
