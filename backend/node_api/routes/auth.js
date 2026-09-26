// routes/auth.js — Professional ABDM-Aligned Authentication Manager
// Features: ABHA ID uniqueness, shared rural family phone support, zero dummy users, multi-identifier login.

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { supabase } = require('../config/supabase');
const { JWT_SECRET } = require('../middleware/auth');

// In-memory user pool (strictly for registered users when cloud DB is offline)
// NO dummy mock users — starts completely clean
const registeredUsers = [];

/**
 * Standardize ABHA ID for consistent matching
 */
function normalizeAbha(id) {
  if (!id) return '';
  const clean = id.trim();
  if (clean.includes('@')) return clean.toLowerCase();
  const digits = clean.replace(/\D/g, '');
  if (digits.length === 14) {
    return `${digits.slice(0, 2)}-${digits.slice(2, 6)}-${digits.slice(6, 10)}-${digits.slice(10, 14)}`;
  }
  return clean;
}

/**
 * Helper to normalize role
 */
function normalizeRole(role) {
  const raw = (role || '').toLowerCase().trim();
  if (raw.includes('admin') || raw.includes('superintendent')) return 'facility_admin';
  if (raw.includes('doc')) return 'doctor';
  if (raw.includes('anm') || raw.includes('asha') || raw.includes('nurse') || raw.includes('worker')) return 'health_worker';
  return 'patient';
}

/**
 * POST /api/auth/signup
 * Enforces ABHA ID & Username uniqueness while permitting shared rural family mobile numbers.
 */
router.post('/signup', async (req, res) => {
  try {
    const { username, name, phone, password, role, abha_id } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'Username and password are required.' });
    }

    const cleanUsername = username.toLowerCase().trim();
    const cleanAbha = normalizeAbha(abha_id);
    const mappedRole = normalizeRole(role);

    // 1. Check for duplicate Username across cloud DB and memory pool
    let usernameConflict = false;
    let abhaConflict = false;

    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      try {
        const { data: userRows } = await supabase
          .from('users')
          .select('id, username, abha_id')
          .eq('username', cleanUsername);

        if (userRows && userRows.length > 0) {
          usernameConflict = true;
        }

        if (cleanAbha) {
          const { data: abhaRows } = await supabase
            .from('users')
            .select('id, username, abha_id')
            .eq('abha_id', cleanAbha);

          if (abhaRows && abhaRows.length > 0) {
            abhaConflict = true;
          }
        }
      } catch (dbErr) {
        console.warn('[AUTH SIGNUP CONFLICT CHECK WARNING]:', dbErr.message);
      }
    }

    // Also check memory pool
    if (registeredUsers.some(u => u.username === cleanUsername)) {
      usernameConflict = true;
    }
    if (cleanAbha && registeredUsers.some(u => u.abha_id && normalizeAbha(u.abha_id) === cleanAbha)) {
      abhaConflict = true;
    }

    if (usernameConflict) {
      return res.status(409).json({
        success: false,
        message: `Username "${username}" is already registered. Please choose another username or log in.`,
      });
    }

    if (abhaConflict) {
      return res.status(409).json({
        success: false,
        message: `An account is already linked to ABHA ID "${cleanAbha}". Each ABHA ID is unique; please log in using this ABHA ID.`,
      });
    }

    // Rural Architecture: Phone numbers are NOT checked for conflict because
    // entire rural families frequently share a single mobile device.

    const userId = `usr-${Date.now()}`;
    const newUser = {
      id: userId,
      username: cleanUsername,
      name: name?.trim() || cleanUsername,
      phone: phone?.trim() || '',
      role: mappedRole,
      password: password,
      abha_id: cleanAbha,
      created_at: new Date().toISOString(),
    };

    // Save to Supabase if connected
    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      try {
        await supabase.from('users').upsert([newUser]);
      } catch (dbErr) {
        console.warn('[AUTH SIGNUP DB EXCEPTION]:', dbErr.message);
      }
    }

    registeredUsers.push(newUser);

    const token = jwt.sign(
      { id: newUser.id, username: newUser.username, role: newUser.role, name: newUser.name, abha_id: newUser.abha_id },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(201).json({
      success: true,
      message: 'Account created successfully with unique ABHA identity.',
      token,
      user: {
        id: newUser.id,
        username: newUser.username,
        name: newUser.name,
        role: newUser.role,
        phone: newUser.phone,
        abha_id: newUser.abha_id,
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/auth/login
 * Supports Multi-Identifier login: ABHA ID, Mobile Phone, or Username.
 */
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username) {
      return res.status(400).json({ success: false, message: 'ABHA ID, Mobile Number, or Username is required.' });
    }

    const cleanInput = username.toLowerCase().trim();
    const cleanAbha = normalizeAbha(username);
    let foundUser = null;

    // 1. Query Supabase across username, phone, and abha_id
    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      try {
        const orConditions = [
          `username.eq.${cleanInput}`,
          `phone.eq.${username.trim()}`,
        ];
        if (cleanAbha) {
          orConditions.push(`abha_id.eq.${cleanAbha}`);
          orConditions.push(`abha_id.eq.${username.trim()}`);
        }

        const { data, error } = await supabase
          .from('users')
          .select('*')
          .or(orConditions.join(','))
          .limit(1);

        if (!error && data && data.length > 0) {
          foundUser = data[0];
        }
      } catch (dbErr) {
        console.warn('[AUTH LOGIN DB LOOKUP EXCEPTION]:', dbErr.message);
      }
    }

    // 2. Fallback to memory pool
    if (!foundUser) {
      foundUser = registeredUsers.find(u => {
        const uAbha = normalizeAbha(u.abha_id);
        return (
          u.username === cleanInput ||
          u.phone === username.trim() ||
          (cleanAbha && uAbha === cleanAbha)
        );
      });
    }

    // Strict validation: Reject unknown credentials
    if (!foundUser) {
      return res.status(401).json({
        success: false,
        message: `Account not found for "${username}". Verify your ABHA ID, phone, or username, or sign up.`,
      });
    }

    // Password verification
    if (foundUser.password && password && foundUser.password !== password) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password. Please try again.',
      });
    }

    const token = jwt.sign(
      { id: foundUser.id, username: foundUser.username, role: foundUser.role, name: foundUser.name, abha_id: foundUser.abha_id },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.json({
      success: true,
      message: 'Login successful.',
      token,
      user: {
        id: foundUser.id,
        username: foundUser.username,
        name: foundUser.name,
        role: foundUser.role,
        phone: foundUser.phone || '',
        abha_id: foundUser.abha_id || '',
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
