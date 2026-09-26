// routes/facilities.js — Healthcare Network, GPS Haversine Distance & Doctor Rosters
const express = require('express');
const router = express.Router();

/**
 * Haversine formula to compute great-circle distance between two GPS coordinates (in km)
 */
function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the Earth in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((R * c).toFixed(1));
}

// Master Regional Healthcare Network with On-Duty Doctors
const governmentFacilities = [
  {
    id: 'fac-001',
    name: 'Primary Health Centre (PHC) - Rampur',
    type: 'PHC',
    district: 'Belagavi',
    address: 'Main Road, Rampur Village, Sub-Center Catchment',
    latitude: 16.2415,
    longitude: 74.7812,
    phone: '+91 83322 10101',
    has_emergency_24x7: false,
    has_obstetrician: false,
    has_pharmacy: true,
    available_specialists: ['General Physician', 'AYUSH Medical Officer', 'ANM Community Nurse'],
    doctors: [
      {
        id: 'doc-101',
        name: 'Dr. Anand Deshmukh',
        degree: 'MBBS (General Medicine)',
        specialty: 'General Physician',
        experience: '8 years',
        opd_timing: '9:00 AM - 1:00 PM',
        status: 'Available Today',
        languages: 'Kannada, Marathi, Hindi',
        phone: '+91 94401 11201',
      },
      {
        id: 'doc-102',
        name: 'Dr. Sneha Patil',
        degree: 'BAMS (Ayurveda & Primary Care)',
        specialty: 'AYUSH Medical Officer',
        experience: '5 years',
        opd_timing: '1:00 PM - 5:00 PM',
        status: 'Available Today',
        languages: 'Kannada, Hindi',
        phone: '+91 94401 11202',
      },
    ],
  },
  {
    id: 'fac-002',
    name: 'Community Health Centre (CHC) - Gokak',
    type: 'CHC',
    district: 'Belagavi',
    address: 'Hospital Circle, Gokak Town',
    latitude: 16.1667,
    longitude: 74.8333,
    phone: '+91 83322 20202',
    has_emergency_24x7: true,
    has_obstetrician: true,
    has_pharmacy: true,
    available_specialists: ['Obstetrician & Gynaecologist', 'Pediatrician', 'General Surgeon'],
    doctors: [
      {
        id: 'doc-201',
        name: 'Dr. Radhika Sharma',
        degree: 'MD, DGO (Obstetrics & Gynecology)',
        specialty: 'Obstetrician & Gynaecologist',
        experience: '12 years',
        opd_timing: '9:00 AM - 2:00 PM (Emergency 24x7)',
        status: 'On Call / Available',
        languages: 'Telugu, Hindi, English',
        phone: '+91 94401 88888',
      },
      {
        id: 'doc-202',
        name: 'Dr. Ramesh Kulkarni',
        degree: 'MD (Pediatrics)',
        specialty: 'Pediatrician',
        experience: '10 years',
        opd_timing: '10:00 AM - 4:00 PM',
        status: 'Available Today',
        languages: 'Kannada, English',
        phone: '+91 94401 22302',
      },
      {
        id: 'doc-203',
        name: 'Dr. Vikram Naik',
        degree: 'MS (General Surgery)',
        specialty: 'General Surgeon',
        experience: '15 years',
        opd_timing: '11:00 AM - 3:00 PM',
        status: 'In OT / Available 2 PM',
        languages: 'Kannada, Hindi, English',
        phone: '+91 94401 22303',
      },
    ],
  },
  {
    id: 'fac-003',
    name: 'ASA Sub-District Hospital - Hukkeri',
    type: 'Hospital',
    district: 'Belagavi',
    address: 'National Highway Link, Hukkeri',
    latitude: 16.2234,
    longitude: 74.6012,
    phone: '+91 83322 30303',
    has_emergency_24x7: true,
    has_obstetrician: true,
    has_pharmacy: true,
    available_specialists: ['Obstetrician', 'Orthopedic Surgeon', 'Cardiologist (Visiting)', 'Pediatrician'],
    doctors: [
      {
        id: 'doc-301',
        name: 'Dr. Suresh Varma',
        degree: 'MS, M.Ch (Superintendent)',
        specialty: 'Hospital Superintendent & General Surgery',
        experience: '22 years',
        opd_timing: '9:00 AM - 1:00 PM',
        status: 'Available Today',
        languages: 'Telugu, Hindi, English',
        phone: '+91 94401 99999',
      },
      {
        id: 'doc-302',
        name: 'Dr. Meenakshi Sundaram',
        degree: 'DNB (Orthopedics)',
        specialty: 'Orthopedic Surgeon',
        experience: '9 years',
        opd_timing: '10:00 AM - 3:00 PM',
        status: 'Available Today',
        languages: 'Tamil, Telugu, English',
        phone: '+91 94401 33402',
      },
    ],
  },
  {
    id: 'fac-004',
    name: 'District Civil Hospital - Belagavi',
    type: 'Hospital',
    district: 'Belagavi',
    address: 'Civil Hospital Road, Belagavi City',
    latitude: 15.8497,
    longitude: 74.4977,
    phone: '+91 83124 04040',
    has_emergency_24x7: true,
    has_obstetrician: true,
    has_pharmacy: true,
    available_specialists: ['High-Risk OBGYN', 'Cardiologist', 'Neurologist', 'Pediatric ICU', 'Trauma Surgeon'],
    doctors: [
      {
        id: 'doc-401',
        name: 'Dr. Hariprasad Rao',
        degree: 'DM (Cardiology), MD',
        specialty: 'Consultant Cardiologist',
        experience: '18 years',
        opd_timing: '9:00 AM - 1:00 PM',
        status: 'Available Today',
        languages: 'Kannada, Hindi, English',
        phone: '+91 83124 04041',
      },
      {
        id: 'doc-402',
        name: 'Dr. Kavitha Menon',
        degree: 'MD, High-Risk Obstetrics Fellowship',
        specialty: 'High-Risk OBGYN Specialist',
        experience: '14 years',
        opd_timing: '24x7 Emergency Delivery Room',
        status: 'Duty Doctor Active',
        languages: 'Malayalam, English, Hindi',
        phone: '+91 83124 04042',
      },
    ],
  },
  {
    id: 'fac-005',
    name: 'KIMS Medical College & Super-Specialty Hospital - Hubballi',
    type: 'Hospital',
    district: 'Dharwad',
    address: 'Vidyanagar, Hubballi',
    latitude: 15.3647,
    longitude: 75.124,
    phone: '+91 83622 25555',
    has_emergency_24x7: true,
    has_obstetrician: true,
    has_pharmacy: true,
    available_specialists: ['Super-Specialty Cardiology', 'Nephrology & Dialysis', 'Oncology', 'Neonatal ICU'],
    doctors: [
      {
        id: 'doc-501',
        name: 'Dr. Raghavendra Bhat',
        degree: 'DM (Nephrology)',
        specialty: 'Nephrologist & Dialysis Head',
        experience: '16 years',
        opd_timing: '10:00 AM - 3:00 PM',
        status: 'Available Today',
        languages: 'Kannada, English',
        phone: '+91 83622 25556',
      },
      {
        id: 'doc-502',
        name: 'Dr. Priya Singhal',
        degree: 'MD (Pediatric Critical Care)',
        specialty: 'Neonatal & Pediatric ICU Lead',
        experience: '11 years',
        opd_timing: '24x7 Critical Care Ward',
        status: 'On Duty',
        languages: 'Hindi, English',
        phone: '+91 83622 25557',
      },
    ],
  },
];

/**
 * GET /api/facilities/nearby
 * Supports: ?lat=16.2415&lng=74.7812&type=PHC&specialty=Cardiology
 */
router.get('/nearby', (req, res) => {
  try {
    const userLat = parseFloat(req.query.lat) || 16.2415; // default Rampur
    const userLng = parseFloat(req.query.lng) || 74.7812;
    const typeFilter = req.query.type;
    const specialtyFilter = (req.query.specialty || '').toLowerCase();

    // Map and compute exact Haversine distance
    let results = governmentFacilities.map((f) => {
      const distance = calculateDistanceKm(userLat, userLng, f.latitude, f.longitude);
      return {
        ...f,
        distance_km: distance,
      };
    });

    // Filter by type if provided
    if (typeFilter && typeFilter !== 'All') {
      results = results.filter(
        (f) => f.type.toLowerCase() === typeFilter.toLowerCase()
      );
    }

    // Filter by specialty if provided
    if (specialtyFilter) {
      results = results.filter(
        (f) =>
          f.available_specialists.some((s) => s.toLowerCase().includes(specialtyFilter)) ||
          f.doctors.some((d) => d.specialty.toLowerCase().includes(specialtyFilter))
      );
    }

    // Sort ascending by proximity
    results.sort((a, b) => a.distance_km - b.distance_km);

    return res.json({
      success: true,
      user_coordinates: { latitude: userLat, longitude: userLng },
      count: results.length,
      data: results,
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;

