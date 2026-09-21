import 'package:flutter/material.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/local/db_helper.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/features/sync/sync_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});
  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppUser? _user;
  int _pendingRecords = 0;
  int _totalPatients = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = await SessionManager.instance.getSession();
    final pending = await DbHelper.instance.getPendingSyncCount();
    final patients = await DbHelper.instance.getAllPatients();

    if (mounted) {
      setState(() {
        _user = user;
        _pendingRecords = pending;
        _totalPatients = patients.length;
        _loading = false;
      });
    }
  }

  Future<void> _confirmClearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusRed),
            SizedBox(width: 8),
            Text('Clear Local Storage?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all offline patients, vitals, medical records, referrals, and appointments stored on this device.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DbHelper.instance.clearAllData();
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Local database cleared successfully.'),
            backgroundColor: AppColors.statusRed,
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
        title: Text(widget.title,
            style: const TextStyle(
                color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textOnPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingPage),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('👤 Authenticated Account'),
                  _buildAccountCard(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildSectionHeader('💾 Local Offline Storage & Sync'),
                  _buildStorageCard(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildSectionHeader('🌐 Microservices & Gateway Connectivity'),
                  _buildConnectivityCard(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildSectionHeader('⚠️ Danger Zone'),
                  _buildDangerZone(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: AppTextStyles.subheading.copyWith(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    final name = _user?.name ?? 'Guest User';
    final role = _user?.role.name.toUpperCase() ?? 'CITIZEN';
    final phone = _user?.phone ?? 'Not set';

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.person, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.subheading),
                    Text('$role • $phone', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ABHA ID', style: AppTextStyles.caption),
              Text(_user?.abhaId ?? 'Not linked',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        children: [
          _buildInfoRow('Local SQLite Database', 'medireach.db (v1)'),
          const Divider(height: 16),
          _buildInfoRow('Total Registered Patients', '$_totalPatients records'),
          const Divider(height: 16),
          _buildInfoRow('Pending Cloud Sync Queue', '$_pendingRecords records'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Open Sync & Inspection Hub'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncScreen()),
              ).then((_) => _loadStats()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        children: [
          _buildInfoRow('Node.js REST Gateway', 'http://localhost:5000/api'),
          const Divider(height: 16),
          _buildInfoRow('Python ML Microservice', 'http://localhost:8001'),
          const Divider(height: 16),
          _buildInfoRow('Cloud Database (Supabase)', 'PostgreSQL Relational'),
          const Divider(height: 16),
          _buildInfoRow('Notification Service (FCM)', 'Firebase Push Cloud'),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: AppColors.statusRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Delete Stored Local Data',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusRed,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Purge all patient records, vitals, referrals, and appointments cached locally on this device.',
            style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmClearDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                ),
              ),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Purge Local Database (Delete Data)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
