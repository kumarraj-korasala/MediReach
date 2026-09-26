// ============================================================
// MediReach — Local SQLite Database Helper
// Offline-first: all records saved locally first, synced later.
// ============================================================
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:miracle/data/models/models.dart';

class DbHelper {
  static const _dbName    = 'medireach.db';
  static const _dbVersion = 1;

  // Singleton ────────────────────────────────────────────────
  DbHelper._();
  static final DbHelper instance = DbHelper._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ── Init & Schema ──────────────────────────────────────────
  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Ensure users table exists even if DB was previously created
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id          TEXT PRIMARY KEY,
        username    TEXT UNIQUE NOT NULL,
        name        TEXT NOT NULL,
        phone       TEXT NOT NULL,
        role        TEXT NOT NULL,
        password    TEXT,
        abha_id     TEXT,
        facility_id TEXT,
        created_at  TEXT NOT NULL
      )
    ''');
    await purgeLegacyDummyData(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id          TEXT PRIMARY KEY,
        username    TEXT UNIQUE NOT NULL,
        name        TEXT NOT NULL,
        phone       TEXT NOT NULL,
        role        TEXT NOT NULL,
        password    TEXT,
        abha_id     TEXT,
        facility_id TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        age         INTEGER NOT NULL,
        gender      TEXT NOT NULL,
        phone       TEXT NOT NULL,
        blood_group TEXT NOT NULL,
        abha_id     TEXT,
        is_pregnant INTEGER DEFAULT 0,
        pregnancy_week INTEGER,
        created_at  TEXT NOT NULL,
        is_synced   INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vitals (
        id           TEXT PRIMARY KEY,
        patient_id   TEXT NOT NULL,
        bp_systolic  REAL,
        bp_diastolic REAL,
        blood_sugar  REAL,
        pulse        REAL,
        hemoglobin   REAL,
        temperature  REAL,
        weight       REAL,
        height       REAL,
        recorded_at  TEXT NOT NULL,
        risk_level   INTEGER DEFAULT 0,
        is_synced    INTEGER DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE medical_records (
        id          TEXT PRIMARY KEY,
        patient_id  TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        specialty   TEXT NOT NULL,
        notes       TEXT,
        status      TEXT NOT NULL,
        tests       TEXT,
        date        TEXT NOT NULL,
        is_synced   INTEGER DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE referrals (
        id            TEXT PRIMARY KEY,
        patient_id    TEXT NOT NULL,
        from_facility TEXT NOT NULL,
        to_facility   TEXT NOT NULL,
        reason        TEXT,
        status        INTEGER DEFAULT 0,
        qr_code       TEXT,
        created_at    TEXT NOT NULL,
        is_synced     INTEGER DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments (
        id            TEXT PRIMARY KEY,
        patient_id    TEXT NOT NULL,
        doctor_name   TEXT NOT NULL,
        facility      TEXT NOT NULL,
        facility_type TEXT NOT NULL,
        specialty     TEXT NOT NULL,
        scheduled_at  TEXT NOT NULL,
        fee           REAL DEFAULT 0,
        status        TEXT DEFAULT 'Scheduled',
        is_synced     INTEGER DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');
    // Fresh database begins completely clean (zero dummy data)
  }

  // ── Patient CRUD ──────────────────────────────────────────
  Future<void> insertPatient(Patient p) async {
    final db = await database;
    // Deduplicate by ABHA ID if present
    if (p.abhaId != null && p.abhaId!.trim().isNotEmpty) {
      final cleanAbha = p.abhaId!.trim();
      final existing = await db.query(
        'patients',
        where: 'abha_id = ?',
        whereArgs: [cleanAbha],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as String;
        final updatedMap = p.toMap()..['id'] = existingId;
        await db.update('patients', updatedMap, where: 'id = ?', whereArgs: [existingId]);
        return;
      }
    }
    await db.insert('patients', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Patient?> getPatient(String id) async {
    final db = await database;
    final rows = await db.query('patients',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Patient.fromMap(rows.first);
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await database;
    final rows = await db.query(
      'patients',
      where: 'name LIKE ? OR id LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Patient.fromMap).toList();
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final rows = await db.query('patients', orderBy: 'created_at DESC');
    return rows.map(Patient.fromMap).toList();
  }

  Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  /// Bulk upserts cloud records downloaded from the server into local SQLite.
  /// Automatically filters columns to prevent schema mismatches and sets is_synced = 1.
  Future<int> upsertDownloadedData({
    List<dynamic> patients = const [],
    List<dynamic> vitals = const [],
    List<dynamic> records = const [],
    List<dynamic> referrals = const [],
    List<dynamic> appointments = const [],
  }) async {
    final db = await database;
    int count = 0;
    final batch = db.batch();

    const patientCols = {'id', 'name', 'age', 'gender', 'phone', 'blood_group', 'abha_id', 'is_pregnant', 'pregnancy_week', 'created_at', 'is_synced'};
    const vitalsCols = {'id', 'patient_id', 'bp_systolic', 'bp_diastolic', 'blood_sugar', 'pulse', 'hemoglobin', 'temperature', 'weight', 'height', 'recorded_at', 'risk_level', 'is_synced'};
    const recordCols = {'id', 'patient_id', 'doctor_name', 'specialty', 'notes', 'status', 'tests', 'date', 'is_synced'};
    const referralCols = {'id', 'patient_id', 'from_facility', 'to_facility', 'reason', 'status', 'qr_code', 'created_at', 'is_synced'};
    const apptCols = {'id', 'patient_id', 'doctor_name', 'facility', 'facility_type', 'specialty', 'scheduled_at', 'fee', 'status', 'is_synced'};

    Map<String, dynamic> filterCols(Map<String, dynamic> source, Set<String> allowed) {
      final filtered = <String, dynamic>{};
      for (final key in source.keys) {
        if (allowed.contains(key)) {
          filtered[key] = source[key];
        }
      }
      filtered['is_synced'] = 1;
      return filtered;
    }

    for (final p in patients) {
      if (p is Map<String, dynamic>) {
        final row = filterCols(p, patientCols);
        if (row['id'] != null && row['name'] != null) {
          final abha = (row['abha_id'] as String?)?.trim();
          if (abha != null && abha.isNotEmpty) {
            final existing = await db.query('patients', where: 'abha_id = ?', whereArgs: [abha], limit: 1);
            if (existing.isNotEmpty) {
              row['id'] = existing.first['id'];
            }
          }
          batch.insert('patients', row, conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        }
      }
    }

    for (final v in vitals) {
      if (v is Map<String, dynamic>) {
        final row = filterCols(v, vitalsCols);
        if (row['id'] != null && row['patient_id'] != null) {
          batch.insert('vitals', row, conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        }
      }
    }

    for (final r in records) {
      if (r is Map<String, dynamic>) {
        final row = filterCols(r, recordCols);
        if (row['id'] != null && row['patient_id'] != null) {
          batch.insert('medical_records', row, conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        }
      }
    }

    for (final ref in referrals) {
      if (ref is Map<String, dynamic>) {
        final row = filterCols(ref, referralCols);
        if (row['id'] != null && row['patient_id'] != null) {
          batch.insert('referrals', row, conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        }
      }
    }

    for (final a in appointments) {
      if (a is Map<String, dynamic>) {
        final row = filterCols(a, apptCols);
        if (row['id'] != null && row['patient_id'] != null) {
          batch.insert('appointments', row, conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        }
      }
    }

    if (count > 0) {
      await batch.commit(noResult: true);
    }
    return count;
  }

  // ── Vitals CRUD ───────────────────────────────────────────
  Future<void> insertVitals(Vitals v) async {
    final db = await database;
    await db.insert('vitals', v.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Vitals>> getVitalsForPatient(String patientId) async {
    final db = await database;
    final rows = await db.query(
      'vitals',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'recorded_at DESC',
    );
    return rows.map(Vitals.fromMap).toList();
  }

  Future<Vitals?> getLatestVitals(String patientId) async {
    final db = await database;
    final rows = await db.query(
      'vitals',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Vitals.fromMap(rows.first);
  }

  // ── Medical Records CRUD ──────────────────────────────────
  Future<void> insertMedicalRecord(MedicalRecord r) async {
    final db = await database;
    await db.insert('medical_records', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MedicalRecord>> getRecordsForPatient(String patientId) async {
    final db = await database;
    final rows = await db.query(
      'medical_records',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );
    return rows.map(MedicalRecord.fromMap).toList();
  }

  // ── Referrals CRUD ────────────────────────────────────────
  Future<void> insertReferral(Referral r) async {
    final db = await database;
    await db.insert('referrals', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Referral>> getReferralsForPatient(String patientId) async {
    final db = await database;
    final rows = await db.query(
      'referrals',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Referral.fromMap).toList();
  }

  Future<void> updateReferralStatus(String id, ReferralStatus status) async {
    final db = await database;
    await db.update(
      'referrals',
      {'status': status.index, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Appointments CRUD ─────────────────────────────────────
  Future<void> insertAppointment(Appointment a) async {
    final db = await database;
    await db.insert('appointments', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    final db = await database;
    final rows = await db.query(
      'appointments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'scheduled_at DESC',
    );
    return rows.map(Appointment.fromMap).toList();
  }

  // ── Offline sync queue ────────────────────────────────────
  /// Returns all rows not yet synced to server, across all tables.
  Future<Map<String, List<Map<String, dynamic>>>> getPendingSyncData() async {
    final db = await database;
    return {
      'patients':        await db.query('patients',        where: 'is_synced = 0'),
      'vitals':          await db.query('vitals',          where: 'is_synced = 0'),
      'medical_records': await db.query('medical_records', where: 'is_synced = 0'),
      'referrals':       await db.query('referrals',       where: 'is_synced = 0'),
      'appointments':    await db.query('appointments',    where: 'is_synced = 0'),
    };
  }

  /// Returns total count of rows pending sync across all tables
  Future<int> getPendingSyncCount() async {
    final data = await getPendingSyncData();
    int count = 0;
    data.forEach((_, list) => count += list.length);
    return count;
  }

  // ── Legacy Dummy Data Purge & Auth ───────────────────────
  Future<void> purgeLegacyDummyData([Database? dbInstance]) async {
    final db = dbInstance ?? await database;
    try {
      // 1. Purge legacy mock users
      await db.delete(
        'users',
        where: 'username IN (?, ?, ?, ?) OR id IN (?, ?, ?, ?)',
        whereArgs: [
          'admin', 'doctor', 'asha', 'patient',
          'usr-admin-01', 'usr-doc-01', 'usr-worker-01', 'usr-patient-01'
        ],
      );

      // 2. Purge legacy mock patients and their dependents
      const legacyPids = [
        'PT-2026-1048',
        'PT-2026-1049',
        'PT-2026-1050',
        'PT-2026-1051',
      ];
      for (final pid in legacyPids) {
        await db.delete('vitals', where: 'patient_id = ?', whereArgs: [pid]);
        await db.delete('medical_records', where: 'patient_id = ?', whereArgs: [pid]);
        await db.delete('referrals', where: 'patient_id = ?', whereArgs: [pid]);
        await db.delete('appointments', where: 'patient_id = ?', whereArgs: [pid]);
        await db.delete('patients', where: 'id = ?', whereArgs: [pid]);
      }
    } catch (_) {}
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final clean = username.toLowerCase().trim();
    final rows = await db.query(
      'users',
      where: 'LOWER(username) = ? OR phone = ? OR abha_id = ?',
      whereArgs: [clean, username.trim(), username.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    final db = await database;
    final clean = username.toLowerCase().trim();
    final rows = await db.query(
      'users',
      where: '(LOWER(username) = ? OR phone = ? OR abha_id = ?) AND password = ?',
      whereArgs: [clean, username.trim(), username.trim(), password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // ── Cascading Deletion & Clear Storage ────────────────────
  Future<void> deletePatientAndData(String patientId) async {
    final db = await database;
    await db.delete('vitals', where: 'patient_id = ?', whereArgs: [patientId]);
    await db.delete('medical_records', where: 'patient_id = ?', whereArgs: [patientId]);
    await db.delete('referrals', where: 'patient_id = ?', whereArgs: [patientId]);
    await db.delete('appointments', where: 'patient_id = ?', whereArgs: [patientId]);
    await db.delete('patients', where: 'id = ?', whereArgs: [patientId]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('vitals');
    await db.delete('medical_records');
    await db.delete('referrals');
    await db.delete('appointments');
    await db.delete('patients');
  }

  Future<void> close() async => _db?.close();
}
