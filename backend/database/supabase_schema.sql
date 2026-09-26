-- ==============================================================================
-- MediReach — Supabase PostgreSQL Schema (1:1 Exact Match with Flutter Models)
-- Run this in Supabase SQL Editor to support all sync tables
-- ==============================================================================

-- Drop old tables to rebuild with exact model matching columns
DROP TABLE IF EXISTS public.appointments CASCADE;
DROP TABLE IF EXISTS public.referrals CASCADE;
DROP TABLE IF EXISTS public.medical_records CASCADE;
DROP TABLE IF EXISTS public.vitals CASCADE;
DROP TABLE IF EXISTS public.patients CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 0. SYSTEM USERS & AUTH ROLES
CREATE TABLE public.users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'patient',
    password TEXT NOT NULL,
    abha_id TEXT,
    facility_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 1. PATIENTS DIRECTORY
CREATE TABLE public.patients (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    gender TEXT NOT NULL,
    phone TEXT NOT NULL,
    blood_group TEXT NOT NULL,
    abha_id TEXT,
    is_pregnant INTEGER DEFAULT 0,
    pregnancy_week INTEGER,
    created_at TEXT NOT NULL,
    is_synced INTEGER DEFAULT 1
);

-- 2. CLINICAL VITALS
CREATE TABLE public.vitals (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    bp_systolic REAL,
    bp_diastolic REAL,
    blood_sugar REAL,
    pulse REAL,
    hemoglobin REAL,
    temperature REAL,
    weight REAL,
    height REAL,
    recorded_at TEXT NOT NULL,
    risk_level INTEGER DEFAULT 0,
    is_synced INTEGER DEFAULT 1
);

-- 3. MEDICAL RECORDS & TIMELINE
CREATE TABLE public.medical_records (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    notes TEXT,
    status TEXT NOT NULL,
    tests TEXT,
    date TEXT NOT NULL,
    is_synced INTEGER DEFAULT 1
);

-- 4. CLOSED-LOOP REFERRALS
CREATE TABLE public.referrals (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    from_facility TEXT NOT NULL,
    to_facility TEXT NOT NULL,
    reason TEXT,
    status INTEGER DEFAULT 0,
    qr_code TEXT,
    created_at TEXT NOT NULL,
    is_synced INTEGER DEFAULT 1
);

-- 5. APPOINTMENTS & QUEUES
CREATE TABLE public.appointments (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    facility TEXT NOT NULL,
    facility_type TEXT NOT NULL,
    specialty TEXT NOT NULL,
    scheduled_at TEXT NOT NULL,
    fee REAL DEFAULT 0,
    status TEXT NOT NULL,
    is_synced INTEGER DEFAULT 1
);

-- ==============================================================================
-- ROW-LEVEL SECURITY POLICIES (Allow Gateway Service Full Access)
-- ==============================================================================

ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations for patients" ON public.patients FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations for vitals" ON public.vitals FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations for medical_records" ON public.medical_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations for referrals" ON public.referrals FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations for appointments" ON public.appointments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations for users" ON public.users FOR ALL USING (true) WITH CHECK (true);
