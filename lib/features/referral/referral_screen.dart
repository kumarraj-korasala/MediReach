import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/data/repositories/patient_repository.dart';
import 'package:miracle/features/referral/referral_status_screen.dart';

class ReferralScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const ReferralScreen({super.key, this.patientId, this.patientName});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  List<Patient> _patients = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String _fromFacility = 'Primary Health Center (PHC) - Rampur';
  String _toFacility = 'District Hospital - Belagavi';
  String _urgencyLevel = 'Urgent'; // Routine | Urgent | Emergency

  static const _fromFacilities = [
    'Primary Health Center (PHC) - Rampur',
    'Sub-Center Karoshi',
    'ASHA Outreach Point - Ward 3',
    'Community Health Center (CHC) - Gokak',
  ];

  static const _toFacilities = [
    'District Hospital - Belagavi',
    'Community Health Center (CHC) - Gokak',
    'Sub-District Hospital (SDH) - Hukkeri',
    'KIMS Medical College Hospital - Hubballi',
  ];

  static const _urgencies = ['Routine', 'Urgent', 'Emergency'];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _selectedPatientName = widget.patientName;
    _loadPatients();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final patients = await PatientRepository.instance.getAll();
    if (mounted) {
      setState(() {
        _patients = patients;
        _isLoading = false;
        if (_selectedPatientId == null && patients.isNotEmpty) {
          _selectedPatientId = patients.first.id;
          _selectedPatientName = patients.first.name;
        } else if (_selectedPatientId != null && _selectedPatientName == null) {
          final match = patients.where((p) => p.id == _selectedPatientId);
          if (match.isNotEmpty) {
            _selectedPatientName = match.first.name;
          }
        }
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
          'Create Patient Referral',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'View All Referrals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferralStatusScreen(
                    patientId: _selectedPatientId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingPage),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientSelectionCard(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildRoutingCard(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildClinicalReasonCard(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildUrgencySelector(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildSubmitButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPatientSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Patient Information', style: AppTextStyles.subheading),
            ],
          ),
          const SizedBox(height: 12),
          if (_patients.isEmpty)
            const Text(
              'No patients found. Please register a patient first.',
              style: AppTextStyles.caption,
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedPatientId,
              decoration: InputDecoration(
                labelText: 'Select Patient',
                labelStyle: AppTextStyles.caption,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
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
                  _selectedPatientName = _patients
                      .firstWhere((p) => p.id == id,
                          orElse: () => _patients.first)
                      .name;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRoutingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Facility Routing', style: AppTextStyles.subheading),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _fromFacility,
            decoration: InputDecoration(
              labelText: 'Referring From (Source)',
              labelStyle: AppTextStyles.caption,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _fromFacilities.map((f) {
              return DropdownMenuItem(value: f, child: Text(f, style: AppTextStyles.body));
            }).toList(),
            onChanged: (v) => setState(() => _fromFacility = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _toFacility,
            decoration: InputDecoration(
              labelText: 'Referred To (Destination Center)',
              labelStyle: AppTextStyles.caption,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _toFacilities.map((f) {
              return DropdownMenuItem(value: f, child: Text(f, style: AppTextStyles.body));
            }).toList(),
            onChanged: (v) => setState(() => _toFacility = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Clinical Reason & Summary', style: AppTextStyles.subheading),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Primary Reason / Diagnosis *',
              hintText: 'e.g. High Risk Pregnancy, Severe Hypertension',
              labelStyle: AppTextStyles.caption,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter primary reason' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clinicalNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Clinical Observations / Notes',
              hintText: 'Vitals, symptoms, preliminary medication given...',
              labelStyle: AppTextStyles.caption,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencySelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_on_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Priority / Urgency Level', style: AppTextStyles.subheading),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _urgencies.map((u) {
              final selected = _urgencyLevel == u;
              Color chipColor;
              if (u == 'Emergency') {
                chipColor = AppColors.statusRed;
              } else if (u == 'Urgent') {
                chipColor = AppColors.statusAmber;
              } else {
                chipColor = AppColors.statusGreen;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _urgencyLevel = u),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? chipColor
                            : chipColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusPill),
                        border: Border.all(color: chipColor),
                      ),
                      child: Text(
                        u,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? AppColors.textOnPrimary
                              : chipColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReferral,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.textOnPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Generate Referral & Digital Pass',
                style: AppTextStyles.buttonLabel,
              ),
      ),
    );
  }

  Future<void> _submitReferral() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or register a patient first'),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reasonText = _clinicalNotesController.text.trim().isNotEmpty
          ? '${_reasonController.text.trim()} | [Notes: ${_clinicalNotesController.text.trim()}] [Urgency: $_urgencyLevel]'
          : '${_reasonController.text.trim()} [Urgency: $_urgencyLevel]';

      final referral = await PatientRepository.instance.createReferral(
        patientId: _selectedPatientId!,
        fromFacility: _fromFacility,
        toFacility: _toFacility,
        reason: reasonText,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _showReferralSuccessDialog(referral);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate referral: $e'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  void _showReferralSuccessDialog(Referral ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.statusGreen, size: 28),
            const SizedBox(width: 8),
            const Text('Referral Created', style: AppTextStyles.heading),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Text(
                'Referral ID: ${ref.id}',
                style: AppTextStyles.subheading
                    .copyWith(color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 12),
            Text('Patient: ${_selectedPatientName ?? ref.patientId}',
                style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text('From: ${ref.fromFacility}', style: AppTextStyles.caption),
            Text('To: ${ref.toFacility}',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('Reason: ${ref.reason}', style: AppTextStyles.caption),
            const SizedBox(height: 12),
            // Digital QR placeholder representation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      size: 90, color: AppColors.textPrimary),
                  const SizedBox(height: 4),
                  Text('Scan at Destination Hospital Desk',
                      style: AppTextStyles.caption),
                  Text('Status: Dispatched / In-Transit',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.statusAmber, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferralStatusScreen(
                    patientId: _selectedPatientId,
                  ),
                ),
              );
            },
            child: const Text('View All Referrals'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
  }
}
