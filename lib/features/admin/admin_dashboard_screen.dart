// ============================================================
// MediReach — Admin & Medical Officer Management Portal
// Inbound Referral Desk, Pharmacy Inventory & OPD Controls
// ============================================================
import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/local/db_helper.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/features/referral/referral_status_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Inbound Referrals State ──────────────────────────────────
  List<Referral> _inboundReferrals = [];
  bool _isLoading = true;

  // ── Hospital Inventory State ─────────────────────────────────
  final List<Map<String, dynamic>> _hospitalInventory = [
    {
      'name': 'Iron & Folic Acid (IFA) Tablets',
      'category': 'Maternal Health',
      'stock': 450,
      'unit': 'Tablets',
      'status': 'IN_STOCK',
      'batch': 'IFA-2026-B8',
    },
    {
      'name': 'Paracetamol 500mg',
      'category': 'Analgesics',
      'stock': 1200,
      'unit': 'Tablets',
      'status': 'IN_STOCK',
      'batch': 'PCM-2026-A1',
    },
    {
      'name': 'Metformin 500mg',
      'category': 'Diabetes / NCD',
      'stock': 85,
      'unit': 'Tablets',
      'status': 'LOW_STOCK',
      'batch': 'MET-2026-C4',
    },
    {
      'name': 'Oral Rehydration Salts (ORS)',
      'category': 'Pediatrics',
      'stock': 600,
      'unit': 'Sachets',
      'status': 'IN_STOCK',
      'batch': 'ORS-2026-D2',
    },
    {
      'name': 'Amoxicillin 500mg',
      'category': 'Antibiotics',
      'stock': 0,
      'unit': 'Capsules',
      'status': 'OUT_OF_STOCK',
      'batch': 'AMX-2026-X9',
    },
  ];

  // ── OPD Doctor Roster ────────────────────────────────────────
  final List<Map<String, dynamic>> _doctorRoster = [
    {
      'name': 'Dr. Suresh Varma',
      'specialty': 'General Medicine & Superintendent',
      'active': true,
      'tokens_served': 18,
      'tokens_pending': 6,
    },
    {
      'name': 'Dr. Radhika Sharma',
      'specialty': 'Obstetrics & Gynecology (ANC)',
      'active': true,
      'tokens_served': 24,
      'tokens_pending': 4,
    },
    {
      'name': 'Dr. K. Venkatesh',
      'specialty': 'Pediatrics & Neonatal Care',
      'active': false,
      'tokens_served': 12,
      'tokens_pending': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReferrals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReferrals() async {
    final db = DbHelper.instance;
    final allPatients = await db.getAllPatients();
    final List<Referral> list = [];
    for (final p in allPatients) {
      final refs = await db.getReferralsForPatient(p.id);
      list.addAll(refs);
    }
    if (mounted) {
      setState(() {
        _inboundReferrals = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B), // Dark Slate Navy for Admin
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏛️ Hospital Admin Portal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('District Hospital Kakinada — Command Desk',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Desk',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadReferrals();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.transfer_within_a_station_rounded, size: 20), text: 'Referrals'),
            Tab(icon: Icon(Icons.medication_rounded, size: 20), text: 'Pharmacy'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'OPD Roster'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReferralTriageTab(),
                _buildPharmacyInventoryTab(),
                _buildOpdRosterTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Inbound Referral Desk ─────────────────────────────
  Widget _buildReferralTriageTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.paddingPage),
      children: [
        _buildStatsSummary(),
        const SizedBox(height: AppDimens.gapMedium),
        Text('Inbound Facility Referrals', style: AppTextStyles.heading),
        const SizedBox(height: 8),
        if (_inboundReferrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: appCardDecoration,
            child: const Center(
              child: Text('No pending inbound referrals at this time.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._inboundReferrals.map(_buildReferralAdminCard),
      ],
    );
  }

  Widget _buildStatsSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Emergency Beds',
            '12 / 16',
            Icons.bed_rounded,
            AppColors.statusGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Inbound Queue',
            '${_inboundReferrals.length}',
            Icons.notifications_active_rounded,
            AppColors.statusAmber,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.heading.copyWith(fontSize: 18, color: color)),
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralAdminCard(Referral ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('🚨 PRIORITY INBOUND',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusRed)),
              ),
              const Spacer(),
              Text(ref.id,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text('From: ${ref.fromFacility} ➔ ${ref.toFacility}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Reason: ${ref.reason}', style: AppTextStyles.body.copyWith(fontSize: 13)),
          const Divider(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Accept & Assign Bed', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Referral ${ref.id} accepted. Bed assigned in Ward 3.'),
                      backgroundColor: AppColors.statusGreen,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReferralStatusScreen(patientId: ref.patientId),
                    ),
                  );
                },
                child: const Text('View Pass', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Hospital Pharmacy Inventory ────────────────────────
  Widget _buildPharmacyInventoryTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.paddingPage),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Drug Stock Control', style: AppTextStyles.heading),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Live Gov Inventory',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusGreen)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._hospitalInventory.map((item) {
          final isLow = item['status'] == 'LOW_STOCK' || item['status'] == 'OUT_OF_STOCK';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: appCardDecoration,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: AppTextStyles.subheading.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${item['category']} • Batch: ${item['batch']}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item['stock']} ${item['unit']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLow ? AppColors.statusRed : AppColors.textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () {
                            setState(() {
                              if (item['stock'] > 0) item['stock'] -= 10;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                          onPressed: () {
                            setState(() {
                              item['stock'] += 50;
                              item['status'] = 'IN_STOCK';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Tab 3: OPD Doctor Roster & Queue Monitor ──────────────────
  Widget _buildOpdRosterTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.paddingPage),
      children: [
        Text('OPD Doctor Schedule & Queue', style: AppTextStyles.heading),
        const SizedBox(height: 12),
        ..._doctorRoster.map((doc) {
          final bool active = doc['active'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppDimens.paddingCard),
            decoration: appCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: active
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      child: Icon(Icons.medical_services_rounded,
                          color: active ? AppColors.primary : Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc['name'], style: AppTextStyles.subheading.copyWith(fontSize: 14)),
                          Text(doc['specialty'], style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Switch(
                      value: active,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => doc['active'] = val);
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Served: ${doc['tokens_served']} patients',
                        style: const TextStyle(fontSize: 12, color: AppColors.statusGreen)),
                    Text('In Queue: ${doc['tokens_pending']} patients',
                        style: const TextStyle(fontSize: 12, color: AppColors.statusAmber)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
