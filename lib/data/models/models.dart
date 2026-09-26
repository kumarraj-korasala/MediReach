// ============================================================
// MediReach — Core Data Models
// Centralised model definitions. All screens import from here.
// ============================================================

/// Health/triage risk level
enum RiskLevel { low, moderate, high, emergency }

extension RiskLevelExt on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:       return 'Low Risk';
      case RiskLevel.moderate:  return 'Moderate Priority';
      case RiskLevel.high:      return 'High Risk';
      case RiskLevel.emergency: return 'Emergency';
    }
  }

  String get emoji {
    switch (this) {
      case RiskLevel.low:       return '🟢';
      case RiskLevel.moderate:  return '🟡';
      case RiskLevel.high:      return '🔴';
      case RiskLevel.emergency: return '🚨';
    }
  }
}

// ── Patient ───────────────────────────────────────────────────
class Patient {
  final String id;           // e.g. PT-2026-1048
  final String name;
  final int age;
  final String gender;       // Male | Female | Other
  final String phone;
  final String bloodGroup;
  final String? abhaId;
  final bool isPregnant;
  final int? pregnancyWeek;
  final DateTime createdAt;
  final bool isSynced;       // false = pending upload to server

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.bloodGroup,
    this.abhaId,
    this.isPregnant = false,
    this.pregnancyWeek,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'phone': phone,
    'blood_group': bloodGroup,
    'abha_id': abhaId,
    'is_pregnant': isPregnant ? 1 : 0,
    'pregnancy_week': pregnancyWeek,
    'created_at': createdAt.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };

  factory Patient.fromMap(Map<String, dynamic> m) => Patient(
    id: m['id'],
    name: m['name'],
    age: m['age'],
    gender: m['gender'],
    phone: m['phone'],
    bloodGroup: m['blood_group'],
    abhaId: m['abha_id'],
    isPregnant: m['is_pregnant'] == 1,
    pregnancyWeek: m['pregnancy_week'],
    createdAt: DateTime.parse(m['created_at']),
    isSynced: m['is_synced'] == 1,
  );
}

// ── Vitals ────────────────────────────────────────────────────
class Vitals {
  final String id;
  final String patientId;
  final double? bpSystolic;
  final double? bpDiastolic;
  final double? bloodSugar;
  final double? pulse;
  final double? hemoglobin;
  final double? temperature;
  final double? weight;
  final double? height;
  final DateTime recordedAt;
  final RiskLevel riskLevel;
  final bool isSynced;

  const Vitals({
    required this.id,
    required this.patientId,
    this.bpSystolic,
    this.bpDiastolic,
    this.bloodSugar,
    this.pulse,
    this.hemoglobin,
    this.temperature,
    this.weight,
    this.height,
    required this.recordedAt,
    this.riskLevel = RiskLevel.low,
    this.isSynced = false,
  });

  String get bpDisplay =>
      (bpSystolic != null && bpDiastolic != null)
          ? '${bpSystolic!.toInt()}/${bpDiastolic!.toInt()}'
          : '--';

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'bp_systolic': bpSystolic,
    'bp_diastolic': bpDiastolic,
    'blood_sugar': bloodSugar,
    'pulse': pulse,
    'hemoglobin': hemoglobin,
    'temperature': temperature,
    'weight': weight,
    'height': height,
    'recorded_at': recordedAt.toIso8601String(),
    'risk_level': riskLevel.index,
    'is_synced': isSynced ? 1 : 0,
  };

  factory Vitals.fromMap(Map<String, dynamic> m) => Vitals(
    id: m['id'],
    patientId: m['patient_id'],
    bpSystolic: m['bp_systolic']?.toDouble(),
    bpDiastolic: m['bp_diastolic']?.toDouble(),
    bloodSugar: m['blood_sugar']?.toDouble(),
    pulse: m['pulse']?.toDouble(),
    hemoglobin: m['hemoglobin']?.toDouble(),
    temperature: m['temperature']?.toDouble(),
    weight: m['weight']?.toDouble(),
    height: m['height']?.toDouble(),
    recordedAt: DateTime.parse(m['recorded_at']),
    riskLevel: RiskLevel.values[m['risk_level'] ?? 0],
    isSynced: m['is_synced'] == 1,
  );
}

// ── Medical Record / Encounter ────────────────────────────────
class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorName;
  final String specialty;
  final String notes;
  final String status;       // Available | Completed | Pending
  final List<String> tests;
  final DateTime date;
  final bool isSynced;

  const MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.specialty,
    required this.notes,
    required this.status,
    required this.tests,
    required this.date,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'doctor_name': doctorName,
    'specialty': specialty,
    'notes': notes,
    'status': status,
    'tests': tests.join('|'),
    'date': date.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };

  factory MedicalRecord.fromMap(Map<String, dynamic> m) => MedicalRecord(
    id: m['id'],
    patientId: m['patient_id'],
    doctorName: m['doctor_name'],
    specialty: m['specialty'],
    notes: m['notes'],
    status: m['status'],
    tests: (m['tests'] as String).split('|'),
    date: DateTime.parse(m['date']),
    isSynced: m['is_synced'] == 1,
  );
}

// ── Referral ──────────────────────────────────────────────────
enum ReferralStatus { created, dispatched, arrived, completed, cancelled }

class Referral {
  final String id;           // REF-2026-00892
  final String patientId;
  final String fromFacility;
  final String toFacility;
  final String reason;
  final ReferralStatus status;
  final String? qrCode;
  final DateTime createdAt;
  final bool isSynced;

  const Referral({
    required this.id,
    required this.patientId,
    required this.fromFacility,
    required this.toFacility,
    required this.reason,
    this.status = ReferralStatus.created,
    this.qrCode,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'from_facility': fromFacility,
    'to_facility': toFacility,
    'reason': reason,
    'status': status.index,
    'qr_code': qrCode,
    'created_at': createdAt.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };

  factory Referral.fromMap(Map<String, dynamic> m) => Referral(
    id: m['id'],
    patientId: m['patient_id'],
    fromFacility: m['from_facility'],
    toFacility: m['to_facility'],
    reason: m['reason'],
    status: ReferralStatus.values[m['status'] ?? 0],
    qrCode: m['qr_code'],
    createdAt: DateTime.parse(m['created_at']),
    isSynced: m['is_synced'] == 1,
  );
}

// ── Appointment ───────────────────────────────────────────────
class Appointment {
  final String id;
  final String patientId;
  final String doctorName;
  final String facility;
  final String facilityType; // PHC | District Hospital | CHC
  final String specialty;
  final DateTime scheduledAt;
  final double fee;
  final String status;       // Scheduled | Completed | Cancelled
  final bool isSynced;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.facility,
    required this.facilityType,
    required this.specialty,
    required this.scheduledAt,
    required this.fee,
    this.status = 'Scheduled',
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'doctor_name': doctorName,
    'facility': facility,
    'facility_type': facilityType,
    'specialty': specialty,
    'scheduled_at': scheduledAt.toIso8601String(),
    'fee': fee,
    'status': status,
    'is_synced': isSynced ? 1 : 0,
  };

  factory Appointment.fromMap(Map<String, dynamic> m) => Appointment(
    id: m['id'],
    patientId: m['patient_id'],
    doctorName: m['doctor_name'],
    facility: m['facility'],
    facilityType: m['facility_type'],
    specialty: m['specialty'],
    scheduledAt: DateTime.parse(m['scheduled_at']),
    fee: m['fee']?.toDouble() ?? 0,
    status: m['status'],
    isSynced: m['is_synced'] == 1,
  );
}

// ── Medicine ──────────────────────────────────────────────────
class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String prescribedBy;
  final String timing;       // After Food | Before Food | Empty Stomach
  final DateTime startDate;
  final String? patientId;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.prescribedBy,
    required this.timing,
    required this.startDate,
    this.patientId,
  });
}

// ── Doctor on Duty ───────────────────────────────────────────
class DutyDoctor {
  final String id;
  final String name;
  final String degree;
  final String specialty;
  final String experience;
  final String opdTiming;
  final String status;
  final String languages;
  final String phone;

  const DutyDoctor({
    required this.id,
    required this.name,
    required this.degree,
    required this.specialty,
    required this.experience,
    required this.opdTiming,
    required this.status,
    required this.languages,
    required this.phone,
  });

  factory DutyDoctor.fromMap(Map<String, dynamic> m) => DutyDoctor(
    id: m['id'] ?? '',
    name: m['name'] ?? '',
    degree: m['degree'] ?? '',
    specialty: m['specialty'] ?? '',
    experience: m['experience'] ?? '',
    opdTiming: m['opd_timing'] ?? '',
    status: m['status'] ?? 'Available',
    languages: m['languages'] ?? '',
    phone: m['phone'] ?? '',
  );
}

// ── Healthcare Facility ───────────────────────────────────────
class HealthcareFacility {
  final String id;
  final String name;
  final String type;         // PHC | CHC | Hospital
  final double distanceKm;
  final double lat;
  final double lng;
  final String phone;
  final String address;
  final bool hasObstetrician;
  final bool hasEmergency24x7;
  final bool hasPharmacy;
  final List<String> availableSpecialists;
  final List<DutyDoctor> doctors;

  const HealthcareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.lat,
    required this.lng,
    required this.phone,
    this.address = '',
    this.hasObstetrician = false,
    this.hasEmergency24x7 = false,
    this.hasPharmacy = true,
    this.availableSpecialists = const [],
    this.doctors = const [],
  });

  factory HealthcareFacility.fromMap(Map<String, dynamic> m) => HealthcareFacility(
    id: m['id'] ?? '',
    name: m['name'] ?? '',
    type: m['type'] ?? 'PHC',
    distanceKm: (m['distance_km'] as num?)?.toDouble() ?? 0.0,
    lat: (m['latitude'] as num?)?.toDouble() ?? 0.0,
    lng: (m['longitude'] as num?)?.toDouble() ?? 0.0,
    phone: m['phone'] ?? '',
    address: m['address'] ?? '',
    hasObstetrician: m['has_obstetrician'] == true,
    hasEmergency24x7: m['has_emergency_24x7'] == true,
    hasPharmacy: m['has_pharmacy'] == true,
    availableSpecialists: List<String>.from(m['available_specialists'] ?? []),
    doctors: (m['doctors'] as List<dynamic>? ?? [])
        .map((d) => DutyDoctor.fromMap(Map<String, dynamic>.from(d)))
        .toList(),
  );
}

// ── App User / Session ────────────────────────────────────────
enum UserRole { asha, anm, healthWorker, doctor, admin, patient }

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? facilityId;
  final String? abhaId;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.facilityId,
    this.abhaId,
  });
}
