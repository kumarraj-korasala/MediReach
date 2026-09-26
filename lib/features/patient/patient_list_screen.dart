import 'package:flutter/material.dart';
import 'package:miracle/core/remote/remote_sync_service.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/data/repositories/patient_repository.dart';
import 'package:miracle/features/patient/patient_profile_screen.dart';
import 'package:miracle/features/patient/patient_registration_screen.dart';
import 'package:miracle/features/sync/sync_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _patients = [];
  List<Patient> _filtered = [];
  final _searchCtrl = TextEditingController();
  int _pendingCount = 0;
  bool _isSyncing = false;
  bool _loading = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUserAndPatients();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndPatients() async {
    final user = await SessionManager.instance.getSession();
    final scopedList = await PatientRepository.instance.getScopedPatients(user);
    final pending = await PatientRepository.instance.getPendingSyncCount();

    if (mounted) {
      setState(() {
        _user = user;
        _patients = scopedList;
        _filtered = scopedList;
        _pendingCount = pending;
        _loading = false;
      });
    }
  }

  Future<void> _loadPatients() async {
    await _loadUserAndPatients();
  }

  Future<void> _triggerQuickSync() async {
    setState(() => _isSyncing = true);
    final res = await RemoteSyncService.instance.syncAllUnsynced();
    if (mounted) {
      setState(() => _isSyncing = false);
      await _loadUserAndPatients();
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

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _patients
          : _patients.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q) ||
              p.phone.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = _user?.role == UserRole.patient;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const PatientRegistrationScreen()),
        ).then((_) => _loadPatients()),
        backgroundColor: AppColors.primary,
        label: Text(
          isPatient ? 'Add Family Member' : 'New Patient',
          style: const TextStyle(color: AppColors.textOnPrimary),
        ),
        icon: Icon(
          isPatient ? Icons.group_add_rounded : Icons.person_add_rounded,
          color: AppColors.textOnPrimary,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildRoleBanner(isPatient),
            _buildHeader(),
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline,
                          size: 60, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _patients.isEmpty
                            ? (isPatient
                                ? 'No personal or family records found.\nTap + to link your family profile.'
                                : 'No patients registered yet.\nTap + to add your first patient.')
                            : 'No results for "${_searchCtrl.text}"',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPatients,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.paddingPage, AppDimens.paddingPage,
                        AppDimens.paddingPage, 80),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _PatientCard(
                      patient: _filtered[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientProfileScreen(
                              patientId: _filtered[i].id),
                        ),
                      ).then((_) => _loadPatients()),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBanner(bool isPatient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPatient ? const Color(0xFFE8F5E9) : const Color(0xFFE0F2FE),
        border: Border(
          bottom: BorderSide(
            color: isPatient ? Colors.green.shade200 : Colors.blue.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPatient ? Icons.folder_shared_rounded : Icons.domain_rounded,
            size: 18,
            color: isPatient ? Colors.green.shade800 : Colors.blue.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPatient
                  ? 'Personal & Family Health Locker (ABHA Encrypted)'
                  : 'Catchment Registry • Health Sub-Center / PHC Level',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPatient ? Colors.green.shade900 : Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingPage, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search records...',
                        hintStyle: AppTextStyles.caption,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Interactive Batch Sync Button
          Tooltip(
            message: 'Sync records with Supabase cloud',
            child: InkWell(
              onTap: _isSyncing ? null : _triggerQuickSync,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _pendingCount > 0
                      ? AppColors.statusAmber.withValues(alpha: 0.15)
                      : AppColors.statusGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  border: Border.all(
                    color: _pendingCount > 0
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
                        _pendingCount > 0
                            ? Icons.cloud_upload_rounded
                            : Icons.cloud_done_rounded,
                        size: 16,
                        color: _pendingCount > 0
                            ? AppColors.statusAmber
                            : AppColors.statusGreen,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      _isSyncing
                          ? 'Syncing'
                          : _pendingCount > 0
                              ? 'Sync ($_pendingCount)'
                              : 'Synced',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _pendingCount > 0
                            ? const Color(0xFFB45309)
                            : AppColors.statusGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Sync Center',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncScreen()),
            ).then((_) => _loadPatients()),
          ),
        ],
      ),
    );
  }
}

// ── Patient card ──────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determine status from pregnancy / age heuristic for display
    final isHighRisk = patient.isPregnant || patient.age > 60;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapMedium),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.person,
                color: AppColors.primaryDark, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isHighRisk
                          ? AppColors.statusAmber
                          : AppColors.statusGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(patient.name, style: AppTextStyles.subheading),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Age: ${patient.age} • ${patient.bloodGroup}',
                    style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  isHighRisk ? '🟡 Follow up Required' : '🟢 Health Stable',
                  style: AppTextStyles.caption.copyWith(
                    color: isHighRisk
                        ? AppColors.statusAmber
                        : AppColors.statusGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              '--->View Records',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
