import 'package:flutter/material.dart';
import 'package:miracle/core/audio/tts_helper.dart';
import 'package:miracle/core/remote/ml_triage_service.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/features/appointment/appointment_screen.dart';
import 'package:miracle/features/facilities/nearby_facilities_screen.dart';
import 'package:miracle/features/teleconsult/teleconsult_screen.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  // ── State ─────────────────────────────────────────────────────
  final List<String> _selectedSymptoms = [];
  int _durationIndex = 1;           // 0=Today, 1=1-2days, 2=3-6days, 3=Week+
  int _severityIndex = 1;           // 0=Mild, 1=Moderate, 2=Severe
  final Set<String> _extraSymptoms = {};
  final Set<String> _conditions = {'None'};
  bool _takingMedicine = false;
  bool _hadBefore = true;
  bool _showResult = false;
  bool _isEvaluating = false;
  Map<String, dynamic>? _mlTriageResult;

  static const _symptomChips = ['Fever', 'Headache', 'Cough', 'Vomiting',
    'Chest Pain', 'Fatigue', 'Dizziness'];
  static const _durations = ['Today', '1 - 2 Days ago', '3 - 6 Days ago',
    'More Than a Week'];
  static const _severities = ['Mild', 'Moderate', 'Severe'];
  static const _severityColors = [
    AppColors.statusGreen, AppColors.statusAmber, AppColors.statusRed
  ];
  static const _extraList = [
    'Difficulty Breathing', 'Continuous Vomiting', 'Severe weakness'
  ];
  static const _conditionList = [
    'Diabetes', 'BP', 'Asthma', 'Heart condition', 'Other', 'None'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text('🤖 Digital Triage',
            style: TextStyle(
                color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: AppDimens.gapLarge),
            _buildSymptomSearch(),
            const SizedBox(height: AppDimens.gapMedium),
            _buildSymptomChips(),
            const SizedBox(height: AppDimens.gapLarge),
            _buildSection('When did your Symptoms Start?',
                _buildDurationOptions()),
            const SizedBox(height: AppDimens.gapLarge),
            _buildSection('How Severe is The Problem?',
                _buildSeverityOptions()),
            const SizedBox(height: AppDimens.gapLarge),
            _buildSection('Are You Experiencing Any of These?',
                _buildExtraSymptoms()),
            const SizedBox(height: AppDimens.gapLarge),
            _buildSection('Do You Have Any Existing Health Conditions?',
                _buildConditions()),
            const SizedBox(height: AppDimens.gapLarge),
            _buildYesNoRow(
              '• Are You Currently Taking Any Medicine?',
              _takingMedicine,
              (v) => setState(() => _takingMedicine = v),
            ),
            const SizedBox(height: 8),
            _buildYesNoRow(
              '• Have you had the same problem recently?',
              _hadBefore,
              (v) => setState(() => _hadBefore = v),
            ),
            const SizedBox(height: AppDimens.gapLarge),
            // ── Assess button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isEvaluating
                    ? null
                    : () async {
                        setState(() => _isEvaluating = true);

                        // Map symptoms & severity to vitals estimation
                        final estimatedSysBp = _severityIndex == 2 ? 145 : (_severityIndex == 1 ? 128 : 115);
                        final estimatedDiaBp = _severityIndex == 2 ? 95 : (_severityIndex == 1 ? 84 : 76);
                        final estimatedTemp = _selectedSymptoms.contains('Fever')
                            ? (_severityIndex == 2 ? 39.2 : 38.1)
                            : 37.0;
                        final estimatedSpo2 = _extraSymptoms.contains('Difficulty Breathing') ? 92 : 98;

                        final mlRes = await MlTriageService.instance.evaluateTriage(
                          patientId: 'p-self',
                          age: 30,
                          systolicBp: estimatedSysBp,
                          diastolicBp: estimatedDiaBp,
                          pulseRate: _severityIndex == 2 ? 104 : 76,
                          temperature: estimatedTemp,
                          spo2: estimatedSpo2,
                          isPregnant: _conditions.contains('Maternal / Pregnant'),
                          symptoms: _selectedSymptoms,
                        );

                        if (mounted) {
                          setState(() {
                            _isEvaluating = false;
                            _mlTriageResult = mlRes;
                            _showResult = true;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isEvaluating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Run Digital ML Assessment',
                        style: AppTextStyles.buttonLabel),
              ),
            ),
            if (_showResult) ...[
              const SizedBox(height: AppDimens.gapLarge),
              _buildAssessmentResult(),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Greeting ─────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        '👋 Hello! Sudharani\nHow are You Feeling today??',
        style: AppTextStyles.body,
      ),
    );
  }

  // ── Symptom search ────────────────────────────────────────────
  Widget _buildSymptomSearch() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for Symptoms...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: const Icon(Icons.mic,
                size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ── Symptom chips ─────────────────────────────────────────────
  Widget _buildSymptomChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _symptomChips.map((s) {
        final selected = _selectedSymptoms.contains(s);
        return ChoiceChip(
          label: Text(s, style: AppTextStyles.caption),
          selected: selected,
          onSelected: (_) => setState(() {
            selected
                ? _selectedSymptoms.remove(s)
                : _selectedSymptoms.add(s);
          }),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(
              color: selected ? AppColors.primary : AppColors.cardBorder),
          labelStyle: TextStyle(
              color: selected ? AppColors.textOnPrimary : AppColors.textPrimary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusPill)),
        );
      }).toList(),
    );
  }

  // ── Reusable section wrapper ──────────────────────────────────
  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subheading),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ── Duration radio ────────────────────────────────────────────
  Widget _buildDurationOptions() {
    return Column(
      children: List.generate(_durations.length, (i) {
        return RadioListTile<int>(
          value: i,
          groupValue: _durationIndex,
          onChanged: (v) => setState(() => _durationIndex = v!),
          title: Text(_durations[i], style: AppTextStyles.body),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }),
    );
  }

  // ── Severity radio ────────────────────────────────────────────
  Widget _buildSeverityOptions() {
    return Column(
      children: List.generate(_severities.length, (i) {
        return RadioListTile<int>(
          value: i,
          groupValue: _severityIndex,
          onChanged: (v) => setState(() => _severityIndex = v!),
          title: Row(
            children: [
              Icon(Icons.circle, size: 10, color: _severityColors[i]),
              const SizedBox(width: 6),
              Text(_severities[i], style: AppTextStyles.body),
            ],
          ),
          activeColor: _severityColors[i],
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }),
    );
  }

  // ── Extra symptoms checkboxes ─────────────────────────────────
  Widget _buildExtraSymptoms() {
    return Column(
      children: _extraList.map((s) {
        final checked = _extraSymptoms.contains(s);
        return CheckboxListTile(
          value: checked,
          onChanged: (_) => setState(() {
            checked ? _extraSymptoms.remove(s) : _extraSymptoms.add(s);
          }),
          title: Text(s, style: AppTextStyles.body),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }

  // ── Existing conditions checkboxes ────────────────────────────
  Widget _buildConditions() {
    return Column(
      children: _conditionList.map((c) {
        final checked = _conditions.contains(c);
        return CheckboxListTile(
          value: checked,
          onChanged: (_) => setState(() {
            checked ? _conditions.remove(c) : _conditions.add(c);
          }),
          title: Text(c, style: AppTextStyles.body),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }

  // ── Yes / No row ──────────────────────────────────────────────
  Widget _buildYesNoRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(height: 4),
        Row(
          children: [
            _YesNoBox(label: 'Yes', selected: value,
                onTap: () => onChanged(true)),
            const SizedBox(width: 12),
            _YesNoBox(label: 'No', selected: !value,
                onTap: () => onChanged(false)),
          ],
        ),
      ],
    );
  }

  // ── Assessment result card ────────────────────────────────────
  Widget _buildAssessmentResult() {
    final mlRisk = _mlTriageResult?['riskLevel'] ??
        (_severityIndex == 0 ? 'LOW' : _severityIndex == 1 ? 'MEDIUM' : 'HIGH');
    final confidence = ((_mlTriageResult?['confidence'] as num?)?.toDouble() ?? 0.92) * 100;
    final recommendation = _mlTriageResult?['recommendation'] ??
        'Please follow the recommended clinical steps below.';
    final isOffline = _mlTriageResult?['isOfflineFallback'] ?? true;

    final Color priorityColor = mlRisk == 'EMERGENCY' || mlRisk == 'HIGH'
        ? AppColors.statusRed
        : mlRisk == 'MEDIUM'
            ? AppColors.statusAmber
            : AppColors.statusGreen;

    final priorityEmoji = mlRisk == 'EMERGENCY'
        ? '🚨'
        : mlRisk == 'HIGH'
            ? '🔴'
            : mlRisk == 'MEDIUM'
                ? '🟡'
                : '🟢';

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: priorityColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🤖 AI Clinical Assessment',
                  style: AppTextStyles.subheading),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOffline
                      ? AppColors.statusAmber.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOffline ? '⚡ On-Device Engine' : '☁️ Cloud ML Model',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOffline ? AppColors.statusAmber : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('$priorityEmoji $mlRisk RISK',
                  style: AppTextStyles.heading
                      .copyWith(color: priorityColor, fontSize: 18)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(0)}% Confidence',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded,
                    color: AppColors.primary, size: 24),
                tooltip: 'Listen in Local Language (Audio Readout)',
                onPressed: () {
                  TtsHelper.speakDialog(
                    context: context,
                    title: 'Digital Triage Audio Assessment',
                    messageEn:
                        'Your assessment indicates $mlRisk risk. $recommendation',
                    messageTe:
                        'మీ ఆరోగ్య అంచనా: $mlRisk రిస్క్ గా గుర్తించబడింది. $recommendation',
                    messageHi:
                        'आपके स्वास्थ्य का मूल्यांकन $mlRisk जोखिम के रूप में किया गया है। $recommendation',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recommendation,
            style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textPrimary),
          ),
          const Divider(height: 16),
          Text('Recommended Next Step:',
              style: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildResultAction(
            '🩺 Consult Doctor',
            '📞 Call',
            AppColors.statusGreen,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeleconsultScreen()),
            ),
          ),
          const SizedBox(height: 6),
          _buildResultAction(
            '📅 Book Appointment',
            '📅 Book',
            AppColors.primary,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentScreen()),
            ),
          ),
          const SizedBox(height: 6),
          _buildResultAction(
            '🗺️ Find Near by PHC',
            '👁️ View',
            AppColors.statusBlue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NearbyFacilitiesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultAction(
      String label, String btnText, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
              child: Text(btnText,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textOnPrimary)),
            ),
          ],
        ),
      ),
    );
  }

}

class _YesNoBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _YesNoBox(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color:
                selected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
