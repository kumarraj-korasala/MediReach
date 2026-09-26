// server.js — MediReach Node.js Express API Gateway
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// ── Middlewares ───────────────────────────────────────────────
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));

// ── Route Bindings ────────────────────────────────────────────
app.use('/api/auth', require('./routes/auth'));
app.use('/api/sync', require('./routes/sync'));
app.use('/api/vitals', require('./routes/vitals'));
app.use('/api/patients', require('./routes/patients'));
app.use('/api/referrals', require('./routes/referrals'));
app.use('/api/appointments', require('./routes/appointments'));
app.use('/api/medicines', require('./routes/medicines'));
app.use('/api/facilities', require('./routes/facilities'));
app.use('/api/diagnostics', require('./routes/diagnostics'));
app.use('/api/abha', require('./routes/abha'));

// ── Health Check & System Status ──────────────────────────────
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    platform: 'MediReach API Gateway',
    version: '1.0.0',
    orchestrator: 'Node.js Express',
    connected_services: {
      python_ml_microservice: process.env.PYTHON_ML_SERVICE_URL || 'http://localhost:8001',
      webrtc_signaling_server: 'http://localhost:8000',
      cloud_database: 'Supabase PostgreSQL',
      push_messaging: 'Firebase Cloud Messaging (FCM)',
    },
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// ── Error Handling Middleware ─────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[GATEWAY UNCAUGHT ERROR]', err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal Gateway Error',
    error: err.message,
  });
});

// ── Start Server with WebSocket Proxy to Python Signaling ──────────
const http = require('http');
const net = require('net');

const server = http.createServer(app);

// Proxy WebSocket upgrade requests (/ws/calls) directly to Python signaling server (port 8000)
server.on('upgrade', (req, socket, head) => {
  if (req.url && (req.url.startsWith('/ws') || req.url.startsWith('/ws/calls'))) {
    const target = net.connect(8000, '127.0.0.1', () => {
      let raw = `${req.method} ${req.url} HTTP/${req.httpVersion}\r\n`;
      for (let i = 0; i < req.rawHeaders.length; i += 2) {
        const key = req.rawHeaders[i];
        const val = req.rawHeaders[i + 1];
        if (key.toLowerCase() === 'host') {
          raw += `Host: 127.0.0.1:8000\r\n`;
        } else {
          raw += `${key}: ${val}\r\n`;
        }
      }
      raw += '\r\n';
      target.write(raw);
      if (head && head.length) target.write(head);
      socket.pipe(target);
      target.pipe(socket);
    });

    target.on('error', (err) => {
      console.error('[WS PROXY ERROR]', err.message);
      socket.destroy();
    });
    socket.on('error', () => {
      target.destroy();
    });
  } else {
    socket.destroy();
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`====================================================`);
  console.log(`🚀 MediReach Node.js API Gateway running on port ${PORT}`);
  console.log(`📡 Unified REST Base URL: http://localhost:${PORT}/api`);
  console.log(`📹 WebRTC Signaling Proxied: /ws/calls -> Python :8000`);
  console.log(`🐍 Python ML Microservice: ${process.env.PYTHON_ML_SERVICE_URL || 'http://localhost:8001'}`);
  console.log(`====================================================`);
});

