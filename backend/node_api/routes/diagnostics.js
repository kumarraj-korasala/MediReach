// routes/diagnostics.js — Laboratory Test Reports & Diagnostics Registry
const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

let demoReports = [
  {
    id: 'diag-001',
    patient_id: 'p-001',
    test_type: 'Hemoglobin (Hb)',
    result: '10.2',
    unit: 'g/dL',
    reference_range: '12.0 - 15.5',
    status: 'BORDERLINE',
    recorded_at: '2026-09-18T10:00:00.000Z',
  },
  {
    id: 'diag-002',
    patient_id: 'p-001',
    test_type: 'Random Blood Sugar',
    result: '118',
    unit: 'mg/dL',
    reference_range: '70 - 140',
    status: 'NORMAL',
    recorded_at: '2026-09-18T10:05:00.000Z',
  },
];

router.get('/', authenticateToken, (req, res) => {
  const { patient_id } = req.query;
  let list = demoReports;
  if (patient_id) {
    list = list.filter((r) => r.patient_id === patient_id);
  }
  return res.json({ success: true, data: list });
});

router.post('/', authenticateToken, (req, res) => {
  const { patient_id, test_type, result, unit, reference_range, status } = req.body;
  const newReport = {
    id: req.body.id || `diag-${Date.now()}`,
    patient_id: patient_id || 'p-001',
    test_type: test_type || 'Blood Test',
    result: result || 'Normal',
    unit: unit || '',
    reference_range: reference_range || '',
    status: status || 'NORMAL',
    recorded_at: new Date().toISOString(),
    is_synced: true,
  };
  demoReports.unshift(newReport);
  return res.status(201).json({ success: true, data: newReport });
});

module.exports = router;
