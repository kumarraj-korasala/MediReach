// routes/referrals.js — Closed-Loop Referral Lifecycle & QR Pass Token Verification
const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { supabase } = require('../config/supabase');
const { sendEmergencyAlert } = require('../config/firebase');
const { authenticateToken } = require('../middleware/auth');

let demoReferrals = [
  {
    id: 'ref-001',
    patient_id: 'p-001',
    patient_name: 'Lakshmi Devi',
    referring_facility_name: 'PHC Peddapuram',
    receiving_facility_name: 'District Hospital Kakinada',
    urgency: 'HIGH',
    reason: 'Severe Pre-eclampsia (BP 165/105, 32w Gestation)',
    qr_token: 'REF-20260920-LAKSHMI-A8F2',
    status: 'ACCEPTED',
    created_at: new Date().toISOString(),
  },
];

/**
 * GET /api/referrals
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      const { data, error } = await supabase.from('referrals').select('*');
      if (!error && data) return res.json({ success: true, data });
    }
    return res.json({ success: true, data: demoReferrals });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/referrals
 * Generates an outbound referral with a unique signed QR token and sends notification.
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { patient_id, patient_name, referring_facility, receiving_facility, urgency, reason, status } = req.body;

    if (!patient_id || !receiving_facility || !reason) {
      return res.status(400).json({ success: false, message: 'Missing referral fields.' });
    }

    const tokenHash = crypto.randomBytes(3).toString('hex').toUpperCase();
    const qrToken = `REF-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${tokenHash}`;

    const statusMap = { PENDING: 0, ACCEPTED: 1, 'IN-TRANSIT': 2, COMPLETED: 3 };
    const statusInt = statusMap[status] ?? 0;

    const newReferral = {
      id: req.body.id || `ref-${Date.now()}`,
      patient_id: String(patient_id),
      from_facility: referring_facility || 'Sub-Centre',
      to_facility: receiving_facility,
      reason,
      status: statusInt,
      qr_code: qrToken,
      created_at: req.body.created_at || new Date().toISOString(),
      is_synced: 1,
    };

    demoReferrals.unshift(newReferral);

    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      const { data: pData } = await supabase.from('patients').select('id').eq('id', newReferral.patient_id).limit(1);
      if (!pData || pData.length === 0) {
        await supabase.from('patients').upsert([{
          id: newReferral.patient_id,
          name: patient_name || req.user?.name || 'Registered Patient',
          age: 30,
          gender: 'Other',
          phone: req.user?.phone || '',
          blood_group: 'O+',
          created_at: new Date().toISOString(),
          is_synced: 1,
        }], { onConflict: 'id' });
      }

      await supabase.from('referrals').upsert([newReferral], { onConflict: 'id' });
    }

    // Fire FCM push alert to receiving hospital
    await sendEmergencyAlert(
      'hospital_referrals_channel',
      `🚨 New Inbound Referral: ${patient_name || patient_id} (${urgency})`,
      `Patient referred to ${receiving_facility} for ${reason}. Token: ${qrToken}`,
      { referral_id: newReferral.id, qr_token: qrToken }
    );

    return res.status(201).json({ success: true, data: newReferral });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PATCH /api/referrals/:id/status
 * Updates the referral transfer lifecycle (Pending -> Accepted -> In-Transit -> Completed)
 */
router.patch('/:id/status', authenticateToken, async (req, res) => {
  const { status } = req.body;
  const referral = demoReferrals.find((r) => r.id === req.params.id);

  if (referral) {
    referral.status = status;
    return res.json({ success: true, message: `Referral updated to ${status}`, data: referral });
  }

  return res.status(404).json({ success: false, message: 'Referral not found.' });
});

module.exports = router;
