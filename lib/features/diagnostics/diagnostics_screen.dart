import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/data/repositories/patient_repository.dart';

class DiagnosticsScreen extends StatefulWidget {
  final String? patientId;
  const DiagnosticsScreen({super.key, this.patientId});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  List<Patient> _patients = [];
  String? _selectedPatientId;
  Patient? _selectedPatient;
  Vitals? _latestVitals;
  List<MedicalRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = PatientRepository.instance;
    final patients = await repo.getAll();

    if (patients.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _selectedPatientId ??= patients.first.id;
    final patient = patients.firstWhere(
      (p) => p.id == _selectedPatientId,
      orElse: () => patients.first,
    );

    final vitals = await repo.getLatestVitals(patient.id);
    final records = await repo.getRecords(patient.id);

    if (mounted) {
      setState(() {
        _patients = patients;
        _selectedPatientId = patient.id;
        _selectedPatient = patient;
        _latestVitals = vitals;
        _records = records;
        _isLoading = false;
      });
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
          '💉 Diagnostics & Reports',
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
                  _buildPatientDropdown(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildTestGrid(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildVitalsAndNotes(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildLabReportsList(),
                  const SizedBox(height: AppDimens.gapLarge),
                  _buildAddReportButton(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildPatientDropdown() {
    if (_patients.isEmpty) {
      return const Text('No patients registered.', style: AppTextStyles.caption);
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected Patient', style: AppTextStyles.subheading),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPatientId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _patients.map((p) {
              return DropdownMenuItem(
                value: p.id,
                child: Text('${p.name} (${p.id})', style: AppTextStyles.body),
              );
            }).toList(),
            onChanged: (id) {
              setState(() {
                _selectedPatientId = id;
                _isLoading = true;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestGrid() {
    final tests = [
      _TestItem('🩸', 'Blood Profile'),
      _TestItem('🧪', 'Urine Albumin'),
      _TestItem('❤️', 'ECG Rhythm'),
      _TestItem('🦴', 'X-Ray / USG'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: tests.map((t) => _TestCard(test: t)).toList(),
    );
  }

  Widget _buildVitalsAndNotes() {
    final v = _latestVitals;
    final vitals = [
      ['❤️', 'BP:', v?.bpDisplay ?? '--/--'],
      ['🩸', 'Sugar levels:', v?.bloodSugar != null ? '${v!.bloodSugar!.toInt()} mg/dL' : '--'],
      ['💓', 'Pulse:', v?.pulse != null ? '${v!.pulse!.toInt()} bpm' : '--'],
      ['🔬', 'Hemoglobin:', v?.hemoglobin != null ? '${v!.hemoglobin} g/dL' : '--'],
      ['🌡️', 'Temperature:', v?.temperature != null ? '${v!.temperature} °F' : '--'],
    ];

    final isNormal = (v?.riskLevel ?? RiskLevel.low) == RiskLevel.low;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingCard),
            decoration: appCardDecoration,
            child: Column(
              children: vitals.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(item[0]),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item[1], style: AppTextStyles.caption)),
                      Text(item[2],
                          style: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.circle,
                          size: 8,
                          color: isNormal
                              ? AppColors.statusGreen
                              : AppColors.statusAmber),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingCard),
            decoration: appCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clinical Impression',
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isNormal ? 'Status: Normal' : 'Status: Follow-up needed',
                  style: AppTextStyles.caption.copyWith(
                      color: isNormal ? AppColors.statusGreen : AppColors.statusAmber,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPatient?.isPregnant == true
                      ? 'High priority ANC monitoring advised for maternal health.'
                      : 'Vitals recorded in local database and evaluated by triage engine.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabReportsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diagnostic Reports (${_records.length})',
            style: AppTextStyles.subheading),
        const SizedBox(height: 8),
        if (_records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: appCardDecoration,
            child: const Text('No diagnostic reports recorded yet.',
                style: AppTextStyles.caption),
          )
        else
          ..._records.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(AppDimens.paddingCard),
                decoration: appCardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(r.date),
                          style: AppTextStyles.subheading
                              .copyWith(color: AppColors.primary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusGreen.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusPill),
                          ),
                          child: Text(
                            r.status,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.statusGreen,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Tests: ${r.tests.join(', ')}',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    Text('${r.doctorName} (${r.specialty})',
                        style: AppTextStyles.caption),
                    if (r.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Notes: ${r.notes}', style: AppTextStyles.caption),
                    ],
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildAddReportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusPill)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _selectedPatientId == null ? null : () => _showAddReportModal(context),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Add Diagnostic Report',
            style: AppTextStyles.buttonLabel),
      ),
    );
  }

  void _showAddReportModal(BuildContext context) {
    final doctorController = TextEditingController(text: 'Dr. Priya Sharma');
    final specialtyController = TextEditingController(text: 'Pathology & Lab');
    final testsController = TextEditingController(text: 'Complete Blood Count (CBC) + Blood Glucose');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
        title: const Text('Add Diagnostic Lab Report', style: AppTextStyles.heading),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: doctorController,
                decoration: const InputDecoration(
                  labelText: 'Doctor / Lab Officer',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Department / Specialty',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: testsController,
                decoration: const InputDecoration(
                  labelText: 'Tests Performed (separated by | or +)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lab Result Summary / Observations',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill)),
            ),
            onPressed: () async {
              if (testsController.text.trim().isEmpty) return;
              final tests = testsController.text
                  .split(RegExp(r'[|+,\n]'))
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();

              await PatientRepository.instance.addRecord(
                patientId: _selectedPatientId!,
                doctorName: doctorController.text.trim(),
                specialty: specialtyController.text.trim(),
                notes: notesController.text.trim().isEmpty
                    ? 'Report validated and saved in offline record'
                    : notesController.text.trim(),
                status: 'Completed',
                tests: tests.isEmpty ? ['Diagnostic Panel'] : tests,
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                _loadData();
              }

            },
            child: const Text('Save Report', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _TestItem {
  final String emoji, label;
  const _TestItem(this.emoji, this.label);
}

class _TestCard extends StatelessWidget {
  final _TestItem test;
  const _TestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(test.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(test.label, style: AppTextStyles.subheading),
        ],
      ),
    );
  }
}
