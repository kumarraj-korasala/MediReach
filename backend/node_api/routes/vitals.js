// routes/vitals.js — Vitals Recording with Internal Python ML Triage & Firebase Alert Orchestration
const express = require('express');
const router = express.Router();
const axios = require('axios');
const { supabase } = require('../config/supabase');
const { sendEmergencyAlert } = require('../config/firebase');
const { authenticateToken } = require('../middleware/auth');

const PYTHON_ML_URL = process.env.PYTHON_ML_SERVICE_URL || 'http://localhost:8001';

/**
 * POST /api/vitals
 * 1. Takes clinical vitals from health worker / patient.
 * 2. Calls internal Python ML microservice (:8001/triage) for risk scoring.
 * 3. Persists enriched vitals record to Supabase.
 * 4. If HIGH or EMERGENCY, dispatches instant FCM alert to receiving hospital triage.
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const {
      patient_id,
      age = 30,
      systolic_bp,
      diastolic_bp,
      pulse_rate,
      temperature,
      spo2,
      blood_glucose = 0,
      is_pregnant = false,
      pregnancy_weeks = 0,
      symptoms = [],
    } = req.body;

    if (!patient_id || !systolic_bp || !diastolic_bp || !spo2) {
      return res.status(400).json({
        success: false,
        message: 'Missing required vitals parameters (patient_id, systolic_bp, diastolic_bp, spo2).',
      });
    }

    // ── 1. Call Internal Python ML Microservice ──────────────
    let triageResult = null;
    try {
      const mlResponse = await axios.post(`${PYTHON_ML_URL}/triage`, {
        age: parseInt(age),
        systolic_bp: parseInt(systolic_bp),
        diastolic_bp: parseInt(diastolic_bp),
        pulse_rate: parseInt(pulse_rate || 72),
        temperature: parseFloat(temperature || 37.0),
        spo2: parseInt(spo2),
        blood_glucose: parseFloat(blood_glucose || 0),
        is_pregnant: Boolean(is_pregnant),
        pregnancy_weeks: parseInt(pregnancy_weeks || 0),
        symptoms: Array.isArray(symptoms) ? symptoms : [],
      }, { timeout: 3500 });

      if (mlResponse.data && mlResponse.data.data) {
        triageResult = mlResponse.data.data;
      }
    } catch (mlErr) {
      console.warn(`[PYTHON ML SERVICE] Warning: Failed to reach Python ML at ${PYTHON_ML_URL}/triage (${mlErr.message}). Using gateway fallback rules.`);
      // Gateway fallback rules
      const isEmergency = spo2 < 90 || (is_pregnant && systolic_bp >= 160);
      triageResult = {
        risk_level: isEmergency ? 'EMERGENCY' : (systolic_bp >= 140 ? 'HIGH' : 'LOW'),
        confidence: 0.90,
        flag: isEmergency ? 'Gateway Fallback Emergency Trigger' : 'Standard Fallback Score',
        recommended_action: isEmergency ? 'Immediate specialist evaluation required.' : 'Routine follow-up.',
        eval_source: 'gateway_safety_rules_fallback',
        requires_immediate_transfer: isEmergency,
      };
    }

    const riskMap = { LOW: 0, MODERATE: 1, HIGH: 2, EMERGENCY: 3 };
    const riskLevelInt = riskMap[triageResult.risk_level] ?? 0;

    const vitalsRecord = {
      id: req.body.id || `vit_${Date.now()}`,
      patient_id: String(patient_id),
      bp_systolic: parseFloat(systolic_bp) || null,
      bp_diastolic: parseFloat(diastolic_bp) || null,
      pulse: parseFloat(pulse_rate) || null,
      temperature: parseFloat(temperature) || null,
      blood_sugar: parseFloat(blood_glucose) || null,
      hemoglobin: parseFloat(req.body.hemoglobin) || null,
      weight: parseFloat(req.body.weight) || null,
      height: parseFloat(req.body.height) || null,
      risk_level: riskLevelInt,
      recorded_at: req.body.recorded_at || new Date().toISOString(),
      is_synced: 1,
    };

    // ── 2. Persist to Supabase if live ─────────────────────────
    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      // Foreign key check
      const { data: pData } = await supabase.from('patients').select('id').eq('id', vitalsRecord.patient_id).limit(1);
      if (!pData || pData.length === 0) {
        await supabase.from('patients').upsert([{
          id: vitalsRecord.patient_id,
          name: req.user?.name || 'Registered Patient',
          age: parseInt(age) || 30,
          gender: 'Other',
          phone: req.user?.phone || '',
          blood_group: 'O+',
          created_at: new Date().toISOString(),
          is_synced: 1,
        }], { onConflict: 'id' });
      }

      await supabase.from('vitals').upsert([vitalsRecord], { onConflict: 'id' });
    }

    // ── 3. High-Priority FCM Push Notification ─────────────────
    if (triageResult.risk_level === 'HIGH' || triageResult.risk_level === 'EMERGENCY') {
      await sendEmergencyAlert(
        'emergency_triage_channel',
        `🚨 ${triageResult.risk_level} Triage Alert: Patient ${patient_id}`,
        `${triageResult.flag} — BP: ${systolic_bp}/${diastolic_bp}, SpO2: ${spo2}%. Action: ${triageResult.recommended_action}`,
        {
          patient_id: String(patient_id),
          risk_level: triageResult.risk_level,
          triage_data: JSON.stringify(triageResult),
        }
      );
    }

    return res.status(201).json({
      success: true,
      message: 'Vitals successfully evaluated and recorded.',
      data: {
        record: vitalsRecord,
        triage: triageResult,
      },
    });
  } catch (err) {
    console.error('[VITALS RECORD ERROR]', err);
    return res.status(500).json({
      success: false,
      message: 'Internal server error processing vitals.',
      error: err.message,
    });
  }
});

module.exports = router;
