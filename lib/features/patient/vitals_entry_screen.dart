// ============================================================
// MediReach — Vitals Entry Screen
// Health worker records patient vitals; triage runs offline.
// ============================================================
import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/data/repositories/patient_repository.dart';

class VitalsEntryScreen extends StatefulWidget {
  final Patient patient;
  const VitalsEntryScreen({super.key, required this.patient});

  @override
  State<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends State<VitalsEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bpSysCtrl  = TextEditingController();
  final _bpDiaCtrl  = TextEditingController();
  final _sugarCtrl  = TextEditingController();
  final _pulseCtrl  = TextEditingController();
  final _hemoCtrl   = TextEditingController();
  final _tempCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  Vitals? _result;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_bpSysCtrl, _bpDiaCtrl, _sugarCtrl, _pulseCtrl,
                     _hemoCtrl, _tempCtrl, _weightCtrl, _heightCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: Text('Vitals — ${widget.patient.name}',
            style: const TextStyle(
                color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient badge ─────────────────────────────
              _PatientBadge(patient: widget.patient),
              const SizedBox(height: AppDimens.gapLarge),

              // ── Vitals form ───────────────────────────────
              _SectionHeader('Blood Pressure'),
              Row(
                children: [
                  Expanded(
                    child: _VitalField(
                      ctrl: _bpSysCtrl,
                      label: 'Systolic (mmHg)',
                      hint: '120',
                      icon: '❤️',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VitalField(
                      ctrl: _bpDiaCtrl,
                      label: 'Diastolic (mmHg)',
                      hint: '80',
                      icon: '❤️',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gapMedium),
              _SectionHeader('Other Vitals'),
              _VitalField(
                ctrl: _sugarCtrl,
                label: 'Blood Sugar (mg/dL)',
                hint: '96',
                icon: '🩸',
              ),
              const SizedBox(height: 8),
              _VitalField(
                ctrl: _pulseCtrl,
                label: 'Pulse (bpm)',
                hint: '75',
                icon: '💓',
              ),
              const SizedBox(height: 8),
              _VitalField(
                ctrl: _hemoCtrl,
                label: 'Hemoglobin (g/dL)',
                hint: '13',
                icon: '🔬',
              ),
              const SizedBox(height: 8),
              _VitalField(
                ctrl: _tempCtrl,
                label: 'Body Temperature (°F)',
                hint: '98.6',
                icon: '🌡️',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _VitalField(
                      ctrl: _weightCtrl,
                      label: 'Weight (kg)',
                      hint: '60',
                      icon: '⚖️',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VitalField(
                      ctrl: _heightCtrl,
                      label: 'Height (cm)',
                      hint: '160',
                      icon: '📏',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gapLarge),

              // ── Save button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusPill)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary),
                        )
                      : const Text('Save & Run Triage',
                          style: AppTextStyles.buttonLabel),
                ),
              ),

              // ── Triage result ─────────────────────────────
              if (_result != null) ...[
                const SizedBox(height: AppDimens.gapLarge),
                _TriageResult(vitals: _result!),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final vitals = await PatientRepository.instance.recordVitals(
        patientId:   widget.patient.id,
        bpSystolic:  double.tryParse(_bpSysCtrl.text),
        bpDiastolic: double.tryParse(_bpDiaCtrl.text),
        bloodSugar:  double.tryParse(_sugarCtrl.text),
        pulse:       double.tryParse(_pulseCtrl.text),
        hemoglobin:  double.tryParse(_hemoCtrl.text),
        temperature: double.tryParse(_tempCtrl.text),
        weight:      double.tryParse(_weightCtrl.text),
        height:      double.tryParse(_heightCtrl.text),
      );
      setState(() => _result = vitals);
    } finally {
      setState(() => _saving = false);
    }
  }
}

// ── Patient badge ─────────────────────────────────────────────
class _PatientBadge extends StatelessWidget {
  final Patient patient;
  const _PatientBadge({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.person,
                color: AppColors.primaryDark, size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.name, style: AppTextStyles.subheading),
              Text('${patient.age} yrs • ${patient.gender} • ${patient.bloodGroup}',
                  style: AppTextStyles.caption),
              Text(patient.id, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Triage result card ────────────────────────────────────────
class _TriageResult extends StatelessWidget {
  final Vitals vitals;
  const _TriageResult({required this.vitals});

  static const _bgColors = [
    Color(0xFFE8F5E9), // low - green tint
    Color(0xFFFFF8E1), // moderate - amber tint
    Color(0xFFFFEBEE), // high - red tint
    Color(0xFFFFCDD2), // emergency - deep red tint
  ];
  static const _borderColors = [
    AppColors.statusGreen,
    AppColors.statusAmber,
    AppColors.statusRed,
    AppColors.statusRed,
  ];

  @override
  Widget build(BuildContext context) {
    final i = vitals.riskLevel.index;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: BoxDecoration(
        color: _bgColors[i],
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: _borderColors[i], width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            '${vitals.riskLevel.emoji} ${vitals.riskLevel.label}',
            style: AppTextStyles.heading
                .copyWith(color: _borderColors[i]),
          ),
          const SizedBox(height: 8),
          Text(
            vitals.riskLevel == RiskLevel.low
                ? 'Patient is stable. Continue routine monitoring.'
                : vitals.riskLevel == RiskLevel.moderate
                    ? 'Schedule an appointment with a doctor soon.'
                    : 'Immediate medical attention required!',
            style: AppTextStyles.body.copyWith(color: _borderColors[i]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'BP: ${vitals.bpDisplay} mmHg  |  '
            'Sugar: ${vitals.bloodSugar?.toStringAsFixed(0) ?? '--'} mg/dL  |  '
            'Pulse: ${vitals.pulse?.toStringAsFixed(0) ?? '--'} bpm',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Reusable section header ───────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.sectionTitle),
    );
  }
}

// ── Reusable vital input field ────────────────────────────────
class _VitalField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final String icon;

  const _VitalField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '$icon  $label',
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      style: AppTextStyles.body,
    );
  }
}
