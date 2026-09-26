import 'package:flutter/material.dart';
import 'package:miracle/core/localization/app_localizations.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/features/admin/admin_dashboard_screen.dart';
import 'package:miracle/features/appointment/appointment_screen.dart';
import 'package:miracle/features/diagnostics/diagnostics_screen.dart';
import 'package:miracle/features/facilities/nearby_facilities_screen.dart';
import 'package:miracle/features/family/family_records_screen.dart';
import 'package:miracle/features/medicines/medicines_screen.dart';
import 'package:miracle/features/patient/patient_list_screen.dart';
import 'package:miracle/features/referral/referral_status_screen.dart';
import 'package:miracle/features/sync/sync_screen.dart';
import 'package:miracle/features/teleconsult/teleconsult_screen.dart';
import 'package:miracle/features/triage/triage_screen.dart';

import 'package:miracle/core/remote/remote_sync_service.dart';
import 'package:miracle/data/local/db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? _user;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SessionManager.instance.getSession();
    final pending = await DbHelper.instance.getPendingSyncCount();
    if (mounted) {
      setState(() {
        _user = user;
        _pendingSyncCount = pending;
      });
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    final res = await RemoteSyncService.instance.syncAllUnsynced();
    if (mounted) {
      setState(() => _isSyncing = false);
      await _loadUser();
      final isSuccess = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess ? '✅ ${res['message']}' : 'ℹ️ ${res['message']}',
          ),
          backgroundColor:
              isSuccess ? AppColors.statusGreen : AppColors.statusAmber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _user?.name.isNotEmpty == true ? _user!.name : 'Sudharani';
    final userRole = _user?.role ?? UserRole.healthWorker;
    final isAdminOrDoctor = userRole == UserRole.admin || userRole == UserRole.doctor;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, currentLang, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, currentLang, userName, userRole),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingPage),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppDimens.gapMedium),
                        if (isAdminOrDoctor) ...[
                          _buildAdminCommandBanner(context),
                          const SizedBox(height: AppDimens.gapMedium),
                        ],
                        _buildSyncBanner(context),
                        const SizedBox(height: AppDimens.gapMedium),
                        _buildEmergencyBanner(context),
                        const SizedBox(height: AppDimens.gapLarge),
                        _buildSectionLabel(AppLocale.tr('quick_services')),
                        const SizedBox(height: AppDimens.gapSmall),
                        _buildServicesGrid(context, isAdminOrDoctor),
                        const SizedBox(height: AppDimens.gapLarge),
                        _buildSectionLabel(AppLocale.tr('reminders')),
                        const SizedBox(height: AppDimens.gapSmall),
                        _buildReminderCard(),
                        const SizedBox(height: AppDimens.gapLarge),
                        _buildSectionLabel(AppLocale.tr('nearby_healthcare')),
                        const SizedBox(height: AppDimens.gapSmall),
                        _buildNearbyCard(context, 'PHC Rampur', '2.4 km'),
                        _buildNearbyCard(context, 'ASA Hospital', '4 km'),
                        _buildNearbyCard(context, 'KIMS Hospital', '6 km'),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top bar with Active User & Role ──────────────────────────
  Widget _buildTopBar(
      BuildContext context, AppLanguage currentLang, String name, UserRole role) {
    String roleLabel = '🩺 ASHA Field Worker';
    Color roleColor = AppColors.primaryDark;
    if (role == UserRole.admin) {
      roleLabel = '🏛️ Hospital Administrator';
      roleColor = const Color(0xFF1E293B);
    } else if (role == UserRole.doctor) {
      roleLabel = '👨‍⚕️ Medical Officer';
      roleColor = const Color(0xFF1565C0);
    } else if (role == UserRole.patient) {
      roleLabel = '👤 Citizen Patient';
      roleColor = AppColors.statusGreen;
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingPage, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SearchBar(hint: AppLocale.tr('search_hint')),
              ),
              const SizedBox(width: 6),
              // Sync Button Badge in Top Bar
              InkWell(
                onTap: _isSyncing ? null : _triggerSync,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pendingSyncCount > 0
                        ? AppColors.statusAmber.withValues(alpha: 0.15)
                        : AppColors.statusGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    border: Border.all(
                      color: _pendingSyncCount > 0
                          ? AppColors.statusAmber.withValues(alpha: 0.4)
                          : AppColors.statusGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSyncing)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        Icon(
                          _pendingSyncCount > 0
                              ? Icons.cloud_upload_rounded
                              : Icons.cloud_done_rounded,
                          size: 16,
                          color: _pendingSyncCount > 0
                              ? AppColors.statusAmber
                              : AppColors.statusGreen,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _isSyncing
                            ? 'Syncing'
                            : _pendingSyncCount > 0
                                ? '$_pendingSyncCount'
                                : 'Sync',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _pendingSyncCount > 0
                              ? const Color(0xFFB45309)
                              : AppColors.statusGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Language Switcher Badge
              PopupMenuButton<AppLanguage>(
                tooltip: 'Change Language',
                initialValue: currentLang,
                onSelected: (lang) => appLanguageNotifier.value = lang,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate_rounded,
                          size: 16, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        currentLang == AppLanguage.en
                            ? 'EN'
                            : currentLang == AppLanguage.te
                                ? 'తె'
                                : 'हि',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: AppLanguage.en,
                    child: Text('English'),
                  ),
                  const PopupMenuItem(
                    value: AppLanguage.te,
                    child: Text('తెలుగు (Telugu)'),
                  ),
                  const PopupMenuItem(
                    value: AppLanguage.hi,
                    child: Text('हिंदी (Hindi)'),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person,
                    color: AppColors.textOnPrimary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      TextSpan(text: AppLocale.tr('greeting')),
                      TextSpan(
                        text: name,
                        style: AppTextStyles.subheading,
                      ),
                      TextSpan(text: '\n${AppLocale.tr('sub_greeting')}'),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sync Banner (Offline / Online Status) ─────────────────────
  Widget _buildSyncBanner(BuildContext context) {
    final hasPending = _pendingSyncCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasPending
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: hasPending
              ? const Color(0xFFFDE68A)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded,
            color: hasPending ? const Color(0xFFD97706) : AppColors.statusGreen,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending
                      ? '$_pendingSyncCount Records Saved Locally'
                      : 'All Records Synced with Cloud',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: hasPending
                        ? const Color(0xFF92400E)
                        : const Color(0xFF166534),
                  ),
                ),
                Text(
                  hasPending
                      ? 'Tap "Sync to Cloud" to upload to Supabase'
                      : 'Local SQLite & Supabase are in sync',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasPending
                        ? const Color(0xFFB45309)
                        : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSyncing
                ? null
                : () async {
                    await _triggerSync();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPending
                  ? const Color(0xFFD97706)
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
              elevation: 0,
            ),
            child: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    hasPending ? '⚡ Sync' : 'Re-sync',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Admin Command Banner (Only for Admins/Doctors) ───────────
  Widget _buildAdminCommandBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _push(context, const AdminDashboardScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏛️ Hospital Command Desk',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('Inbound Referrals, Bed Triage & Drug Stock',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Emergency banner ──────────────────────────────────────────
  Widget _buildEmergencyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.emergencyBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.emergencyBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/SOS.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Text('🚑  ', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Text(
            'Get Immediate Medical Help',
            style:
                AppTextStyles.subheading.copyWith(color: AppColors.statusRed),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.phone, color: AppColors.statusRed, size: 18),
          Text(' Call',
              style: AppTextStyles.body.copyWith(color: AppColors.statusRed)),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(label, style: AppTextStyles.sectionTitle),
    );
  }

  // ── Services grid ─────────────────────────────────────────────
  Widget _buildServicesGrid(BuildContext context, bool isAdminOrDoctor) {
    final services = [
      _ServiceItem(
        '💉',
        'Diagnostics',
        () => _push(context, const DiagnosticsScreen()),
        imageAsset: 'assets/images/Tests.png',
      ),
      _ServiceItem(
        '📹',
        'Teleconsult',
        () => _push(context, const TeleconsultScreen()),
        imageAsset: 'assets/images/connect.png',
      ),
      _ServiceItem(
        '📅',
        'Appointment',
        () => _push(context, const AppointmentScreen()),
        imageAsset: 'assets/images/book appointment.png',
      ),
      _ServiceItem(
        '🔄',
        'Referrals',
        () => _push(context, const ReferralStatusScreen()),
        imageAsset: 'assets/images/my records.png',
      ),
      _ServiceItem(
        '📋',
        'Directory',
        () => _push(context, const PatientListScreen()),
        imageAsset: 'assets/images/my records.png',
      ),
      _ServiceItem(
        '💊',
        'Medicines',
        () => _push(context, const MedicinesScreen()),
        imageAsset: 'assets/images/medicine.png',
      ),
      _ServiceItem(
        '🤖',
        'AI Triage',
        () => _push(context, const TriageScreen()),
        imageAsset: 'assets/images/triage.png',
      ),
      _ServiceItem(
        '☁️',
        'Cloud Sync',
        () => _push(context, const SyncScreen()),
        icon: Icons.cloud_sync_rounded,
        iconColor: const Color(0xFF0284C7),
        iconBg: const Color(0xFFE0F2FE),
      ),
      if (isAdminOrDoctor)
        _ServiceItem(
          '🏛️',
          'Admin Desk',
          () => _push(context, const AdminDashboardScreen()),
          icon: Icons.admin_panel_settings_rounded,
          iconColor: const Color(0xFF475569),
          iconBg: const Color(0xFFF1F5F9),
        )
      else
        _ServiceItem(
          '👨‍👩‍👧',
          'Family Records',
          () => _push(context, const FamilyRecordsScreen()),
          imageAsset: 'assets/images/family records.png',
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: services.length,
      itemBuilder: (_, i) => _ServiceCard(item: services[i]),
    );
  }

  // ── Reminder card ─────────────────────────────────────────────
  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/Reminders.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Text('💊 ', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Iron & Folic Acid Tablet', style: AppTextStyles.subheading),
                const SizedBox(height: 4),
                Text('1 Tablet Daily After Meal • 9:00 PM',
                    style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: Text(
                    'Next Dose Today',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.statusGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Nearby card ───────────────────────────────────────────────
  Widget _buildNearbyCard(BuildContext context, String name, String distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: appCardDecoration,
      child: Row(
        children: [
          const Icon(Icons.local_hospital_rounded,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.subheading),
                Text('$distance • Open 24/7', style: AppTextStyles.caption),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            onPressed: () => _push(context, const NearbyFacilitiesScreen()),
            child: const Text('Directions'),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Search bar widget ─────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final String hint;
  const _SearchBar({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption,
          prefixIcon:
              const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

// ── Helper models & widgets for grid ──────────────────────────
class _ServiceItem {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final String? imageAsset;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBg;
  const _ServiceItem(
    this.emoji,
    this.label,
    this.onTap, {
    this.imageAsset,
    this.icon,
    this.iconColor,
    this.iconBg,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItem item;
  const _ServiceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: appCardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.imageAsset != null)
              Image.asset(
                item.imageAsset!,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Text(item.emoji, style: const TextStyle(fontSize: 26)),
              )
            else if (item.icon != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconBg ?? AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (item.iconColor ?? AppColors.primary).withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: item.iconColor ?? AppColors.primary,
                ),
              )
            else
              Text(item.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
