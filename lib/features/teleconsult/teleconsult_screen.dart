import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/views/pages/videocall_page.dart';
import 'package:url_launcher/url_launcher.dart';

class TeleconsultScreen extends StatefulWidget {
  const TeleconsultScreen({super.key});

  @override
  State<TeleconsultScreen> createState() => _TeleconsultScreenState();
}

class _TeleconsultScreenState extends State<TeleconsultScreen> {
  final _searchController = TextEditingController();

  static const _doctors = [
    _Doctor(
      'Dr. Kumar (MBBS, MS)',
      'General Surgeon',
      'Amalapuram PHC',
      '+917013061877',
      'doctor_kumar',
    ),
    _Doctor(
      'Dr. Sunita Verma (MS, OBGYN)',
      'Gynecologist & Obstetrician',
      'Belagavi District Hospital',
      '+919876500002',
      'doctor_sunita',
    ),
    _Doctor(
      'Dr. Teja (MBBS, FRCS)',
      'ENT Specialist',
      'Challapalli CHC',
      '+919876500003',
      'doctor_teja',
    ),
    _Doctor(
      'Dr. Harshini (BPT, MPT)',
      'Physiotherapy Specialist',
      'Vaddigudem PHC',
      '+919876500004',
      'doctor_harshini',
    ),
    _Doctor(
      'Dr. Shankar (MD, DM)',
      'Cardiology Specialist',
      'KIMS Hospital',
      '+919876500005',
      'doctor_shankar',
    ),
    _Doctor(
      'Dr. Pavan (MBBS)',
      'Emergency Medical Officer',
      'Rampur Sub-Center',
      '+919876500006',
      'doctor_pavan',
    ),
  ];

  List<_Doctor> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _doctors;
    return _doctors
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q) ||
              d.location.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildWebRtcHubBanner(context),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, _, child) {
                  final list = _filtered;
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppDimens.paddingPage),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _DoctorCard(doctor: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingPage,
        vertical: 10,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
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
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for Doctors, Specialists...',
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
            child: const Icon(
              Icons.person,
              color: AppColors.textOnPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebRtcHubBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingPage,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.videocam_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEDI Connect (WebRTC)',
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const Text(
                  'Live encrypted video call & file exchange',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VideoCallPage()),
              );
            },
            child: const Text(
              'Open Hub',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final _Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapMedium),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name, style: AppTextStyles.subheading),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('📍 ${doctor.location}', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Voice Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    ),
                  ),
                  onPressed: () => _call(doctor.phone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam, size: 16),
                  label: const Text('Video Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusGreen,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoCallPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _Doctor {
  final String name, specialty, location, phone, contactId;
  const _Doctor(
    this.name,
    this.specialty,
    this.location,
    this.phone,
    this.contactId,
  );
}
