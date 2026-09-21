import 'package:flutter/material.dart';
import 'package:miracle/core/remote/abha_service.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/views/pages/welcome_page.dart';

import '../../data/notifiers.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUser? _user;
  bool _loading = true;
  bool _isSyncingAbha = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await SessionManager.instance.getSession();
    if (mounted) {
      setState(() {
        _user = u;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;
    final name = user?.name.isNotEmpty == true ? user!.name : 'MediReach User';
    final phone = user?.phone.isNotEmpty == true ? user!.phone : 'Not Provided';
    final role = user?.role ?? UserRole.patient;
    final abhaId = user?.abhaId?.isNotEmpty == true ? user!.abhaId! : 'Not Linked';

    String roleTitle = 'Citizen Patient';
    String roleEmoji = '👤';
    Color roleColor = AppColors.statusGreen;

    if (role == UserRole.admin) {
      roleTitle = 'Hospital Administrator';
      roleEmoji = '🏛️';
      roleColor = const Color(0xFF1E293B);
    } else if (role == UserRole.doctor) {
      roleTitle = 'Medical Officer (Doctor)';
      roleEmoji = '👨‍⚕️';
      roleColor = const Color(0xFF1565C0);
    } else if (role == UserRole.healthWorker) {
      roleTitle = 'ASHA / ANM Field Worker';
      roleEmoji = '🩺';
      roleColor = AppColors.primaryDark;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Avatar with role badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      roleEmoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: roleColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.verified, color: Colors.white, size: 18),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                name,
                style: AppTextStyles.heading.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              // Role Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$roleEmoji $roleTitle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ABHA Health Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004D40).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Ayushman Bharat Digital Mission',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('ABHA NUMBER / ID', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      abhaId,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CARD HOLDER', style: TextStyle(color: Colors.white60, fontSize: 9)),
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('PRIMARY PHONE', style: TextStyle(color: Colors.white60, fontSize: 9)),
                            Text(phone, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ABDM Sync Button
              if (user?.abhaId?.isNotEmpty == true)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncingAbha
                        ? null
                        : () async {
                            setState(() => _isSyncingAbha = true);
                            final res = await AbhaService.instance
                                .fetchAndSyncAbhaRecords(user!.abhaId!);
                            if (mounted) {
                              setState(() => _isSyncingAbha = false);
                              final count = res['total_synced'] ?? 0;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['success'] == true
                                        ? '✅ Synced $count clinical records from Government ABDM Registry!'
                                        : '⚠️ ${res['message']}',
                                  ),
                                  backgroundColor: res['success'] == true
                                      ? const Color(0xFF00796B)
                                      : Colors.orange,
                                ),
                              );
                            }
                          },
                    icon: _isSyncingAbha
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, color: Colors.white),
                    label: Text(
                      _isSyncingAbha
                          ? 'Syncing ABDM Records...'
                          : '🔄 Fetch Health Records from ABHA Network',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Account Details List
              Container(
                decoration: appCardDecoration,
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      subtitle: phone,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.security_outlined,
                      title: 'System Role',
                      subtitle: roleTitle,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.cloud_done_outlined,
                      title: 'Sync Engine',
                      subtitle: 'Connected (Supabase & SQLite Hybrid)',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.language_outlined,
                      title: 'Language Preference',
                      subtitle: 'English / తెలుగు / हिंदी (Auto-switch)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await SessionManager.instance.clearSession();
                    selectedPageNotifier.value = 0;

                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const WelcomePage()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.statusRed),
                  label: const Text(
                    'Log Out of MediReach',
                    style: TextStyle(
                      color: AppColors.statusRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.statusRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
      title: Text(title, style: AppTextStyles.caption),
      subtitle: Text(subtitle, style: AppTextStyles.subheading),
    );
  }
}

