import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:miracle/core/remote/api_client.dart';
import 'package:miracle/core/remote/abha_service.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/data/models/models.dart';
import 'package:miracle/views/pages/login_page.dart';

import '../widget_tree.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool obscurePassword = true;
  bool _isLoading = false;

  String selectedRole = 'Citizen Patient';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController abhaController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    abhaController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final abhaId = abhaController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a valid username/email and password.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post('/auth/signup', {
        'name': name.isNotEmpty ? name : username,
        'username': username,
        'phone': phone,
        'password': password,
        'role': selectedRole,
        'abha_id': abhaId,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] != true || response['user'] == null) {
        final errMsg = response['message'] ?? 'Registration failed. Please check your information.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $errMsg'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      UserRole userRole = UserRole.patient;
      String rawRole = selectedRole.toLowerCase();
      if (rawRole.contains('admin') || rawRole.contains('superintendent')) {
        userRole = UserRole.admin;
      } else if (rawRole.contains('doc')) {
        userRole = UserRole.doctor;
      } else if (rawRole.contains('anm') ||
          rawRole.contains('asha') ||
          rawRole.contains('nurse') ||
          rawRole.contains('worker')) {
        userRole = UserRole.healthWorker;
      } else {
        userRole = UserRole.patient;
      }

      String userId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
      String displayName = name.isNotEmpty ? name : username;

      final u = response['user'];
      userId = u['id'] ?? userId;
      displayName = u['name'] ?? displayName;

      final appUser = AppUser(
        id: userId,
        name: displayName,
        phone: phone.isNotEmpty ? phone : username,
        role: userRole,
        abhaId: abhaId.isNotEmpty ? abhaId : null,
      );

      await SessionManager.instance.saveSession(appUser);

      // Automatically sync existing records from ABDM if ABHA ID was provided
      if (abhaId.isNotEmpty) {
        AbhaService.instance.fetchAndSyncAbhaRecords(abhaId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Welcome to MediReach, ${appUser.name}! Registered as $selectedRole.',
            ),
            backgroundColor: const Color(0xFF26A69A),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const witree()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/icon.jpeg'),
              fit: BoxFit.fitWidth,
              opacity: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 75),

                    // =================================================
                    // SIGNUP TITLE
                    // =================================================
                    Row(
                      children: [
                        const Text(
                          'MediReach',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Create Your Health Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 45),

                    // =================================================
                    // GLASS SIGNUP CARD
                    // =================================================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.65),
                              width: 1.3,
                            ),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role Selection Label
                              const Text(
                                'Select Account Role',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildGlassDropdown(),

                              const SizedBox(height: 14),

                              // Full Name
                              _buildTextField(
                                controller: nameController,
                                hintText: 'Full Name (e.g. Lakshmi Devi)',
                                icon: Icons.badge_outlined,
                              ),

                              const SizedBox(height: 12),

                              // Username / Email
                              _buildTextField(
                                controller: usernameController,
                                hintText: 'Username or Email ID',
                                icon: Icons.person_outline,
                              ),

                              const SizedBox(height: 12),

                              // Phone (Rural Family Friendly)
                              _buildTextField(
                                controller: phoneController,
                                hintText: 'Mobile (+91) • Shared Family Phone OK',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),

                              const SizedBox(height: 12),

                              // ABHA ID
                              _buildTextField(
                                controller: abhaController,
                                hintText: 'Family ABHA ID (e.g. 91-1234-5678-9012)',
                                icon: Icons.health_and_safety_outlined,
                              ),

                              const SizedBox(height: 4),
                              const Text(
                                '💡 Rural Family: One mobile phone can be shared by family accounts. ABHA ID connects your health records.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Password
                              _buildPasswordField(),

                              const SizedBox(height: 20),

                              // Submit Button
                              SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                    foregroundColor: Colors.black,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
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
                                          'CREATE ACCOUNT',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Already have account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Color(0xFF004D40),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
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
  // GLASS ROLE DROPDOWN
  // =========================================================
  Widget _buildGlassDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
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
                color: Colors.black87,
              ),
              dropdownColor: const Color(0xFFE0F2F1),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Citizen Patient',
                  child: Text('👤 Citizen Patient (Self / Family)'),
                ),
                DropdownMenuItem(
                  value: 'ASHA Field Worker',
                  child: Text('🩺 ASHA / ANM Health Worker'),
                ),
                DropdownMenuItem(
                  value: 'Medical Officer Doctor',
                  child: Text('👨‍⚕️ Medical Officer / Doctor'),
                ),
                DropdownMenuItem(
                  value: 'Hospital Administrator',
                  child: Text('🏛️ Hospital Administrator'),
                ),
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
  // GLASS TEXT FIELD
  // =========================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, size: 18, color: Colors.black87),
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
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
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 18,
                color: Colors.black87,
              ),
              hintText: 'Password',
              hintStyle: TextStyle(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
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
                  size: 18,
                  color: Colors.black87,
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
