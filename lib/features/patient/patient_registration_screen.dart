// ============================================================
// MediReach — Patient Registration Screen
// Works fully offline. Saves to SQLite immediately.
// ============================================================
import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/repositories/patient_repository.dart';
import 'package:miracle/features/patient/patient_profile_screen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl   = TextEditingController();
  final _abhaCtrl  = TextEditingController();

  String _gender      = 'Female';
  String _bloodGroup  = 'O+';
  bool _isPregnant    = false;
  bool _saving        = false;

  static const _genders     = ['Female', 'Male', 'Other'];
  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _abhaCtrl.dispose();
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
        title: const Text('Register Patient',
            style: TextStyle(
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
              _label('Full Name *'),
              _textField(
                ctrl: _nameCtrl,
                hint: 'Enter patient name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppDimens.gapMedium),

              _label('Phone Number *'),
              _textField(
                ctrl: _phoneCtrl,
                hint: '+91 9XXXXXXXXX',
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().length < 10) ? 'Enter valid phone' : null,
              ),
              const SizedBox(height: AppDimens.gapMedium),

              _label('Age *'),
              _textField(
                ctrl: _ageCtrl,
                hint: 'e.g. 29',
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || int.tryParse(v) == null) ? 'Enter valid age' : null,
              ),
              const SizedBox(height: AppDimens.gapMedium),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Gender'),
                        _dropdown(
                          value: _gender,
                          items: _genders,
                          onChanged: (v) => setState(() => _gender = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Blood Group'),
                        _dropdown(
                          value: _bloodGroup,
                          items: _bloodGroups,
                          onChanged: (v) => setState(() => _bloodGroup = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gapMedium),

              _label('ABHA / Aadhar ID (optional)'),
              _textField(
                ctrl: _abhaCtrl,
                hint: 'XXXX XXXX XXXX',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimens.gapMedium),

              // ── Pregnancy toggle ───────────────────────────
              if (_gender == 'Female')
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingCard, vertical: 4),
                  decoration: appCardDecoration,
                  child: SwitchListTile(
                    value: _isPregnant,
                    onChanged: (v) => setState(() => _isPregnant = v),
                    title: Text('Currently Pregnant',
                        style: AppTextStyles.body),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

              const SizedBox(height: AppDimens.gapLarge),

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
                      : const Text('Register Patient',
                          style: AppTextStyles.buttonLabel),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final patient = await PatientRepository.instance.register(
        name:        _nameCtrl.text.trim(),
        age:         int.parse(_ageCtrl.text.trim()),
        gender:      _gender,
        phone:       _phoneCtrl.text.trim(),
        bloodGroup:  _bloodGroup,
        abhaId:      _abhaCtrl.text.trim().isEmpty ? null : _abhaCtrl.text.trim(),
        isPregnant:  _isPregnant,
      );
      if (!mounted) return;
      // Navigate to the patient's profile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatientProfileScreen(patientId: patient.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AppTextStyles.sectionTitle),
  );

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.caption,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.statusRed),
        ),
      ),
      style: AppTextStyles.body,
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((v) =>
            DropdownMenuItem(value: v, child: Text(v, style: AppTextStyles.body))
        ).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
