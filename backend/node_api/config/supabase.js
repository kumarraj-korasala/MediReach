// config/supabase.js — Supabase Client Setup with fallback for local dev
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://mock.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || 'mock-key';

let supabase = null;
try {
  supabase = createClient(supabaseUrl, supabaseKey);
  console.log('[SUPABASE] Client initialized for:', supabaseUrl);
} catch (err) {
  console.warn('[SUPABASE] Warning: Failed to initialize live Supabase client. Running in offline/mock fallback mode.');
}

module.exports = { supabase };
