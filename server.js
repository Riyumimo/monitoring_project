const path = require('path');
const fs = require('fs');
const express = require('express');

const app = express();
const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';
const WEB_ROOT = path.join(__dirname, 'build', 'web');
const INDEX_FILE = path.join(WEB_ROOT, 'index.html');

if (!fs.existsSync(INDEX_FILE)) {
  console.error(`Web build not found at ${WEB_ROOT}`);
  console.error('Run "flutter build web --release" first.');
  process.exit(1);
}

app.disable('x-powered-by');

app.post('/api/log', express.text({ type: '*/*', limit: '1mb' }), (req, res) => {
  const body = typeof req.body === 'string' ? req.body : '';
  console.log('\n[CLIENT ERROR] ' + new Date().toISOString());
  console.log(body);
  res.status(204).end();
});

app.use((req, res, next) => {
  res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.set('Pragma', 'no-cache');
  res.set('Expires', '0');
  next();
});

app.use(express.static(WEB_ROOT, { index: false }));

app.use((req, res, next) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return next();
  }
  if (path.extname(req.path)) {
    return next();
  }
  res.sendFile(INDEX_FILE);
});

app.use((req, res) => {
  res.status(404).json({ error: 'Not found', path: req.path });
});

app.listen(PORT, HOST, () => {
  console.log(`Geoterra Monitoring web server running at http://${HOST}:${PORT}`);
  console.log(`Serving static files from ${WEB_ROOT}`);
});
