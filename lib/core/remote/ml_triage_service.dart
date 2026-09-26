// ============================================================
// MediReach — ML Triage Service
// Calls Node.js API Gateway -> Python ML Microservice
// with instant offline fallback to local clinical rules
// ============================================================
import 'package:miracle/core/remote/api_client.dart';

class MlTriageService {
  static final MlTriageService instance = MlTriageService._();
  MlTriageService._();

  final _api = ApiClient.instance;

  /// Evaluates clinical vitals with cloud ML or offline fallback rules
  Future<Map<String, dynamic>> evaluateTriage({
    required String patientId,
    required int age,
    required int systolicBp,
    required int diastolicBp,
    required int pulseRate,
    required double temperature,
    required int spo2,
    double bloodGlucose = 0.0,
    bool isPregnant = false,
    int pregnancyWeeks = 0,
    List<String> symptoms = const [],
  }) async {
    // 1. Try cloud evaluation via Gateway (:5000 -> :8001)
    final payload = {
      'patient_id': patientId,
      'age': age,
      'systolic_bp': systolicBp,
      'diastolic_bp': diastolicBp,
      'pulse_rate': pulseRate,
      'temperature': temperature,
      'spo2': spo2,
      'blood_glucose': bloodGlucose,
      'is_pregnant': isPregnant,
      'pregnancy_weeks': pregnancyWeeks,
      'symptoms': symptoms,
    };

    final response = await _api.post('/vitals', payload);

    if (response['success'] == true && response['data'] != null) {
      final triageData = response['data']['triage'] as Map<String, dynamic>;
      return {
        'riskLevel': triageData['risk_level'] ?? 'LOW',
        'confidence': (triageData['confidence'] as num?)?.toDouble() ?? 0.95,
        'flag': triageData['flag'] ?? 'ML Risk Stratification',
        'recommendation': triageData['recommended_action'] ?? 'Standard follow-up.',
        'isOfflineFallback': false,
      };
    }

    // 2. Instant On-Device Clinical Fallback Rules (Safe & Deterministic)
    if (spo2 > 0 && spo2 < 90) {
      return {
        'riskLevel': 'EMERGENCY',
        'confidence': 0.99,
        'flag': 'Critical Hypoxia Alert (SpO2 < 90%)',
        'recommendation': 'Immediate emergency referral & supplemental oxygen.',
        'isOfflineFallback': true,
      };
    }

    if (isPregnant && (systolicBp >= 160 || diastolicBp >= 110)) {
      return {
        'riskLevel': 'HIGH',
        'confidence': 0.97,
        'flag': 'Pre-eclampsia Risk (Hypertension in Pregnancy)',
        'recommendation': 'Immediate referral to Obstetric Specialist at CHC / Hospital.',
        'isOfflineFallback': true,
      };
    }

    if (systolicBp >= 140 || diastolicBp >= 90 || temperature >= 38.5) {
      return {
        'riskLevel': 'HIGH',
        'confidence': 0.92,
        'flag': 'Elevated Blood Pressure / High Fever',
        'recommendation': 'Referral recommended for physician review.',
        'isOfflineFallback': true,
      };
    }

    if (systolicBp >= 130 || diastolicBp >= 85 || (spo2 >= 90 && spo2 <= 94)) {
      return {
        'riskLevel': 'MEDIUM',
        'confidence': 0.88,
        'flag': 'Borderline Vitals Deviation',
        'recommendation': 'Monitor vitals and schedule routine PHC OPD visit.',
        'isOfflineFallback': true,
      };
    }

    return {
      'riskLevel': 'LOW',
      'confidence': 0.95,
      'flag': 'Stable Vitals',
      'recommendation': 'Vitals are normal. Continue routine community care.',
      'isOfflineFallback': true,
    };
  }
}
