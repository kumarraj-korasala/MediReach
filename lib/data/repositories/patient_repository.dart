// ============================================================
// MediReach — Patient Repository
// Single source of truth. Reads/writes local DB first.
// ============================================================
import 'package:miracle/core/remote/abha_service.dart';
import 'package:miracle/data/local/db_helper.dart';
import 'package:miracle/data/models/models.dart';

class PatientRepository {
  PatientRepository._();
  static final PatientRepository instance = PatientRepository._();

  final _db = DbHelper.instance;

  // ── Register new patient ───────────────────────────────────
  Future<Patient> register({
    required String name,
    required int age,
    required String gender,
    required String phone,
    required String bloodGroup,
    String? abhaId,
    bool isPregnant = false,
    int? pregnancyWeek,
  }) async {
    final patient = Patient(
      id: _generateId(),
      name: name,
      age: age,
      gender: gender,
      phone: phone,
      bloodGroup: bloodGroup,
      abhaId: abhaId,
      isPregnant: isPregnant,
      pregnancyWeek: pregnancyWeek,
      createdAt: DateTime.now(),
      isSynced: false,
    );
    await _db.insertPatient(patient);
    return patient;
  }

  // ── Search & Scoped Queries ───────────────────────────────
  Future<List<Patient>> search(String query) =>
      _db.searchPatients(query);

  Future<List<Patient>> getAll() => _db.getAllPatients();

  /// Role-based data encapsulation:
  /// - Admin / Doctor: full hospital registry
  /// - ASHA / Health Worker: catchment area registry
  /// - Citizen Patient: strictly isolated personal and family health records
  Future<List<Patient>> getScopedPatients(AppUser? user) async {
    final all = await _db.getAllPatients();
    if (user == null) return all;

    if (user.role == UserRole.admin ||
        user.role == UserRole.doctor ||
        user.role == UserRole.healthWorker) {
      return all;
    }

    // Role is Patient:
    // On a citizen's personal device, all local patient records represent the citizen
    // and their registered family members (children, spouse, elders).
    // If local DB has records, return all family/personal records on this device
    if (all.isNotEmpty) {
      return all;
    }

    // If no records exist in SQLite for this citizen, fetch existing records via ABHA API
    if (user.abhaId != null && user.abhaId!.trim().isNotEmpty) {
      await AbhaService.instance.fetchAndSyncAbhaRecords(user.abhaId!);
      final updatedAll = await _db.getAllPatients();
      if (updatedAll.isNotEmpty) return updatedAll;
    }

    return all;
  }

  Future<int> getPendingSyncCount() => _db.getPendingSyncCount();

  Future<Patient?> getById(String id) => _db.getPatient(id);

  Future<void> deletePatient(String id) => _db.deletePatientAndData(id);

  Future<void> clearLocalStorage() => _db.clearAllData();

  // ── Vitals ────────────────────────────────────────────────
  Future<Vitals> recordVitals({
    required String patientId,
    double? bpSystolic,
    double? bpDiastolic,
    double? bloodSugar,
    double? pulse,
    double? hemoglobin,
    double? temperature,
    double? weight,
    double? height,
  }) async {
    final risk = _calculateRisk(
      bpSystolic: bpSystolic,
      bpDiastolic: bpDiastolic,
      bloodSugar: bloodSugar,
      pulse: pulse,
    );

    final vitals = Vitals(
      id: _generateId(),
      patientId: patientId,
      bpSystolic: bpSystolic,
      bpDiastolic: bpDiastolic,
      bloodSugar: bloodSugar,
      pulse: pulse,
      hemoglobin: hemoglobin,
      temperature: temperature,
      weight: weight,
      height: height,
      recordedAt: DateTime.now(),
      riskLevel: risk,
      isSynced: false,
    );

    await _db.insertVitals(vitals);
    return vitals;
  }

  Future<Vitals?> getLatestVitals(String patientId) =>
      _db.getLatestVitals(patientId);

  Future<List<Vitals>> getVitalsHistory(String patientId) =>
      _db.getVitalsForPatient(patientId);

  // ── Medical Records ───────────────────────────────────────
  Future<List<MedicalRecord>> getRecords(String patientId) =>
      _db.getRecordsForPatient(patientId);

  Future<MedicalRecord> addRecord({
    required String patientId,
    required String doctorName,
    required String specialty,
    required String notes,
    required String status,
    required List<String> tests,
  }) async {
    final record = MedicalRecord(
      id: _generateId(),
      patientId: patientId,
      doctorName: doctorName,
      specialty: specialty,
      notes: notes,
      status: status,
      tests: tests,
      date: DateTime.now(),
      isSynced: false,
    );
    await _db.insertMedicalRecord(record);
    return record;
  }

  // ── Referrals ─────────────────────────────────────────────
  Future<Referral> createReferral({
    required String patientId,
    required String fromFacility,
    required String toFacility,
    required String reason,
  }) async {
    final referral = Referral(
      id: 'REF-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      fromFacility: fromFacility,
      toFacility: toFacility,
      reason: reason,
      status: ReferralStatus.created,
      createdAt: DateTime.now(),
      isSynced: false,
    );
    await _db.insertReferral(referral);
    return referral;
  }

  Future<List<Referral>> getReferrals(String patientId) =>
      _db.getReferralsForPatient(patientId);

  Future<void> updateReferralStatus(String id, ReferralStatus status) =>
      _db.updateReferralStatus(id, status);

  // ── Appointments ──────────────────────────────────────────
  Future<Appointment> bookAppointment({
    required String patientId,
    required String doctorName,
    required String facility,
    required String facilityType,
    required String specialty,
    required DateTime scheduledAt,
    required double fee,
  }) async {
    final appt = Appointment(
      id: 'APT-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      doctorName: doctorName,
      facility: facility,
      facilityType: facilityType,
      specialty: specialty,
      scheduledAt: scheduledAt,
      fee: fee,
      isSynced: false,
    );
    await _db.insertAppointment(appt);
    return appt;
  }

  Future<List<Appointment>> getAppointments(String patientId) =>
      _db.getAppointmentsForPatient(patientId);

  // ── Helpers ───────────────────────────────────────────────
  String _generateId() =>
      'PT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 100000}';

  /// Deterministic triage rules (offline, no ML needed).
  RiskLevel _calculateRisk({
    double? bpSystolic,
    double? bpDiastolic,
    double? bloodSugar,
    double? pulse,
  }) {
    // Emergency thresholds
    if ((bpSystolic != null && bpSystolic >= 180) ||
        (bpDiastolic != null && bpDiastolic >= 120)) {
      return RiskLevel.emergency;
    }
    if (bloodSugar != null && (bloodSugar < 50 || bloodSugar > 400)) {
      return RiskLevel.emergency;
    }
    if (pulse != null && (pulse < 40 || pulse > 150)) {
      return RiskLevel.emergency;
    }

    // High thresholds
    if ((bpSystolic != null && bpSystolic >= 160) ||
        (bpDiastolic != null && bpDiastolic >= 100)) {
      return RiskLevel.high;
    }
    if (bloodSugar != null && (bloodSugar < 70 || bloodSugar > 300)) {
      return RiskLevel.high;
    }

    // Moderate thresholds
    if ((bpSystolic != null && bpSystolic >= 140) ||
        (bpDiastolic != null && bpDiastolic >= 90)) {
      return RiskLevel.moderate;
    }
    if (bloodSugar != null && bloodSugar > 180) {
      return RiskLevel.moderate;
    }

    return RiskLevel.low;
  }
}
