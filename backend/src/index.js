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
