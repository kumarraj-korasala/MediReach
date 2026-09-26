import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/data/repositories/patient_repository.dart';
import 'package:miracle/features/referral/referral_screen.dart';

class ReferralStatusScreen extends StatefulWidget {
  final String? patientId;

  const ReferralStatusScreen({super.key, this.patientId});

  @override
  State<ReferralStatusScreen> createState() => _ReferralStatusScreenState();
}

class _ReferralStatusScreenState extends State<ReferralStatusScreen> {
  List<Referral> _referrals = [];
  Map<String, Patient> _patientMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = PatientRepository.instance;
    final allPatients = await repo.getAll();
    final patientMap = {for (var p in allPatients) p.id: p};

    List<Referral> refs;
    if (widget.patientId != null) {
      refs = await repo.getReferrals(widget.patientId!);
    } else {
      // Gather referrals across all patients
      List<Referral> combined = [];
      for (final p in allPatients) {
        final rList = await repo.getReferrals(p.id);
        combined.addAll(rList);
      }
      refs = combined;
    }

    refs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _referrals = refs;
        _patientMap = patientMap;
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
          'Referral Tracking',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReferralScreen(patientId: widget.patientId),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('New Referral',
            style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _referrals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimens.paddingPage),
                      itemCount: _referrals.length,
                      itemBuilder: (context, index) {
                        return _buildReferralCard(_referrals[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swap_calls_rounded,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No Referrals Found',
                style: AppTextStyles.heading.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new patient referral to track transfers between PHCs, CHCs, and District Hospitals.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusPill)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReferralScreen(patientId: widget.patientId),
                    ),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
                label: const Text('Create Referral',
                    style: AppTextStyles.buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCard(Referral ref) {
    final patient = _patientMap[ref.patientId];
    final patientName = patient?.name ?? ref.patientId;

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
              Text(
                ref.id,
                style: AppTextStyles.subheading.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusBadge(ref.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(ref.createdAt),
            style: AppTextStyles.caption,
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Patient: $patientName',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'From: ${ref.fromFacility}\nTo: ${ref.toFacility}',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Reason: ${ref.reason}',
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code, size: 16),
                label: const Text('View QR Pass'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                ),
                onPressed: () => _showQrModal(ref, patientName),
              ),
              PopupMenuButton<ReferralStatus>(
                tooltip: 'Update Status',
                onSelected: (status) => _updateStatus(ref.id, status),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusPill),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Text('Update ', style: AppTextStyles.caption),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ReferralStatus.created,
                    child: Text('Created'),
                  ),
                  const PopupMenuItem(
                    value: ReferralStatus.dispatched,
                    child: Text('Dispatched'),
                  ),
                  const PopupMenuItem(
                    value: ReferralStatus.arrived,
                    child: Text('Arrived'),
                  ),
                  const PopupMenuItem(
                    value: ReferralStatus.completed,
                    child: Text('Completed'),
                  ),
                  const PopupMenuItem(
                    value: ReferralStatus.cancelled,
                    child: Text('Cancelled'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReferralStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ReferralStatus.created:
        bg = const Color(0xFFE3F2FD);
        fg = AppColors.statusBlue;
        label = 'Created';
        break;
      case ReferralStatus.dispatched:
        bg = const Color(0xFFFFF8E1);
        fg = AppColors.statusAmber;
        label = 'Dispatched';
        break;
      case ReferralStatus.arrived:
        bg = const Color(0xFFEDE7F6);
        fg = Colors.deepPurple;
        label = 'Arrived';
        break;
      case ReferralStatus.completed:
        bg = const Color(0xFFE8F5E9);
        fg = AppColors.statusGreen;
        label = 'Completed';
        break;
      case ReferralStatus.cancelled:
        bg = const Color(0xFFFFEBEE);
        fg = AppColors.statusRed;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, ReferralStatus status) async {
    await PatientRepository.instance.updateReferralStatus(id, status);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral status updated to ${status.name.toUpperCase()}'),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showQrModal(Referral ref, String patientName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
        title: const Text('Digital Referral Pass', style: AppTextStyles.heading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.qr_code_2_rounded,
                  size: 140, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(ref.id,
                style: AppTextStyles.subheading
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            Text('Patient: $patientName', style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text('To: ${ref.toFacility}',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildStatusBadge(ref.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
