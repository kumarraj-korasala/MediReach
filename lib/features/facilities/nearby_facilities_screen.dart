import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:miracle/core/remote/api_client.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/features/appointment/appointment_screen.dart';

class NearbyFacilitiesScreen extends StatefulWidget {
  final String? patientId;

  const NearbyFacilitiesScreen({super.key, this.patientId});

  @override
  State<NearbyFacilitiesScreen> createState() => _NearbyFacilitiesScreenState();
}

class _NearbyFacilitiesScreenState extends State<NearbyFacilitiesScreen> {
  String _selectedFilter = 'All'; // All | PHC | CHC | Hospital
  String _searchQuery = '';
  bool _isLoading = true;

  // Selected Reference GPS Coordinates (Default: Rampur Village)
  String _currentLocationName = 'Rampur Village Catchment';
  double _userLat = 16.2415;
  double _userLng = 74.7812;

  List<HealthcareFacility> _facilities = [];

  // Default Fallback Facilities with Complete Doctor Rosters
  static final _defaultFacilities = [
    HealthcareFacility(
      id: 'FAC-001',
      name: 'Primary Health Centre (PHC) - Rampur',
      type: 'PHC',
      distanceKm: 2.4,
      lat: 16.2415,
      lng: 74.7812,
      phone: '+91 83322 10101',
      address: 'Main Road, Rampur Village, Belagavi',
      hasObstetrician: false,
      hasEmergency24x7: false,
      hasPharmacy: true,
      availableSpecialists: ['General Physician', 'AYUSH Doctor', 'ANM/Staff Nurse'],
      doctors: const [
        DutyDoctor(
          id: 'doc-101',
          name: 'Dr. Anand Deshmukh',
          degree: 'MBBS (General Medicine)',
          specialty: 'General Physician',
          experience: '8 yrs exp',
          opdTiming: '9:00 AM - 1:00 PM',
          status: 'Available Today',
          languages: 'Kannada, Marathi, Hindi',
          phone: '+91 94401 11201',
        ),
        DutyDoctor(
          id: 'doc-102',
          name: 'Dr. Sneha Patil',
          degree: 'BAMS (Ayurveda & Primary Care)',
          specialty: 'AYUSH Medical Officer',
          experience: '5 yrs exp',
          opdTiming: '1:00 PM - 5:00 PM',
          status: 'Available Today',
          languages: 'Kannada, Hindi',
          phone: '+91 94401 11202',
        ),
      ],
    ),
    HealthcareFacility(
      id: 'FAC-002',
      name: 'Community Health Centre (CHC) - Gokak',
      type: 'CHC',
      distanceKm: 8.5,
      lat: 16.1667,
      lng: 74.8333,
      phone: '+91 83322 20202',
      address: 'Hospital Circle, Gokak Town',
      hasObstetrician: true,
      hasEmergency24x7: true,
      hasPharmacy: true,
      availableSpecialists: ['Obstetrician & Gynaecologist', 'Pediatrician', 'General Surgeon'],
      doctors: const [
        DutyDoctor(
          id: 'doc-201',
          name: 'Dr. Radhika Sharma',
          degree: 'MD, DGO (Obstetrics & Gynecology)',
          specialty: 'Obstetrician & Gynaecologist',
          experience: '12 yrs exp',
          opdTiming: '9:00 AM - 2:00 PM (Emergency 24x7)',
          status: 'On Duty / Available',
          languages: 'Telugu, Hindi, English',
          phone: '+91 94401 88888',
        ),
        DutyDoctor(
          id: 'doc-202',
          name: 'Dr. Ramesh Kulkarni',
          degree: 'MD (Pediatrics)',
          specialty: 'Pediatrician',
          experience: '10 yrs exp',
          opdTiming: '10:00 AM - 4:00 PM',
          status: 'Available Today',
          languages: 'Kannada, English',
          phone: '+91 94401 22302',
        ),
        DutyDoctor(
          id: 'doc-203',
          name: 'Dr. Vikram Naik',
          degree: 'MS (General Surgery)',
          specialty: 'General Surgeon',
          experience: '15 yrs exp',
          opdTiming: '11:00 AM - 3:00 PM',
          status: 'In OT / Available 2 PM',
          languages: 'Kannada, Hindi, English',
          phone: '+91 94401 22303',
        ),
      ],
    ),
    HealthcareFacility(
      id: 'FAC-003',
      name: 'ASA Sub-District Hospital - Hukkeri',
      type: 'Hospital',
      distanceKm: 14.2,
      lat: 16.2234,
      lng: 74.6012,
      phone: '+91 83322 30303',
      address: 'National Highway Link, Hukkeri',
      hasObstetrician: true,
      hasEmergency24x7: true,
      hasPharmacy: true,
      availableSpecialists: ['Obstetrician', 'Orthopedic Surgeon', 'Cardiologist (Visiting)', 'Pediatrician'],
      doctors: const [
        DutyDoctor(
          id: 'doc-301',
          name: 'Dr. Suresh Varma',
          degree: 'MS, M.Ch (Superintendent)',
          specialty: 'Hospital Superintendent & General Surgery',
          experience: '22 yrs exp',
          opdTiming: '9:00 AM - 1:00 PM',
          status: 'Available Today',
          languages: 'Telugu, Hindi, English',
          phone: '+91 94401 99999',
        ),
        DutyDoctor(
          id: 'doc-302',
          name: 'Dr. Meenakshi Sundaram',
          degree: 'DNB (Orthopedics)',
          specialty: 'Orthopedic Surgeon',
          experience: '9 yrs exp',
          opdTiming: '10:00 AM - 3:00 PM',
          status: 'Available Today',
          languages: 'Tamil, Telugu, English',
          phone: '+91 94401 33402',
        ),
      ],
    ),
    HealthcareFacility(
      id: 'FAC-004',
      name: 'District Civil Hospital - Belagavi',
      type: 'Hospital',
      distanceKm: 28.0,
      lat: 15.8497,
      lng: 74.4977,
      phone: '+91 83124 04040',
      address: 'Civil Hospital Road, Belagavi City',
      hasObstetrician: true,
      hasEmergency24x7: true,
      hasPharmacy: true,
      availableSpecialists: ['High-Risk OBGYN', 'Cardiologist', 'Neurologist', 'Pediatric ICU', 'Trauma Surgeon'],
      doctors: const [
        DutyDoctor(
          id: 'doc-401',
          name: 'Dr. Hariprasad Rao',
          degree: 'DM (Cardiology), MD',
          specialty: 'Consultant Cardiologist',
          experience: '18 yrs exp',
          opdTiming: '9:00 AM - 1:00 PM',
          status: 'Available Today',
          languages: 'Kannada, Hindi, English',
          phone: '+91 83124 04041',
        ),
        DutyDoctor(
          id: 'doc-402',
          name: 'Dr. Kavitha Menon',
          degree: 'MD, High-Risk Obstetrics Fellowship',
          specialty: 'High-Risk OBGYN Specialist',
          experience: '14 yrs exp',
          opdTiming: '24x7 Emergency Delivery Room',
          status: 'Duty Doctor Active',
          languages: 'Malayalam, English, Hindi',
          phone: '+91 83124 04042',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((R * c).toStringAsFixed(1));
  }

  Future<void> _fetchFacilities() async {
    setState(() => _isLoading = true);

    try {
      final res = await ApiClient.instance.get('/facilities/nearby?lat=$_userLat&lng=$_userLng');
      if (res['success'] == true && res['data'] != null) {
        final list = (res['data'] as List)
            .map((item) => HealthcareFacility.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        if (mounted) {
          setState(() {
            _facilities = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Local fallback calculation with Haversine
    }

    // Recompute distances on local data based on active coordinates
    final computed = _defaultFacilities.map((f) {
      final dist = _haversineKm(_userLat, _userLng, f.lat, f.lng);
      return HealthcareFacility(
        id: f.id,
        name: f.name,
        type: f.type,
        distanceKm: dist,
        lat: f.lat,
        lng: f.lng,
        phone: f.phone,
        address: f.address,
        hasObstetrician: f.hasObstetrician,
        hasEmergency24x7: f.hasEmergency24x7,
        hasPharmacy: f.hasPharmacy,
        availableSpecialists: f.availableSpecialists,
        doctors: f.doctors,
      );
    }).toList();

    computed.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (mounted) {
      setState(() {
        _facilities = computed;
        _isLoading = false;
      });
    }
  }

  void _changeLocation(String name, double lat, double lng) {
    setState(() {
      _currentLocationName = name;
      _userLat = lat;
      _userLng = lng;
    });
    _fetchFacilities();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _facilities.where((f) {
      final matchesFilter = _selectedFilter == 'All' || f.type.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.availableSpecialists.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          f.doctors.any((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()) || d.specialty.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text(
          '📍 Nearby Centers & Doctors',
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
      body: Column(
        children: [
          _buildLocationBanner(),
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching facilities or doctors found',
                          style: AppTextStyles.caption,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchFacilities,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimens.paddingPage),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildFacilityCard(filtered[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Location Selector Banner ────────────────────────────────
  Widget _buildLocationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFE0F2F1),
      child: Row(
        children: [
          const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF00695C)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR DETECTED LOCATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00695C), letterSpacing: 0.8)),
                Text(
                  '$_currentLocationName (${_userLat.toStringAsFixed(3)}, ${_userLng.toStringAsFixed(3)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
          PopupMenuButton<Map<String, dynamic>>(
            tooltip: 'Change Location',
            onSelected: (loc) => _changeLocation(loc['name'], loc['lat'], loc['lng']),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: {'name': 'Rampur Village Catchment', 'lat': 16.2415, 'lng': 74.7812},
                child: Text('📍 Rampur Village (Rural Sub-Center)'),
              ),
              const PopupMenuItem(
                value: {'name': 'Gokak Town CHC Hub', 'lat': 16.1667, 'lng': 74.8333},
                child: Text('📍 Gokak Town (CHC Hub)'),
              ),
              const PopupMenuItem(
                value: {'name': 'Belagavi District City', 'lat': 15.8497, 'lng': 74.4977},
                child: Text('📍 Belagavi City (District Hospital)'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00695C).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                  Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF00695C)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingPage, vertical: 10),
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search hospital, doctor, or specialty...',
                      hintStyle: AppTextStyles.caption,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['All', 'PHC', 'CHC', 'Hospital'].map((type) {
              final isSelected = _selectedFilter == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type, style: AppTextStyles.caption),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = type),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(HealthcareFacility f) {
    Color typeColor;
    if (f.type == 'PHC') {
      typeColor = AppColors.chipPHC;
    } else if (f.type == 'CHC') {
      typeColor = AppColors.chipCHC;
    } else {
      typeColor = AppColors.chipHospital;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapMedium),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_hospital_rounded,
                    color: typeColor, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: AppTextStyles.subheading),
                    if (f.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(f.address, style: AppTextStyles.caption),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusPill),
                          ),
                          child: Text(
                            f.type,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.near_me_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          '${f.distanceKm} km away',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (f.hasObstetrician)
                _buildTag('🤰 Obstetrician 24x7', AppColors.statusGreen),
              if (f.hasEmergency24x7)
                _buildTag('🚑 Emergency 24x7', AppColors.statusRed),
              if (f.hasPharmacy)
                _buildTag('💊 Pharmacy on-site', AppColors.statusBlue),
            ],
          ),
          const Divider(height: 20),

          // ── Duty Doctors List ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👨‍⚕️ Available Doctors (${f.doctors.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'OPD Timings',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...f.doctors.map((doc) => _buildDoctorRow(doc)),

          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call Facility'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusPill),
                    ),
                  ),
                  onPressed: () => _callFacility(f.phone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Maps (GPS)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusBlue,
                    side: const BorderSide(color: AppColors.statusBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusPill),
                    ),
                  ),
                  onPressed: () => _openMaps(f.lat, f.lng, f.name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorRow(DutyDoctor doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE0F2F1),
            child: const Icon(Icons.person, color: Color(0xFF00796B), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${doc.degree} • ${doc.experience}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text('🩺 ${doc.specialty}', style: const TextStyle(fontSize: 11, color: Color(0xFF00796B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('🕒 ${doc.opdTiming}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  doc.status,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.statusGreen),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentScreen(
                        patientId: widget.patientId,
                      ),
                    ),
                  );
                },
                child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _callFacility(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $phone...')),
        );
      }
    }
  }

  Future<void> _openMaps(double lat, double lng, String name) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening maps to $name...')),
        );
      }
    }
  }
}

