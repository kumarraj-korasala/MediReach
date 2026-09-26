// ============================================================
// MediReach — Government ABHA / ABDM API Client Service
// Bridges local SQLite with the National Health Authority (ABDM)
// ============================================================
import 'dart:developer' as dev;
import 'package:miracle/core/remote/api_client.dart';
import 'package:miracle/data/local/db_helper.dart';

class AbhaService {
  AbhaService._();
  static final AbhaService instance = AbhaService._();

  final _api = ApiClient.instance;
  final _db = DbHelper.instance;

  /// Verifies an ABHA ID (14-digit number or name@abdm) with the ABDM network
  Future<Map<String, dynamic>> verifyAbha(String abhaId) async {
    try {
      final clean = abhaId.trim();
      final res = await _api.get('/abha/verify/$clean');
      return res;
    } catch (e) {
      dev.log('[ABHA SERVICE VERIFY ERROR]: $e');
      return {
        'success': false,
        'valid': false,
        'message': 'Failed to verify ABHA ID: $e',
      };
    }
  }

  /// Fetches existing clinical records linked to an ABHA ID and saves them into local SQLite
  Future<Map<String, dynamic>> fetchAndSyncAbhaRecords(String abhaId) async {
    try {
      final clean = abhaId.trim();
      final res = await _api.get('/abha/records/$clean');

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final patients = data['patients'] as List<dynamic>? ?? [];
        final vitals = data['vitals'] as List<dynamic>? ?? [];
        final records = data['medical_records'] as List<dynamic>? ?? [];
        final referrals = data['referrals'] as List<dynamic>? ?? [];
        final appointments = data['appointments'] as List<dynamic>? ?? [];

        final totalUpserted = await _db.upsertDownloadedData(
          patients: patients,
          vitals: vitals,
          records: records,
          referrals: referrals,
          appointments: appointments,
        );

        dev.log('[ABHA SERVICE] Successfully synced $totalUpserted clinical records for ABHA: $clean');

        return {
          'success': true,
          'total_synced': totalUpserted,
          'patients_count': patients.length,
          'records_count': records.length,
          'vitals_count': vitals.length,
        };
      }

      return {
        'success': false,
        'message': res['message'] ?? 'No records found for this ABHA ID.',
      };
    } catch (e) {
      dev.log('[ABHA SERVICE SYNC ERROR]: $e');
      return {
        'success': false,
        'message': 'Error retrieving ABHA records: $e',
      };
    }
  }

  /// Retrieves all family members under a shared family ABHA ID
  Future<List<dynamic>> fetchFamilyMembers(String abhaId) async {
    try {
      final clean = abhaId.trim();
      final res = await _api.get('/abha/family/$clean');
      if (res['success'] == true && res['members'] != null) {
        return res['members'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      dev.log('[ABHA SERVICE FAMILY FETCH ERROR]: $e');
      return [];
    }
  }

  /// Links an ABHA ID to the active user account
  Future<bool> linkAbha(String abhaId) async {
    try {
      final res = await _api.post('/abha/link', {'abha_id': abhaId.trim()});
      return res['success'] == true;
    } catch (e) {
      dev.log('[ABHA SERVICE LINK ERROR]: $e');
      return false;
    }
  }
}
