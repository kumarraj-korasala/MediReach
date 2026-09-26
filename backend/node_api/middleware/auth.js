// middleware/auth.js — JWT & Role-Based Access Control Middleware
const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'medireach_super_secret_production_key_2026';

/**
 * Verify JWT Bearer token
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    // If no token, allow demo header or assign default guest/worker role in development
    if (process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
      req.user = {
        id: req.headers['x-user-id'] || 'usr-worker-01',
        role: req.headers['x-user-role'] || 'health_worker',
        name: 'ASHA Worker (Field)',
      };
      return next();
    }
    return res.status(401).json({ success: false, message: 'Authentication token required.' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Invalid or expired token.' });
    }
    req.user = user;
    next();
  });
}

/**
 * Role-Based Access Guard Middleware
 * @param  {...string} allowedRoles Allowed role names
 */
function requireRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Forbidden: Access restricted to roles [${allowedRoles.join(', ')}]. Current role: ${req.user ? req.user.role : 'none'}`,
      });
    }
    next();
  };
}

module.exports = { authenticateToken, requireRoles, JWT_SECRET };
