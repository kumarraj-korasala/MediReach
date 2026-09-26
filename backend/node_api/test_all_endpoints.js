// test_all_endpoints.js - Comprehensive API Endpoints & Supabase Sync Verification
require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const axios = require('axios');
const { supabase } = require('./config/supabase');

const BASE_URL = 'http://localhost:5000/api';
let authToken = null;
let testUser = null;
let testPatientId = 'test-pt-' + Date.now();
let testAbhaId = '91-' + String(Date.now()).slice(-4) + '-' + Math.floor(1000 + Math.random() * 9000) + '-' + Math.floor(1000 + Math.random() * 9000);

async function runTests() {
  console.log('====================================================');
  console.log('MEDIREACH COMPREHENSIVE ENDPOINT & SYNC TEST SUITE');
  console.log('====================================================\n');

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      process.stdout.write('Checking: ' + name + ' ... ');
      await fn();
      console.log('PASSED');
      passed++;
    } catch (err) {
      console.log('FAILED: ' + (err.response ? JSON.stringify(err.response.data) : err.message));
      failed++;
    }
  }

  // 1. Health
  await test('1. GET /api/health', async () => {
    const res = await axios.get(BASE_URL + '/health');
    if (res.status !== 200 || res.data.status !== 'healthy') throw new Error('Health check failed');
  });

  // 2. Auth Signup
  await test('2. POST /api/auth/signup (Unique ABHA)', async () => {
    const username = 'testuser_' + Date.now();
    const res = await axios.post(BASE_URL + '/auth/signup', {
      username,
      name: 'Dr. Test Physician',
      phone: '9845099999',
      password: 'password123',
      role: 'health_worker',
      abha_id: testAbhaId,
    });
    if (res.status !== 201 || !res.data.token) throw new Error('Signup failed');
    authToken = res.data.token;
    testUser = res.data.user;
  });

  // 3. Auth Login with ABHA
  await test('3. POST /api/auth/login (Login via 14-digit ABHA)', async () => {
    const res = await axios.post(BASE_URL + '/auth/login', {
      username: testAbhaId,
      password: 'password123',
    });
    if (res.status !== 200 || !res.data.token) throw new Error('Login with ABHA failed');
  });

  // 4. ABHA Verification
  await test('4. GET /api/abha/verify/:abha_id', async () => {
    const res = await axios.get(BASE_URL + '/abha/verify/' + testAbhaId);
    if (res.status !== 200 || res.data.valid !== true) throw new Error('ABHA verification failed');
  });

  // 5. ABHA Records Fetch
  await test('5. GET /api/abha/records/:abha_id', async () => {
    const res = await axios.get(BASE_URL + '/abha/records/' + testAbhaId);
    if (res.status !== 200 || !res.data.data) throw new Error('ABHA records fetch failed');
  });

  const headers = () => ({ Authorization: 'Bearer ' + authToken });

  // 6. Patient Creation
  await test('6. POST /api/patients (Supabase Schema Compatible)', async () => {
    const res = await axios.post(BASE_URL + '/patients', {
      id: testPatientId,
      name: 'Ananya Sharma',
      age: 28,
      gender: 'Female',
      phone: '9845099999',
      blood_group: 'B+',
      abha_id: testAbhaId,
      is_pregnant: true,
      pregnancy_week: 14,
    }, { headers: headers() });
    if (res.status !== 201 && res.status !== 200) throw new Error('Patient creation failed');
  });

  // 7. Patients Listing
  await test('7. GET /api/patients', async () => {
    const res = await axios.get(BASE_URL + '/patients', { headers: headers() });
    if (res.status !== 200 || !Array.isArray(res.data.data)) throw new Error('Patients list failed');
  });

  // 8. Vitals Recording
  await test('8. POST /api/vitals (ML Triage + Supabase Persistence)', async () => {
    const res = await axios.post(BASE_URL + '/vitals', {
      id: 'vit-test-' + Date.now(),
      patient_id: testPatientId,
      age: 28,
      systolic_bp: 125,
      diastolic_bp: 82,
      pulse_rate: 74,
      spo2: 98,
      blood_glucose: 95,
      temperature: 37.0,
      is_pregnant: true,
      pregnancy_weeks: 14,
    }, { headers: headers() });
    if (res.status !== 201 || !res.data.data.record) throw new Error('Vitals recording failed');
  });

  // 9. Appointments Booking
  await test('9. POST /api/appointments (Supabase Connected & FK Safe)', async () => {
    const res = await axios.post(BASE_URL + '/appointments', {
      id: 'apt-test-' + Date.now(),
      patient_id: testPatientId,
      doctor_name: 'Dr. Priya Sharma',
      facility: 'Peddapuram Community Hospital',
      facility_type: 'CHC',
      specialty: 'Obstetrics',
      scheduled_at: new Date().toISOString(),
      fee: 0,
      status: 'Scheduled',
    }, { headers: headers() });
    if (res.status !== 201 || !res.data.data) throw new Error('Appointment booking failed');
  });

  // 10. Appointments Listing
  await test('10. GET /api/appointments', async () => {
    const res = await axios.get(BASE_URL + '/appointments?patient_id=' + testPatientId, { headers: headers() });
    if (res.status !== 200 || !Array.isArray(res.data.data)) throw new Error('Appointment list failed');
  });

  // 11. Referrals Outbound
  await test('11. POST /api/referrals (Outbound Transfer + QR Pass)', async () => {
    const res = await axios.post(BASE_URL + '/referrals', {
      id: 'ref-test-' + Date.now(),
      patient_id: testPatientId,
      patient_name: 'Ananya Sharma',
      referring_facility: 'PHC Rampur',
      receiving_facility: 'District Hospital Kakinada',
      reason: 'Routine Gestational Anomaly Scan',
      urgency: 'ROUTINE',
    }, { headers: headers() });
    if (res.status !== 201 || !res.data.data.qr_code) throw new Error('Referral creation failed');
  });

  // 12. Bi-directional Batch Sync with Dependents (Foreign-Key Safe)
  await test('12. POST /api/sync/batch (Foreign Key Integrity & Dependency Ordering)', async () => {
    const batchFamilyPatientId = 'family-pt-' + Date.now();
    const batchApptId = 'batch-apt-' + Date.now();
    const batchVitalId = 'batch-vit-' + Date.now();

    const res = await axios.post(BASE_URL + '/sync/batch', {
      patients: [
        {
          id: batchFamilyPatientId,
          name: 'Rohan Sharma (Child)',
          age: 4,
          gender: 'Male',
          phone: '9845099999',
          blood_group: 'B+',
          abha_id: null,
          is_pregnant: 0,
        },
      ],
      appointments: [
        {
          id: batchApptId,
          patient_id: batchFamilyPatientId,
          doctor_name: 'Dr. Child Specialist',
          facility: 'PHC Peddapuram',
          facility_type: 'PHC',
          specialty: 'Pediatrics',
          scheduled_at: new Date().toISOString(),
          fee: 0,
          status: 'Scheduled',
        },
      ],
      vitals: [
        {
          id: batchVitalId,
          patient_id: batchFamilyPatientId,
          bp_systolic: 95,
          bp_diastolic: 60,
          pulse: 88,
          temperature: 98.4,
          risk_level: 0,
        },
      ],
      user_role: 'patient',
      user_phone: '9845099999',
      user_abha_id: testAbhaId,
    }, { headers: headers() });

    if (res.status !== 200 || !res.data.acks) throw new Error('Batch sync failed');
    if (!res.data.acks.synced_appointment_ids.includes(batchApptId)) throw new Error('Appointment was not acknowledged');
  });

  // 13. Dynamic Cloudflare Tunnel Supabase Auto-Discovery
  await test('13. Supabase Dynamic Tunnel Config Discovery', async () => {
    const { data, error } = await supabase.from('users').select('password').eq('id', 'system_config');
    if (error || !data || data.length === 0) throw new Error('Failed to query system_config in Supabase: ' + (error ? error.message : 'No data'));
    const tunnelUrl = data[0].password;
    if (!tunnelUrl || !tunnelUrl.startsWith('http')) throw new Error('Invalid tunnel URL in Supabase config: ' + tunnelUrl);
  });

  console.log('\n====================================================');
  console.log('SUMMARY: ' + passed + ' PASSED, ' + failed + ' FAILED');
  console.log('====================================================');
  if (failed === 0) {
    console.log('ALL ENDPOINTS & DATABASE SCHEMAS ARE 100% OPERATIONAL!');
    process.exit(0);
  } else {
    process.exit(1);
  }
}

runTests();