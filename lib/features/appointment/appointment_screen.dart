import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/data/repositories/patient_repository.dart';

class AppointmentScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const AppointmentScreen({super.key, this.patientId, this.patientName});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  // ── State ─────────────────────────────────────────────────────
  String _selectedFacilityType = 'PHC'; // PHC | District Hospital | CHC
  String _selectedFacilityName = 'Primary Health Center (PHC) - Rampur';
  String _selectedSpecialist = 'General Physician';
  String _selectedDoctor = 'Dr. Priya Sharma (MBBS)';
  int _selectedDay = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _selectedHour = 10;
  int _selectedMinute = 0;
  bool _isAM = true;
  double _consultationFee = 0.0;

  List<Patient> _patients = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  bool _isLoadingPatients = true;
  bool _isBooking = false;

  static const _facilityTypes = ['PHC', 'District Hospital', 'CHC'];
  static const _facilityColors = [
    AppColors.chipPHC,
    AppColors.chipHospital,
    AppColors.chipCHC,
  ];

  static const Map<String, List<String>> _specialistsAndDoctors = {
    'General Physician': [
      'Dr. Priya Sharma (MBBS)',
      'Dr. Rajesh Kumar (MD)',
    ],
    'Gynecologist': [
      'Dr. Sunita Verma (MS, OBGYN)',
      'Dr. Meenakshi Rao (DGO)',
    ],
    'Cardiologist': [
      'Dr. Vikram Malhotra (DM, Cardio)',
    ],
    'Pediatrician': [
      'Dr. Anita Joshi (DCH, MD)',
    ],
    'Orthopedic': [
      'Dr. Suresh Hegde (MS, Ortho)',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _selectedPatientName = widget.patientName;
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final patients = await PatientRepository.instance.getAll();
    if (mounted) {
      setState(() {
        _patients = patients;
        _isLoadingPatients = false;
        if (_selectedPatientId == null && patients.isNotEmpty) {
          _selectedPatientId = patients.first.id;
          _selectedPatientName = patients.first.name;
        } else if (_selectedPatientId != null && _selectedPatientName == null) {
          final found = patients.where((p) => p.id == _selectedPatientId);
          if (found.isNotEmpty) {
            _selectedPatientName = found.first.name;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.paddingPage),
                child: Column(
                  children: [
                    _buildPatientSelector(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildChooseHealthCare(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildChooseSpecialist(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildDateTimeSection(),
                    const SizedBox(height: AppDimens.gapLarge),
                    _buildFeeAndBook(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingPage, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
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
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for Doctors, Hospitals....',
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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person,
                color: AppColors.textOnPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Patient selector ──────────────────────────────────────────
  Widget _buildPatientSelector() {
    return _SectionCard(
      title: 'Patient Details',
      child: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.statusAmber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No patients registered yet. General Booking will be used.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                )
              : DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  decoration: InputDecoration(
                    labelText: 'Select Patient',
                    labelStyle: AppTextStyles.caption,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusSmall),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _patients.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} (${p.id})',
                          style: AppTextStyles.body),
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
    );
  }

  // ── Choose Health Care ────────────────────────────────────────
  Widget _buildChooseHealthCare() {
    return _SectionCard(
      title: 'Choose Health Care',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_facilityTypes.length, (i) {
              final selected = _selectedFacilityType == _facilityTypes[i];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFacilityType = _facilityTypes[i];
                    if (_selectedFacilityType == 'PHC') {
                      _selectedFacilityName = 'PHC Rampur';
                      _consultationFee = 0.0;
                    } else if (_selectedFacilityType == 'District Hospital') {
                      _selectedFacilityName = 'District Hospital Belagavi';
                      _consultationFee = 250.0;
                    } else {
                      _selectedFacilityName = 'CHC Gokak';
                      _consultationFee = 100.0;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? _facilityColors[i]
                        : _facilityColors[i].withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusPill),
                    border: Border.all(color: _facilityColors[i]),
                  ),
                  child: Text(
                    _facilityTypes[i],
                    style: AppTextStyles.caption.copyWith(
                      color: selected
                          ? AppColors.textOnPrimary
                          : _facilityColors[i],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_selectedFacilityName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Choose Specialist ─────────────────────────────────────────
  Widget _buildChooseSpecialist() {
    final specialists = _specialistsAndDoctors.keys.toList();

    return _SectionCard(
      title: 'Choose Specialist',
      child: Column(
        children: specialists.map((s) {
          final selected = _selectedSpecialist == s;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSpecialist = s;
                  final docs = _specialistsAndDoctors[s] ?? [];
                  if (docs.isNotEmpty) {
                    _selectedDoctor = docs.first;
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s, style: AppTextStyles.body),
                      if (selected)
                        Text(_selectedDoctor,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primary)),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.statusGreen
                          : AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusPill),
                      border: Border.all(
                          color: selected
                              ? AppColors.statusGreen
                              : AppColors.cardBorder),
                    ),
                    child: Align(
                      alignment: selected
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.textOnPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Date & Time ───────────────────────────────────────────────
  Widget _buildDateTimeSection() {
    return _SectionCard(
      title: 'Select Date & Time',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Row(
            children: [
              _DropdownBox(
                label: 'Day',
                value: _selectedDay,
                items: List.generate(31, (i) => i + 1),
                onChanged: (v) => setState(() => _selectedDay = v),
              ),
              const SizedBox(width: 6),
              _DropdownBox(
                label: 'Month',
                value: _selectedMonth,
                items: List.generate(12, (i) => i + 1),
                onChanged: (v) => setState(() => _selectedMonth = v),
              ),
              const SizedBox(width: 6),
              _DropdownBox(
                label: 'Year',
                value: _selectedYear,
                items: [2026, 2027],
                onChanged: (v) => setState(() => _selectedYear = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Time row
          Row(
            children: [
              _DropdownBox(
                label: 'Hour',
                value: _selectedHour,
                items: List.generate(12, (i) => i + 1),
                onChanged: (v) => setState(() => _selectedHour = v),
              ),
              const SizedBox(width: 6),
              _DropdownBox(
                label: 'Min',
                value: _selectedMinute,
                items: [0, 15, 30, 45],
                onChanged: (v) => setState(() => _selectedMinute = v),
              ),
              const SizedBox(width: 6),
              _DropdownBox(
                label: 'AM/PM',
                value: _isAM ? 1 : 2,
                items: [1, 2],
                displayMap: const {1: 'AM', 2: 'PM'},
                onChanged: (v) => setState(() => _isAM = v == 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fee & Book button ─────────────────────────────────────────
  Widget _buildFeeAndBook() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Consultation Fee: ', style: AppTextStyles.subheading),
              Text(
                _consultationFee == 0.0 ? 'FREE (Govt)' : '₹${_consultationFee.toInt()}',
                style: AppTextStyles.heading.copyWith(
                  color: _consultationFee == 0.0
                      ? AppColors.statusGreen
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _bookAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusBlue,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusPill)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isBooking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.textOnPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Book Appointment',
                      style: AppTextStyles.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bookAppointment() async {
    final patientId = _selectedPatientId ?? 'GEN-PATIENT-1';

    // Construct scheduled DateTime
    int hour = _selectedHour;
    if (!_isAM && hour < 12) hour += 12;
    if (_isAM && hour == 12) hour = 0;

    DateTime scheduledAt;
    try {
      scheduledAt = DateTime(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
        hour,
        _selectedMinute,
      );
    } catch (_) {
      scheduledAt = DateTime.now().add(const Duration(days: 1));
    }

    setState(() => _isBooking = true);

    try {
      final appt = await PatientRepository.instance.bookAppointment(
        patientId: patientId,
        doctorName: _selectedDoctor,
        facility: _selectedFacilityName,
        facilityType: _selectedFacilityType,
        specialty: _selectedSpecialist,
        scheduledAt: scheduledAt,
        fee: _consultationFee,
      );

      if (!mounted) return;
      setState(() => _isBooking = false);

      _showConfirmationDialog(appt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book appointment: $e'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  void _showConfirmationDialog(Appointment appt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusGreen, size: 28),
            const SizedBox(width: 8),
            const Text('Appointment Booked', style: AppTextStyles.heading),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Token / ID: ${appt.id}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Patient: ${_selectedPatientName ?? appt.patientId}', style: AppTextStyles.body),
            Text('Doctor: ${appt.doctorName}', style: AppTextStyles.body),
            Text('Facility: ${appt.facility}', style: AppTextStyles.body),
            Text('Specialty: ${appt.specialty}', style: AppTextStyles.body),
            Text(
              'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(appt.scheduledAt)}',
              style: AppTextStyles.body.copyWith(color: AppColors.statusBlue),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Saved offline to SQLite database. Will sync automatically when network is available.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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

// ── Reusable section card ─────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
}

// ── Compact dropdown box ──────────────────────────────────────
class _DropdownBox extends StatelessWidget {
  final String label;
  final int value;
  final List<int> items;
  final Map<int, String>? displayMap;
  final ValueChanged<int> onChanged;

  const _DropdownBox({
    required this.label,
    required this.value,
    required this.items,
    this.displayMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          underline: const SizedBox(),
          isExpanded: true,
          hint: Text(label, style: AppTextStyles.caption),
          items: items.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text(
                displayMap != null ? displayMap![v]! : v.toString(),
                style: AppTextStyles.body,
              ),
            );
          }).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}
