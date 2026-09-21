import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:miracle/core/remote/api_client.dart';
import 'package:miracle/core/remote/abha_service.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/views/pages/signup_page.dart';

import '../widget_tree.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isAdmin = true;
  bool obscurePassword = true;
  bool _isLoading = false;

  String selectedRole = 'ANM';

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _showServerSettingsDialog() {
    final ipController = TextEditingController(text: ApiClient.instance.serverHost);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync, color: Colors.teal),
            SizedBox(width: 8),
            Text('Server Config', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a preset or enter a custom backend address:',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.cloud_done, size: 16, color: Colors.teal),
                    label: const Text('Cloudflare Tunnel', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ipController.text = ApiClient.defaultHost;
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.sync, size: 16, color: Colors.amber),
                    label: const Text('Auto-Detect from Cloud', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final live = await ApiClient.instance.autoDiscoverBackendUrl();
                      if (live != null) {
                        ipController.text = live;
                      }
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wifi, size: 16, color: Colors.indigo),
                    label: const Text('Local Wi-Fi (10.4.10.57)', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ipController.text = ApiClient.localWifiHost;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Server URL / IP',
                  hintText: 'https://xxx.trycloudflare.com or 10.4.10.57',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ipController.text.trim().isNotEmpty) {
                await ApiClient.instance.updateServerHost(ipController.text.trim());
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Connected to: ${ApiClient.instance.baseUrl}'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Save & Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,

          // =========================================================
          // BACKGROUND IMAGE
          // =========================================================
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/icon.jpeg'),
              fit: BoxFit.fitWidth,
              opacity: 0.7,
            ),
          ),

          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.settings_ethernet, color: Colors.teal, size: 28),
                        tooltip: 'Configure Backend Server IP',
                        onPressed: _showServerSettingsDialog,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // =================================================
                    // LOGIN TITLE
                    // =================================================
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 75),

                    // =================================================
                    // ADMIN / USER BUTTONS
                    // =================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTopButton(
                          title: 'Admin',
                          selected: isAdmin,
                          onTap: () {
                            setState(() {
                              isAdmin = true;
                            });
                          },
                        ),

                        const SizedBox(width: 32),

                        _buildTopButton(
                          title: 'User',
                          selected: !isAdmin,
                          onTap: () {
                            setState(() {
                              isAdmin = false;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // GLASS LOGIN CARD
                    // =================================================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 340),
                          padding: const EdgeInsets.fromLTRB(25, 22, 20, 15),
                          decoration: BoxDecoration(
                            // Transparent white glass
                            color: Colors.white.withValues(alpha: 0.22),

                            borderRadius: BorderRadius.circular(22),

                            // Glass border
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 1.3,
                            ),

                            // Soft shadow
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: 3,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),

                          child: Column(
                            children: [
                              // =================================================
                              // ROLE DROPDOWN
                              // =================================================
                              if (isAdmin) ...[
                                _buildGlassDropdown(),

                                const SizedBox(height: 20),
                              ],

                              // =================================================
                              // USERNAME / ABHA / MOBILE
                              // =================================================
                              _buildTextField(
                                controller: usernameController,
                                hintText: 'ABHA ID / Mobile / Username',
                                icon: Icons.badge_outlined,
                              ),

                              const SizedBox(height: 20),

                              // =================================================
                              // PASSWORD
                              // =================================================
                              _buildPasswordField(),

                              const SizedBox(height: 12),

                              // =================================================
                              // FORGOT PASSWORD
                              // =================================================
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    // UI only
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // =================================================
                              // LOGIN BUTTON
                              // =================================================
                                SizedBox(
                                  width: 130,
                                  height: 41,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            final username = usernameController.text.trim();
                                            final password = passwordController.text.trim();

                                            if (username.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Please enter your username or phone number.'),
                                                ),
                                              );
                                              return;
                                            }

                                            setState(() => _isLoading = true);

                                            final roleStr = isAdmin ? selectedRole : 'Citizen Patient';
                                            final response = await ApiClient.instance.post('/auth/login', {
                                              'username': username,
                                              'password': password,
                                              'role': roleStr,
                                            });

                                            if (!mounted) return;
                                            setState(() => _isLoading = false);

                                            if (response['success'] != true || response['user'] == null) {
                                              final errMsg = response['message'] ??
                                                  'Invalid credentials. Please check your username & password or create an account via SignUp.';
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('❌ $errMsg'),
                                                  backgroundColor: Colors.red.shade700,
                                                  duration: const Duration(seconds: 3),
                                                ),
                                              );
                                              return;
                                            }

                                            final u = response['user'];
                                            final id = u['id'] ?? 'usr-${DateTime.now().millisecondsSinceEpoch}';
                                            final name = u['name'] ?? username;
                                            final abhaId = u['abha_id'];
                                            UserRole userRole = UserRole.patient;

                                            final r = (u['role'] as String? ?? '').toLowerCase();
                                            if (r.contains('admin') || r.contains('superintendent')) {
                                              userRole = UserRole.admin;
                                            } else if (r.contains('doc')) {
                                              userRole = UserRole.doctor;
                                            } else if (r.contains('anm') ||
                                                r.contains('asha') ||
                                                r.contains('worker') ||
                                                r.contains('nurse')) {
                                              userRole = UserRole.healthWorker;
                                            } else {
                                              userRole = UserRole.patient;
                                            }

                                            final appUser = AppUser(
                                              id: id,
                                              name: name,
                                              role: userRole,
                                              phone: u['phone'] ?? username,
                                              abhaId: abhaId,
                                            );

                                            await SessionManager.instance.saveSession(appUser);

                                            // Automatically link and sync existing clinical records from ABDM
                                            if (abhaId != null && (abhaId as String).trim().isNotEmpty) {
                                              AbhaService.instance.fetchAndSyncAbhaRecords(abhaId.trim());
                                            }

                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('✅ Welcome back, ${appUser.name}! (${appUser.role.name.toUpperCase()})'),
                                                  backgroundColor: const Color(0xFF26A69A),
                                                ),
                                              );

                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const witree(),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),

                              const SizedBox(height: 23),

                              // =================================================
                              // SIGNUP
                              // =================================================
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don’t Have An Account ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return SignupPage();
                                          },
                                        ),
                                      );
                                      // UI
                                    },
                                    child: const Text(
                                      'Signup',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // GLASS DROPDOWN
  // =========================================================

  Widget _buildGlassDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,

              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.white,
              ),

              dropdownColor: const Color(0xFF83C69F),

              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),

              items: const [
                DropdownMenuItem(value: 'ANM', child: Text('🩺 ASHA / ANM Worker')),
                DropdownMenuItem(value: 'Doctor', child: Text('👨‍⚕️ Medical Officer / Doctor')),
                DropdownMenuItem(value: 'Admin', child: Text('🏛️ Hospital Administrator')),
              ],

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedRole = value;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TOP ADMIN / USER BUTTON
  // =========================================================

  Widget _buildTopButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.20),

          borderRadius: BorderRadius.circular(9),

          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 0.7 : 0.4),
            width: 1,
          ),

          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.20),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // GLASS USERNAME FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 11, color: Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,

              prefixIcon: Icon(icon, size: 17, color: Colors.black),

              hintText: hintText,

              hintStyle: const TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),

              contentPadding: const EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // GLASS PASSWORD FIELD
  // =========================================================

  Widget _buildPasswordField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,

            style: const TextStyle(fontSize: 11, color: Colors.black),

            decoration: InputDecoration(
              border: InputBorder.none,

              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 18,
                color: Colors.black,
              ),

              hintText: 'Password',

              hintStyle: const TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),

              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 17,
                  color: Colors.black,
                ),
              ),

              contentPadding: const EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
      ),
    );
  }
}
