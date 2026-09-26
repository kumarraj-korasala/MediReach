// routes/appointments.js — Appointment Scheduling & Token Queue (Connected to Supabase)
const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

let fallbackAppointments = [];

/**
 * GET /api/appointments
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { patient_id } = req.query;

    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      let query = supabase.from('appointments').select('*').order('scheduled_at', { ascending: false });
      if (patient_id) {
        query = query.eq('patient_id', patient_id);
      }
      const { data, error } = await query;
      if (!error && data) {
        return res.json({ success: true, data });
      }
    }

    let list = fallbackAppointments;
    if (patient_id) {
      list = list.filter((a) => a.patient_id === patient_id);
    }
    return res.json({ success: true, data: list });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/appointments
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const {
      id,
      patient_id,
      doctor_name,
      facility,
      facility_name,
      facility_type,
      specialty,
      scheduled_at,
      appointment_date,
      appointment_time,
      fee,
      status,
    } = req.body;

    if (!patient_id) {
      return res.status(400).json({ success: false, message: 'patient_id is required.' });
    }

    const scheduledTime = scheduled_at || (appointment_date ? `${appointment_date}T${appointment_time || '10:00:00'}` : new Date().toISOString());

    const apptRecord = {
      id: id || `apt-${Date.now()}`,
      patient_id: String(patient_id),
      doctor_name: doctor_name || 'Dr. Medical Officer',
      facility: facility || facility_name || 'Primary Health Center',
      facility_type: facility_type || 'PHC',
      specialty: specialty || 'General Medicine',
      scheduled_at: scheduledTime,
      fee: parseFloat(String(fee || '0').replace(/[^\d.-]/g, '')) || 0,
      status: status || 'Scheduled',
      is_synced: 1,
    };

    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      // Foreign-key guarantee: verify patient exists in Supabase
      const { data: pData } = await supabase.from('patients').select('id').eq('id', apptRecord.patient_id).limit(1);
      if (!pData || pData.length === 0) {
        // Auto-provision patient entry
        await supabase.from('patients').upsert([{
          id: apptRecord.patient_id,
          name: req.user?.name || 'Registered Patient',
          age: 30,
          gender: 'Other',
          phone: req.user?.phone || '',
          blood_group: 'O+',
          created_at: new Date().toISOString(),
          is_synced: 1,
        }], { onConflict: 'id' });
      }

      const { error: insertErr } = await supabase.from('appointments').upsert([apptRecord], { onConflict: 'id' });
      if (insertErr) {
        console.error('[APPOINTMENT SUPABASE ERROR]', insertErr.message);
        return res.status(500).json({ success: false, error: insertErr.message });
      }
    }

    fallbackAppointments.unshift(apptRecord);
    return res.status(201).json({ success: true, data: apptRecord });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
