import 'package:miracle/core/remote/api_client.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/data/local/db_helper.dart';

class RemoteSyncService {
  static final RemoteSyncService instance = RemoteSyncService._();
  RemoteSyncService._();

  final _db = DbHelper.instance;
  final _api = ApiClient.instance;

  /// Performs a role-aware batch synchronization with the Node.js API Gateway
  Future<Map<String, dynamic>> syncAllUnsynced({bool forceSyncAll = false}) async {
    try {
      final db = await _db.database;
      final sessionUser = await SessionManager.instance.getSession();

      // 1. Gather local SQLite rows (either pending is_synced = 0 or all if forceSyncAll)
      List<Map<String, dynamic>> unsyncedPatients = await db.query('patients', where: 'is_synced = 0');
      List<Map<String, dynamic>> unsyncedVitals = await db.query('vitals', where: 'is_synced = 0');
      List<Map<String, dynamic>> unsyncedRecords = await db.query('medical_records', where: 'is_synced = 0');
      List<Map<String, dynamic>> unsyncedReferrals = await db.query('referrals', where: 'is_synced = 0');
      List<Map<String, dynamic>> unsyncedAppointments = await db.query('appointments', where: 'is_synced = 0');

      if (forceSyncAll || (unsyncedPatients.isEmpty && unsyncedVitals.isEmpty)) {
        unsyncedPatients = await db.query('patients');
        unsyncedVitals = await db.query('vitals');
        unsyncedRecords = await db.query('medical_records');
        unsyncedReferrals = await db.query('referrals');
        unsyncedAppointments = await db.query('appointments');
      }

      // 2. Guarantee Foreign Key integrity:
      // For every dependent record (appointment, vitals, medical records, referrals),
      // ensure its parent patient is included in the upload payload so Supabase foreign keys never fail.
      final referencedPatientIds = <String>{
        ...unsyncedVitals.map((v) => v['patient_id'] as String? ?? ''),
        ...unsyncedRecords.map((r) => r['patient_id'] as String? ?? ''),
        ...unsyncedReferrals.map((r) => r['patient_id'] as String? ?? ''),
        ...unsyncedAppointments.map((a) => a['patient_id'] as String? ?? ''),
      }..remove('');

      final currentPatientIds = unsyncedPatients.map((p) => p['id'] as String).toSet();
      final missingPatientIds = referencedPatientIds.difference(currentPatientIds);

      if (missingPatientIds.isNotEmpty) {
        for (final pId in missingPatientIds) {
          final pRows = await db.query('patients', where: 'id = ?', whereArgs: [pId], limit: 1);
          if (pRows.isNotEmpty) {
            unsyncedPatients.add(pRows.first);
          }
        }
      }

      final totalPending = unsyncedPatients.length +
          unsyncedVitals.length +
          unsyncedRecords.length +
          unsyncedReferrals.length +
          unsyncedAppointments.length;

      // 2. If nothing to upload locally, attempt cloud download directly
      if (totalPending == 0) {
        final downloadResult = await downloadCloudData();
        return {
          'success': true,
          'message': downloadResult['downloadedCount'] > 0
              ? 'Local storage updated: Downloaded ${downloadResult['downloadedCount']} new records from cloud.'
              : 'All records are already up to date with the cloud.',
          'syncedCount': 0,
          'downloadedCount': downloadResult['downloadedCount'] ?? 0,
        };
      }

      // 3. Post payload to /api/sync/batch (Push + Pull)
      final payload = {
        'patients': unsyncedPatients,
        'vitals': unsyncedVitals,
        'medical_records': unsyncedRecords,
        'referrals': unsyncedReferrals,
        'appointments': unsyncedAppointments,
        'client_timestamp': DateTime.now().toIso8601String(),
        'user_id': sessionUser?.id ?? 'guest',
        'user_role': sessionUser?.role.name ?? 'patient',
        'user_phone': sessionUser?.phone ?? '',
        'user_abha_id': sessionUser?.abhaId ?? '',
      };

      final response = await _api.post('/sync/batch', payload);

      if (response['success'] == true) {
        // 4. Mark local rows as synced
        for (final p in unsyncedPatients) {
          await db.update('patients', {'is_synced': 1}, where: 'id = ?', whereArgs: [p['id']]);
        }
        for (final v in unsyncedVitals) {
          await db.update('vitals', {'is_synced': 1}, where: 'id = ?', whereArgs: [v['id']]);
        }
        for (final r in unsyncedRecords) {
          await db.update('medical_records', {'is_synced': 1}, where: 'id = ?', whereArgs: [r['id']]);
        }
        for (final r in unsyncedReferrals) {
          await db.update('referrals', {'is_synced': 1}, where: 'id = ?', whereArgs: [r['id']]);
        }
        for (final a in unsyncedAppointments) {
          await db.update('appointments', {'is_synced': 1}, where: 'id = ?', whereArgs: [a['id']]);
        }

        // 5. Merge downloaded cloud records returned by server
        int downloadedCount = 0;
        if (response['pulled_records'] != null && response['pulled_records'] is Map) {
          final pulled = response['pulled_records'] as Map<String, dynamic>;
          downloadedCount = await _db.upsertDownloadedData(
            patients: pulled['patients'] as List? ?? [],
            vitals: pulled['vitals'] as List? ?? [],
            records: pulled['medical_records'] as List? ?? [],
            referrals: pulled['referrals'] as List? ?? [],
            appointments: pulled['appointments'] as List? ?? [],
          );
        }

        return {
          'success': true,
          'message': downloadedCount > 0
              ? 'Uploaded $totalPending local records & downloaded $downloadedCount cloud records.'
              : 'Successfully uploaded $totalPending records to cloud gateway.',
          'syncedCount': totalPending,
          'downloadedCount': downloadedCount,
        };
      } else {
        // Gateway offline or error: records remain is_synced = 0 for retry
        return {
          'success': false,
          'message': response['message'] ?? 'Unable to connect to cloud gateway.',
          'isOffline': response['isOffline'] ?? false,
          'syncedCount': 0,
          'downloadedCount': 0,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Sync error: $e',
        'syncedCount': 0,
        'downloadedCount': 0,
      };
    }
  }

  /// Explicitly pulls and downloads latest cloud records under active user access
  Future<Map<String, dynamic>> downloadCloudData() async {
    try {
      final sessionUser = await SessionManager.instance.getSession();
      final queryParams = {
        'role': sessionUser?.role.name ?? 'patient',
        'user_id': sessionUser?.id ?? '',
        'phone': sessionUser?.phone ?? '',
        'abha_id': sessionUser?.abhaId ?? '',
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final res = await _api.get('/sync/pull?$queryString');

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final inserted = await _db.upsertDownloadedData(
          patients: data['patients'] as List? ?? [],
          vitals: data['vitals'] as List? ?? [],
          records: data['medical_records'] as List? ?? [],
          referrals: data['referrals'] as List? ?? [],
          appointments: data['appointments'] as List? ?? [],
        );

        return {
          'success': true,
          'message': 'Downloaded and updated $inserted cloud records into local storage.',
          'downloadedCount': inserted,
        };
      } else {
        return {
          'success': false,
          'message': res['message'] ?? 'Could not retrieve cloud records.',
          'downloadedCount': 0,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Download failed: $e',
        'downloadedCount': 0,
      };
    }
  }
}
