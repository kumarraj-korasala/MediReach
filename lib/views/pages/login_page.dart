import 'dart:ui';

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isAdmin = true;
  bool obscurePassword = true;

  String selectedRole = 'ANM';

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
              opacity: 0.5,
            ),
          ),

          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),

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
                              // USERNAME
                              // =================================================
                              _buildTextField(
                                controller: usernameController,
                                hintText: 'username/email ID',
                                icon: Icons.email,
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
                                width: 115,
                                height: 41,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // UI only
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
                                  child: const Text(
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
                                      // UI only
                                    },
                                    child: const Text(
                                      'Signup',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
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
                DropdownMenuItem(value: 'ANM', child: Text('ANM')),
                DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
                DropdownMenuItem(value: 'Nurse', child: Text('Nurse')),
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
