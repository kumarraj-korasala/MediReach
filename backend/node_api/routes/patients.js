// routes/patients.js — Patient Management with ABHA Deduplication & RBAC Filtering
const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

// In-memory patient store for offline/local development without pre-seeded dummy records
let activePatients = [];

/**
 * Standardize ABHA ID
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
 * GET /api/patients
 * Lists patients accessible to the current user (Role-based scoping)
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const isCitizen = req.user.role === 'patient';
    const userAbha = normalizeAbha(req.user.abha_id);

    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      let query = supabase.from('patients').select('*');
      if (isCitizen && userAbha) {
        query = query.eq('abha_id', userAbha);
      } else if (isCitizen) {
        query = query.or(`phone.eq.${req.user.phone},id.eq.${req.user.id}`);
      }
      const { data, error } = await query;
      if (!error && data) {
        return res.json({ success: true, data });
      }
    }

    // Scoped memory fallback
    if (isCitizen) {
      const filtered = activePatients.filter(p => {
        const pAbha = normalizeAbha(p.abha_id);
        return (userAbha && pAbha === userAbha) || p.phone === req.user.phone || p.id === req.user.id;
      });
      return res.json({ success: true, data: filtered });
    }

    return res.json({ success: true, data: activePatients });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/patients
 * Registers or updates a patient with strict ABHA deduplication.
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const {
      name,
      age,
      gender = 'Female',
      phone = '',
      blood_group,
      bloodGroup,
      abha_id,
      abhaId,
      is_pregnant,
      isPregnant,
      pregnancy_week,
      pregnancyWeek,
    } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Patient name is required.' });
    }

    const cleanAbha = normalizeAbha(abha_id || abhaId);

    // 1. Deduplication check: does a patient with this ABHA already exist?
    let existingPatient = null;
    if (cleanAbha) {
      if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
        const { data } = await supabase.from('patients').select('*').eq('abha_id', cleanAbha).limit(1);
        if (data && data.length > 0) existingPatient = data[0];
      }
      if (!existingPatient) {
        existingPatient = activePatients.find(p => normalizeAbha(p.abha_id) === cleanAbha);
      }
    }

    if (existingPatient) {
      // Update existing record without creating duplicate ID
      const updated = {
        ...existingPatient,
        name: name.trim() || existingPatient.name,
        age: parseInt(age) || existingPatient.age || 30,
        gender: gender || existingPatient.gender,
        phone: (phone || '').trim() || existingPatient.phone,
        blood_group: blood_group || bloodGroup || existingPatient.blood_group || 'O+',
        is_pregnant: (is_pregnant === 1 || is_pregnant === true || isPregnant === true) ? 1 : 0,
        pregnancy_week: pregnancy_week || pregnancyWeek || existingPatient.pregnancy_week || null,
        created_at: existingPatient.created_at || new Date().toISOString(),
        is_synced: 1,
      };

      if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
        await supabase.from('patients').upsert([updated], { onConflict: 'id' });
      }

      const idx = activePatients.findIndex(p => p.id === existingPatient.id);
      if (idx >= 0) activePatients[idx] = updated;

      return res.status(200).json({
        success: true,
        message: 'Patient record merged under existing unique ABHA ID.',
        data: updated,
        is_merged: true,
      });
    }

    const newPatient = {
      id: req.body.id || `p-${Date.now()}`,
      name: name.trim(),
      age: parseInt(age) || 30,
      gender: gender || 'Female',
      phone: (phone || '').trim(),
      blood_group: blood_group || bloodGroup || 'O+',
      abha_id: cleanAbha || null,
      is_pregnant: (is_pregnant === 1 || is_pregnant === true || isPregnant === true) ? 1 : 0,
      pregnancy_week: pregnancy_week || pregnancyWeek || null,
      created_at: req.body.created_at || new Date().toISOString(),
      is_synced: 1,
    };

    activePatients.unshift(newPatient);

    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      await supabase.from('patients').upsert([newPatient], { onConflict: 'id' });
    }

    return res.status(201).json({ success: true, data: newPatient, is_merged: false });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
