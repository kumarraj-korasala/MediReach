// routes/medicines.js — Essential Medicines Catalog & Real-Time Stock Inventory
const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');

const essentialMedicines = [
  {
    id: 'med-01',
    name: 'Iron & Folic Acid (IFA) Tablets',
    generic_name: 'Ferrous Sulfate + Folic Acid',
    category: 'Maternal Health',
    stock_quantity: 450,
    unit: 'Tablets',
    status: 'IN_STOCK',
    nearest_dispensary: 'PHC Peddapuram Dispensary (2.1 km)',
    phone: '+91 94401 23456',
    dosage: '1 tablet daily after meals',
  },
  {
    id: 'med-02',
    name: 'Paracetamol 500mg',
    generic_name: 'Acetaminophen',
    category: 'Analgesics / Antipyretic',
    stock_quantity: 1200,
    unit: 'Tablets',
    status: 'IN_STOCK',
    nearest_dispensary: 'Sub-Centre Peddapuram (0.8 km)',
    phone: '+91 94402 34567',
    dosage: '1 tablet every 6-8 hours as needed for fever',
  },
  {
    id: 'med-03',
    name: 'Metformin 500mg',
    generic_name: 'Metformin Hydrochloride',
    category: 'Diabetes / NCD',
    stock_quantity: 85,
    unit: 'Tablets',
    status: 'LOW_STOCK',
    nearest_dispensary: 'CHC Samalkot Pharmacy (6.4 km)',
    phone: '+91 94403 45678',
    dosage: '1 tablet twice daily with meals',
  },
  {
    id: 'med-04',
    name: 'Telmisartan 40mg',
    generic_name: 'Telmisartan',
    category: 'Cardiovascular / HTN',
    stock_quantity: 320,
    unit: 'Tablets',
    status: 'IN_STOCK',
    nearest_dispensary: 'District Hospital Kakinada (14.2 km)',
    phone: '+91 94404 56789',
    dosage: '1 tablet once daily in the morning',
  },
  {
    id: 'med-05',
    name: 'Oral Rehydration Salts (ORS)',
    generic_name: 'Sodium Chloride + Potassium Chloride + Dextrose',
    category: 'Pediatrics / Dehydration',
    stock_quantity: 600,
    unit: 'Sachets',
    status: 'IN_STOCK',
    nearest_dispensary: 'All Village ASHA Kits',
    phone: '+91 94405 67890',
    dosage: 'Dissolve 1 sachet in 1 Litre of clean drinking water',
  },
  {
    id: 'med-06',
    name: 'Amoxicillin 500mg Capsules',
    generic_name: 'Amoxicillin Trihydrate',
    category: 'Antibiotics',
    stock_quantity: 0,
    unit: 'Capsules',
    status: 'OUT_OF_STOCK',
    nearest_dispensary: 'District Hospital Central Medical Store',
    phone: '+91 94406 78901',
    dosage: '1 capsule three times daily for 5 days as prescribed',
  },
];

router.get('/', authenticateToken, (req, res) => {
  const query = (req.query.q || '').toLowerCase();
  const filtered = essentialMedicines.filter(
    (m) =>
      m.name.toLowerCase().includes(query) ||
      m.generic_name.toLowerCase().includes(query) ||
      m.category.toLowerCase().includes(query)
  );
  return res.json({ success: true, count: filtered.length, data: filtered });
});

module.exports = router;
