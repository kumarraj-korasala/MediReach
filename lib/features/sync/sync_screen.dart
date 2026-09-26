import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:miracle/core/remote/remote_sync_service.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/local/db_helper.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
  Map<String, List<Map<String, dynamic>>> _pendingData = {};
  int _totalPending = 0;
  int _totalPatients = 0;
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() => _isLoading = true);
    final db = DbHelper.instance;
    final pending = await db.getPendingSyncData();
    final allPatients = await db.getAllPatients();

    int totalPending = 0;
    pending.forEach((_, list) => totalPending += list.length);

    if (mounted) {
      setState(() {
        _pendingData = pending;
        _totalPending = totalPending;
        _totalPatients = allPatients.length;
        _isLoading = false;
        _lastSyncTime ??= DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      });
    }
  }

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);

    // Call real Gateway Batch Sync Service (with local SQLite fallback)
    final syncResult = await RemoteSyncService.instance.syncAllUnsynced();

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSyncTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      });

      await _loadSyncStatus();

      if (mounted) {
        final isSuccess = syncResult['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess
                  ? '✅ ${syncResult['message']}'
                  : 'ℹ️ ${syncResult['message']}',
            ),
            backgroundColor: isSuccess ? AppColors.statusGreen : AppColors.statusAmber,
          ),
        );
      }
    }
  }

  Future<void> _performDownload() async {
    setState(() => _isSyncing = true);

    final downloadResult = await RemoteSyncService.instance.downloadCloudData();

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSyncTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      });

      await _loadSyncStatus();

      if (mounted) {
        final isSuccess = downloadResult['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess
                  ? '📥 ${downloadResult['message']}'
                  : 'ℹ️ ${downloadResult['message']}',
            ),
            backgroundColor: isSuccess ? AppColors.statusGreen : AppColors.statusAmber,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text(
          'Offline Data Sync',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingPage),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSyncStatusCard(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildBreakdownCard(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildSyncButton(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildArchitectureExplanation(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatusCard() {
    final hasPending = _totalPending > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: BoxDecoration(
        color: hasPending
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: hasPending ? AppColors.statusAmber : AppColors.statusGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPending ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded,
                color: hasPending ? AppColors.statusAmber : AppColors.statusGreen,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending
                          ? '$_totalPending Records Pending Sync'
                          : 'All Records Synchronized',
                      style: AppTextStyles.heading.copyWith(
                        color: hasPending ? AppColors.statusAmber : AppColors.statusGreen,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last Sync: $_lastSyncTime',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasPending
                ? 'Your local changes are safely saved in SQLite. Connect to internet and tap "Sync Now" to push updates to the district hospital server.'
                : 'All patient registrations, vitals, triage records, and appointments are up to date on both your device and the cloud.',
            style: AppTextStyles.body.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    final pendingPatients = _pendingData['patients']?.length ?? 0;
    final pendingVitals = _pendingData['vitals']?.length ?? 0;
    final pendingRecords = _pendingData['medical_records']?.length ?? 0;
    final pendingReferrals = _pendingData['referrals']?.length ?? 0;
    final pendingAppointments = _pendingData['appointments']?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Local Database Records', style: AppTextStyles.subheading),
          const SizedBox(height: 12),
          _buildItemRow('👥 Patients Registered', '$_totalPatients total', pendingPatients),
          const Divider(height: 16),
          _buildItemRow('🩺 Vitals & Triage Runs', 'Real-time SQLite', pendingVitals),
          const Divider(height: 16),
          _buildItemRow('📋 Medical Encounters', 'Offline cached', pendingRecords),
          const Divider(height: 16),
          _buildItemRow('🔄 Hospital Referrals', 'Digital QR Passes', pendingReferrals),
          const Divider(height: 16),
          _buildItemRow('📅 Specialist Appointments', 'PHC/CHC/Hospital', pendingAppointments),
        ],
      ),
    );
  }

  Widget _buildItemRow(String title, String subtitle, int pendingCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            Text(subtitle, style: AppTextStyles.caption),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: pendingCount > 0
                ? AppColors.statusAmber.withValues(alpha: 0.15)
                : AppColors.statusGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          ),
          child: Text(
            pendingCount > 0 ? '$pendingCount pending' : 'Synced',
            style: AppTextStyles.caption.copyWith(
              color: pendingCount > 0 ? AppColors.statusAmber : AppColors.statusGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSyncing ? null : _performSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
            ),
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync_rounded, color: AppColors.textOnPrimary),
            label: Text(
              _isSyncing ? 'Synchronizing with Server...' : 'Bi-Directional Sync (Upload & Download)',
              style: AppTextStyles.buttonLabel,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSyncing ? null : _performDownload,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
            ),
            icon: const Icon(Icons.cloud_download_rounded, color: AppColors.primary),
            label: const Text(
              '📥 Download Latest from Cloud (Pull Only)',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArchitectureExplanation() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Offline-First Data Security & Sync',
                  style: AppTextStyles.subheading),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '1. All operations write to local SQLite with `is_synced = 0`.\n'
            '2. Full app usability (vitals recording, triage, referrals, appointments) requires zero internet.\n'
            '3. When network is available, pending records sync automatically in background batches.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
