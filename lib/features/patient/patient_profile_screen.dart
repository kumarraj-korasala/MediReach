import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/data/repositories/patient_repository.dart';
import 'package:miracle/features/appointment/appointment_screen.dart';
import 'package:miracle/features/patient/vitals_entry_screen.dart';
import 'package:miracle/features/referral/referral_screen.dart';
import 'package:miracle/features/referral/referral_status_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  /// Pass [patientId] to load from DB, or [patient] directly for static preview.
  final String? patientId;
  final Patient? patient;

  const PatientProfileScreen({super.key, this.patientId, this.patient})
      : assert(patientId != null || patient != null,
            'Provide either patientId or patient');

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Patient? _patient;
  Vitals? _vitals;
  List<MedicalRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = PatientRepository.instance;
    final p = widget.patient ?? await repo.getById(widget.patientId!);
    if (p == null) {
      setState(() => _loading = false);
      return;
    }
    final vitals  = await repo.getLatestVitals(p.id);
    final records = await repo.getRecords(p.id);
    setState(() {
      _patient = p;
      _vitals  = vitals;
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_patient == null) {
      return const Scaffold(
        body: Center(child: Text('Patient not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VitalsEntryScreen(patient: _patient!),
          ),
        ).then((_) => _load()),
        backgroundColor: AppColors.primary,
        label: const Text('Record Vitals',
            style: TextStyle(color: AppColors.textOnPrimary)),
        icon: const Icon(Icons.monitor_heart_rounded,
            color: AppColors.textOnPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingPage),
        child: Column(
          children: [
            _buildPatientCard(),
            const SizedBox(height: AppDimens.gapMedium),
            _buildQuickActions(),
            const SizedBox(height: AppDimens.gapLarge),
            _buildHealthSummaryCard(),
            const SizedBox(height: AppDimens.gapLarge),
            _buildRecentRecordsSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final p = _patient!;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAmber,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
            ),
            icon: const Icon(Icons.swap_horiz_rounded,
                color: AppColors.textOnPrimary, size: 18),
            label: const Text('Refer',
                style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferralScreen(
                    patientId: p.id,
                    patientName: p.name,
                  ),
                ),
              ).then((_) => _load());
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBlue,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
            ),
            icon: const Icon(Icons.calendar_month_rounded,
                color: AppColors.textOnPrimary, size: 18),
            label: const Text('Appointment',
                style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentScreen(
                    patientId: p.id,
                    patientName: p.name,
                  ),
                ),
              ).then((_) => _load());
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
            ),
            icon: const Icon(Icons.history_rounded,
                color: AppColors.primary, size: 18),
            label: const Text('Passes',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferralStatusScreen(
                    patientId: p.id,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeletePatient(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.statusRed),
            SizedBox(width: 8),
            Text('Delete Patient Record?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the profile and all local vitals/records for "${_patient?.name}"?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _patient != null) {
      await PatientRepository.instance.deletePatient(_patient!.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Removed record for ${_patient!.name}'),
            backgroundColor: AppColors.statusRed,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      title: const Text('Patient Profile',
          style: TextStyle(
              color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textOnPrimary),
          tooltip: 'Delete Patient Record',
          onPressed: () => _confirmDeletePatient(context),
        ),
      ],
    );
  }

  Widget _buildPatientCard() {
    final p = _patient!;
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Row(
        children: [
          Column(
            children: [
              const Text('👑', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Patient Profile:', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AppTextStyles.heading),
                const SizedBox(height: 2),
                Text('Age: ${p.age}', style: AppTextStyles.body),
                Text('Patient ID: ${p.id}', style: AppTextStyles.caption),
                Text('Blood Group: ${p.bloodGroup}',
                    style: AppTextStyles.caption),
                if (p.isPregnant)
                  Text('🤰 Pregnant${p.pregnancyWeek != null ? ' — Week ${p.pregnancyWeek}' : ''}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.statusAmber)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.person,
                color: AppColors.primaryDark, size: 34),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard() {
    final v = _vitals;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🩺 ', style: TextStyle(fontSize: 14)),
              Text('Current Health Summary',
                  style: AppTextStyles.subheading),
              if (v != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _riskBg(v.riskLevel),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusPill),
                  ),
                  child: Text(
                    '${v.riskLevel.emoji} ${v.riskLevel.label}',
                    style: AppTextStyles.caption
                        .copyWith(color: _riskColor(v.riskLevel)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (v == null)
            const Text('No vitals recorded yet.',
                style: AppTextStyles.caption)
          else ...[
            // Table header
            Row(children: [
              Expanded(child: Text('Vital',     style: _bold)),
              Expanded(child: Text('Result',    style: _bold)),
              Expanded(child: Text('Status',    style: _bold)),
            ]),
            const Divider(height: 8),
            _vitalRow('Blood Pressure', v.bpDisplay, v.riskLevel),
            _vitalRow('Blood Sugar',
                v.bloodSugar != null ? '${v.bloodSugar!.toStringAsFixed(0)} mg/dL' : '--',
                v.riskLevel),
            _vitalRow('Pulse',
                v.pulse != null ? '${v.pulse!.toStringAsFixed(0)} bpm' : '--',
                RiskLevel.low),
            _vitalRow('Hemoglobin',
                v.hemoglobin != null ? '${v.hemoglobin!.toStringAsFixed(1)} g/dL' : '--',
                RiskLevel.low),
            if (v.temperature != null)
              _vitalRow('Temperature',
                  '${v.temperature!.toStringAsFixed(1)} °F',
                  RiskLevel.low),
          ],
        ],
      ),
    );
  }

  Widget _vitalRow(String name, String result, RiskLevel risk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AppTextStyles.body)),
          Expanded(child: Text(result, style: AppTextStyles.body)),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: _riskColor(risk)),
                const SizedBox(width: 4),
                Text(
                  risk == RiskLevel.low ? 'Normal' : risk.label,
                  style: AppTextStyles.body
                      .copyWith(color: _riskColor(risk)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Text('🗂️ ', style: TextStyle(fontSize: 14)),
              Text('Recent Medical Records',
                  style: AppTextStyles.subheading),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.gapSmall),
        if (_records.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingCard),
            decoration: appCardDecoration,
            child: const Text('No records yet.', style: AppTextStyles.caption),
          )
        else
          ..._records.map((r) => _recordCard(r)),
      ],
    );
  }

  Widget _recordCard(MedicalRecord r) {
    final statusColor = r.status == 'Completed'
        ? AppColors.statusGreen
        : r.status == 'Available'
            ? AppColors.statusBlue
            : AppColors.statusAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapSmall),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd MMM yyyy').format(r.date),
              style: AppTextStyles.subheading
                  .copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Status: ', style: AppTextStyles.caption),
              Text(r.status,
                  style: AppTextStyles.caption
                      .copyWith(color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
          if (r.tests.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('✅ ${r.tests.join(' + ')}', style: AppTextStyles.body),
          ],
          Text('${r.doctorName} - ${r.specialty}',
              style: AppTextStyles.caption),
          Text('Report: ${r.status}', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Color _riskColor(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:       return AppColors.statusGreen;
      case RiskLevel.moderate:  return AppColors.statusAmber;
      case RiskLevel.high:
      case RiskLevel.emergency: return AppColors.statusRed;
    }
  }

  Color _riskBg(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:       return const Color(0xFFE8F5E9);
      case RiskLevel.moderate:  return const Color(0xFFFFF8E1);
      case RiskLevel.high:
      case RiskLevel.emergency: return const Color(0xFFFFEBEE);
    }
  }

  static final _bold = AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold);
}
