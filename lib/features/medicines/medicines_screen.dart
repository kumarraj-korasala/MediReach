import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String _searchQuery = '';
  String _filter = 'All'; // All | Available | PHC Dispensary | Jan Aushadhi

  static const _essentialMedicines = [
    _MedicineStock(
      name: 'Paracetamol 500 mg',
      category: 'Analgesic / Antipyretic',
      stockStatus: 'In Stock (450 units)',
      statusColor: AppColors.statusGreen,
      dispensary: 'Primary Health Center (PHC) - Rampur',
      distance: '2.4 km away',
      price: 'Free (Govt Supply)',
      phone: '+918332210101',
      dosageNote: '1 tablet after food, twice a day for fever/pain',
    ),
    _MedicineStock(
      name: 'Iron & Folic Acid (IFA) Tablets',
      category: 'Maternal Nutrition (ANC)',
      stockStatus: 'In Stock (600 units)',
      statusColor: AppColors.statusGreen,
      dispensary: 'Sub-Center Karoshi / ASHA Kit',
      distance: '0.8 km away',
      price: 'Free (Govt Supply)',
      phone: '+918332210102',
      dosageNote: '1 tablet daily after food for pregnant & lactating mothers',
    ),
    _MedicineStock(
      name: 'Metformin 500 mg',
      category: 'Anti-Diabetic',
      stockStatus: 'In Stock (180 units)',
      statusColor: AppColors.statusGreen,
      dispensary: 'PM Jan Aushadhi Kendra - Gokak',
      distance: '8.5 km away',
      price: '₹12 (Jan Aushadhi)',
      phone: '+918332220202',
      dosageNote: '1 tablet with morning meal',
    ),
    _MedicineStock(
      name: 'Telmisartan 40 mg',
      category: 'Anti-Hypertensive',
      stockStatus: 'In Stock (120 units)',
      statusColor: AppColors.statusGreen,
      dispensary: 'Community Health Center (CHC) - Gokak',
      distance: '8.5 km away',
      price: 'Free (Govt Supply)',
      phone: '+918332220203',
      dosageNote: '1 tablet morning daily for blood pressure control',
    ),
    _MedicineStock(
      name: 'Amoxicillin 500 mg Capsules',
      category: 'Antibiotic',
      stockStatus: 'Limited Stock (25 units)',
      statusColor: AppColors.statusAmber,
      dispensary: 'ASA Sub-District Hospital - Hukkeri',
      distance: '14.2 km away',
      price: 'Free (Govt Supply)',
      phone: '+918332230303',
      dosageNote: 'As prescribed by Medical Officer',
    ),
    _MedicineStock(
      name: 'Oral Rehydration Salts (ORS) Sachets',
      category: 'Child Health / Hydration',
      stockStatus: 'In Stock (800 units)',
      statusColor: AppColors.statusGreen,
      dispensary: 'Primary Health Center (PHC) - Rampur',
      distance: '2.4 km away',
      price: 'Free (Govt Supply)',
      phone: '+918332210101',
      dosageNote: 'Mix 1 packet in 1 liter clean water',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _essentialMedicines.where((m) {
      final matchSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchFilter = _filter == 'All' ||
          (_filter == 'Available' && m.statusColor == AppColors.statusGreen) ||
          (_filter == 'PHC' && m.dispensary.contains('PHC')) ||
          (_filter == 'Jan Aushadhi' && m.dispensary.contains('Jan Aushadhi'));
      return matchSearch && matchFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text(
          '💊 Pharmacy & Medicines',
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
          _buildSearchAndFilters(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.paddingPage),
              children: [
                _buildActivePrescriptionCard(),
                const SizedBox(height: AppDimens.gapLarge),
                _buildStockHeader(filtered.length),
                const SizedBox(height: AppDimens.gapSmall),
                ...filtered.map((m) => _buildMedicineCard(m)),
                const SizedBox(height: 30),
              ],
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
          horizontal: AppDimens.paddingPage, vertical: 12),
      child: Column(
        children: [
          Container(
            height: 40,
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
                      hintText: 'Search medicine, generic salt or category...',
                      hintStyle: AppTextStyles.caption,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['All', 'Available', 'PHC', 'Jan Aushadhi'].map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f, style: AppTextStyles.caption),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePrescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Active Prescription for Patient',
                  style: AppTextStyles.subheading),
            ],
          ),
          const Divider(height: 16),
          Text('💊 Iron & Folic Acid 100mg + Calcium 500mg',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Prescribed By: Dr. Sunita Verma (OBGYN) — ANC Protocol',
              style: AppTextStyles.caption),
          Text('Course: 90 Days | Started: 12 Sep 2026',
              style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            ),
            child: Text(
              '🕒 1 Tablet Daily After Morning Food',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Essential Drug Inventory ($count)',
            style: AppTextStyles.subheading),
        Text('Govt Free Drug Scheme',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.statusGreen, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMedicineCard(_MedicineStock m) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapMedium),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(m.name,
                    style: AppTextStyles.subheading.copyWith(fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: m.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  border: Border.all(color: m.statusColor),
                ),
                child: Text(
                  m.stockStatus,
                  style: AppTextStyles.caption.copyWith(
                    color: m.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(m.category,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text('${m.dispensary} (${m.distance})',
                    style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.currency_rupee,
                  size: 14, color: AppColors.statusGreen),
              const SizedBox(width: 4),
              Text(m.price,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.statusGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('ℹ️ ${m.dosageNote}', style: AppTextStyles.caption),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Call Dispensary'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                ),
                onPressed: () => _call(m.phone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _MedicineStock {
  final String name;
  final String category;
  final String stockStatus;
  final Color statusColor;
  final String dispensary;
  final String distance;
  final String price;
  final String phone;
  final String dosageNote;

  const _MedicineStock({
    required this.name,
    required this.category,
    required this.stockStatus,
    required this.statusColor,
    required this.dispensary,
    required this.distance,
    required this.price,
    required this.phone,
    required this.dosageNote,
  });
}
