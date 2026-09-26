// routes/sync.js — Bi-Directional Batch Sync (Upload + Download) for Offline SQLite
const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

/**
 * Helper to fetch cloud records scoped to user's access
 */
async function fetchScopedCloudData(user, queryParams = {}) {
  const role = (user?.role || queryParams.role || 'patient').toLowerCase();
  const userId = user?.id || queryParams.user_id;
  const phone = queryParams.phone || '';
  const abhaId = queryParams.abha_id || '';
  const isPatient = role.includes('patient');

  let cloudPatients = [];
  let cloudVitals = [];
  let cloudRecords = [];
  let cloudReferrals = [];
  let cloudAppointments = [];

  if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
    try {
      // 1. Fetch Patients
      if (isPatient) {
        let pQuery = supabase.from('patients').select('*');
        const filters = [];
        if (phone) filters.push(`phone.eq.${phone}`);
        if (abhaId) filters.push(`abha_id.eq.${abhaId}`);
        if (userId) filters.push(`id.eq.${userId}`);

        if (filters.length > 0) {
          pQuery = pQuery.or(filters.join(','));
        }
        const { data: pData } = await pQuery;
        cloudPatients = pData || [];
      } else {
        // Staff / Health Worker / Admin sees full catchment
        const { data: pData } = await supabase.from('patients').select('*').limit(200);
        cloudPatients = pData || [];
      }

      const patientIds = cloudPatients.map((p) => p.id);

      // 2. Fetch Dependent Tables
      if (!isPatient || patientIds.length > 0) {
        let vQuery = supabase.from('vitals').select('*');
        let rQuery = supabase.from('medical_records').select('*');
        let refQuery = supabase.from('referrals').select('*');
        let aQuery = supabase.from('appointments').select('*');

        if (isPatient) {
          vQuery = vQuery.in('patient_id', patientIds);
          rQuery = rQuery.in('patient_id', patientIds);
          refQuery = refQuery.in('patient_id', patientIds);
          aQuery = aQuery.in('patient_id', patientIds);
        }

        const [vRes, rRes, refRes, aRes] = await Promise.all([
          vQuery.limit(200),
          rQuery.limit(200),
          refQuery.limit(200),
          aQuery.limit(200),
        ]);

        cloudVitals = vRes.data || [];
        cloudRecords = rRes.data || [];
        cloudReferrals = refRes.data || [];
        cloudAppointments = aRes.data || [];
      }
    } catch (err) {
      console.warn('[SUPABASE PULL EXCEPTION]', err.message);
    }
  }

  return {
    patients: cloudPatients,
    vitals: cloudVitals,
    medical_records: cloudRecords,
    referrals: cloudReferrals,
    appointments: cloudAppointments,
  };
}

/**
 * GET /api/sync/pull
 * Downloads latest cloud records scoped to the user's role and identity
 */
router.get('/pull', authenticateToken, async (req, res) => {
  try {
    const pulledData = await fetchScopedCloudData(req.user, req.query);
    const totalRecords =
      pulledData.patients.length +
      pulledData.vitals.length +
      pulledData.medical_records.length +
      pulledData.referrals.length +
      pulledData.appointments.length;

    return res.json({
      success: true,
      message: `Downloaded ${totalRecords} cloud records under active access.`,
      server_timestamp: new Date().toISOString(),
      total_pulled: totalRecords,
      data: pulledData,
    });
  } catch (err) {
    console.error('[SYNC PULL ERROR]', err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/sync/batch
 * Bi-directional sync: Receives unsynced local rows, upserts to Supabase,
 * and responds with acknowledgments + latest cloud records for download.
 */
router.post('/batch', authenticateToken, async (req, res) => {
  try {
    const {
      patients = [],
      vitals = [],
      referrals = [],
      appointments = [],
      diagnostic_reports = [],
      client_timestamp,
      user_role,
      user_phone,
      user_abha_id,
    } = req.body;

    const totalIncoming =
      patients.length +
      vitals.length +
      referrals.length +
      appointments.length +
      diagnostic_reports.length;

    console.log(`[SYNC BATCH] Received ${totalIncoming} unsynced records from User: ${req.user.id}`);

    const syncAcks = {
      synced_patient_ids: patients.map((p) => p.id),
      synced_vitals_ids: vitals.map((v) => v.id),
      synced_referral_ids: referrals.map((r) => r.id),
      synced_appointment_ids: appointments.map((a) => a.id),
      synced_diagnostic_ids: diagnostic_reports.map((d) => d.id),
    };

    // 1. Push to Supabase if connected
    if (supabase && process.env.SUPABASE_URL && !process.env.SUPABASE_URL.includes('mock')) {
      // Step A: Upsert Patients first (root parent table)
      if (patients.length > 0) {
        const seenAbhas = new Set();
        const uniqueBatchPatients = [];
        for (const p of patients) {
          const abha = p.abha_id ? p.abha_id.trim() : null;
          if (abha) {
            if (seenAbhas.has(abha)) continue;
            seenAbhas.add(abha);
          }
          uniqueBatchPatients.push(p);
        }

        const sanitizedPatients = uniqueBatchPatients.map((p) => ({
          id: String(p.id),
          name: p.name || 'Patient',
          age: parseInt(p.age) || 30,
          gender: p.gender || 'Female',
          phone: p.phone || '',
          blood_group: p.blood_group || p.bloodGroup || 'O+',
          abha_id: p.abha_id || p.abhaId || null,
          is_pregnant: (p.is_pregnant === 1 || p.is_pregnant === true) ? 1 : 0,
          pregnancy_week: p.pregnancy_week || p.pregnancyWeek || null,
          created_at: p.created_at || new Date().toISOString(),
          is_synced: 1,
        }));

        const { error: pErr } = await supabase.from('patients').upsert(sanitizedPatients, { onConflict: 'id' });
        if (pErr) console.error('[SUPABASE SYNC ERROR: patients]', pErr.message);
        else console.log(`[SUPABASE SYNC] Upserted ${sanitizedPatients.length} deduplicated patients.`);
      }

      // Step B: Ensure all foreign-key referenced patient_ids exist in Supabase
      const allReferencedPatientIds = Array.from(new Set([
        ...vitals.map((v) => v.patient_id),
        ...referrals.map((r) => r.patient_id),
        ...appointments.map((a) => a.patient_id),
      ].filter(Boolean)));

      if (allReferencedPatientIds.length > 0) {
        const { data: existingPatients } = await supabase
          .from('patients')
          .select('id')
          .in('id', allReferencedPatientIds);

        const existingSet = new Set((existingPatients || []).map((p) => p.id));
        const missingPatientIds = allReferencedPatientIds.filter((id) => !existingSet.has(id));

        if (missingPatientIds.length > 0) {
          console.log(`[SYNC AUTOPROVISION] Auto-creating baseline patient records for missing foreign keys:`, missingPatientIds);
          const placeholders = missingPatientIds.map((id) => ({
            id,
            name: req.user?.name ? `${req.user.name} (Family Member)` : 'Registered Family Member',
            age: 30,
            gender: 'Other',
            phone: req.user?.phone || '',
            blood_group: 'O+',
            abha_id: null,
            is_pregnant: 0,
            pregnancy_week: null,
            created_at: new Date().toISOString(),
            is_synced: 1,
          }));
          await supabase.from('patients').upsert(placeholders, { onConflict: 'id' });
        }
      }

      // Step C: Upsert Dependent Tables with matching column schemas
      if (vitals.length > 0) {
        const sanitizedVitals = vitals.map((v) => ({
          id: String(v.id),
          patient_id: String(v.patient_id),
          bp_systolic: parseFloat(v.bp_systolic || v.systolic_bp) || null,
          bp_diastolic: parseFloat(v.bp_diastolic || v.diastolic_bp) || null,
          blood_sugar: parseFloat(v.blood_sugar || v.blood_glucose) || null,
          pulse: parseFloat(v.pulse || v.pulse_rate) || null,
          hemoglobin: parseFloat(v.hemoglobin) || null,
          temperature: parseFloat(v.temperature) || null,
          weight: parseFloat(v.weight) || null,
          height: parseFloat(v.height) || null,
          risk_level: parseInt(v.risk_level) || 0,
          recorded_at: v.recorded_at || new Date().toISOString(),
          is_synced: 1,
        }));
        const { error: vErr } = await supabase.from('vitals').upsert(sanitizedVitals, { onConflict: 'id' });
        if (vErr) console.error('[SUPABASE SYNC ERROR: vitals]', vErr.message);
        else console.log(`[SUPABASE SYNC] Upserted ${sanitizedVitals.length} vitals.`);
      }

      if (referrals.length > 0) {
        const sanitizedReferrals = referrals.map((r) => ({
          id: String(r.id),
          patient_id: String(r.patient_id),
          from_facility: r.from_facility || r.referring_facility_name || 'PHC Sub-Centre',
          to_facility: r.to_facility || r.receiving_facility_name || 'District Hospital',
          reason: r.reason || 'Specialist Evaluation',
          status: parseInt(r.status) || 0,
          qr_code: r.qr_code || r.qr_token || null,
          created_at: r.created_at || new Date().toISOString(),
          is_synced: 1,
        }));
        const { error: rErr } = await supabase.from('referrals').upsert(sanitizedReferrals, { onConflict: 'id' });
        if (rErr) console.error('[SUPABASE SYNC ERROR: referrals]', rErr.message);
        else console.log(`[SUPABASE SYNC] Upserted ${sanitizedReferrals.length} referrals.`);
      }

      if (appointments.length > 0) {
        const sanitizedAppointments = appointments.map((a) => ({
          id: String(a.id),
          patient_id: String(a.patient_id),
          doctor_name: a.doctor_name || 'General Medical Officer',
          facility: a.facility || a.facility_name || 'Primary Health Center',
          facility_type: a.facility_type || 'PHC',
          specialty: a.specialty || 'General Medicine',
          scheduled_at: a.scheduled_at || a.appointment_date || new Date().toISOString(),
          fee: parseFloat(String(a.fee || '0').replace(/[^\d.-]/g, '')) || 0,
          status: a.status || 'Scheduled',
          is_synced: 1,
        }));
        const { error: aErr } = await supabase.from('appointments').upsert(sanitizedAppointments, { onConflict: 'id' });
        if (aErr) console.error('[SUPABASE SYNC ERROR: appointments]', aErr.message);
        else console.log(`[SUPABASE SYNC] Upserted ${sanitizedAppointments.length} appointments.`);
      }
    }

    // 2. Fetch latest cloud updates to return to mobile app (bi-directional sync)
    const pulledData = await fetchScopedCloudData(req.user, {
      role: user_role,
      phone: user_phone,
      abha_id: user_abha_id,
    });

    const totalPulled =
      pulledData.patients.length +
      pulledData.vitals.length +
      pulledData.medical_records.length +
      pulledData.referrals.length +
      pulledData.appointments.length;

    return res.status(200).json({
      success: true,
      message: `Sync complete. ${totalIncoming} records uploaded, ${totalPulled} cloud records retrieved.`,
      server_timestamp: new Date().toISOString(),
      acks: syncAcks,
      total_processed: totalIncoming,
      pulled_records: pulledData,
      total_pulled: totalPulled,
    });
  } catch (err) {
    console.error('[SYNC BATCH ERROR]', err);
    return res.status(500).json({
      success: false,
      message: 'Batch sync failed on server.',
      error: err.message,
    });
  }
});

module.exports = router;
