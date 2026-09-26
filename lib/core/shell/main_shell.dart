import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';
import 'package:miracle/features/home/home_screen.dart';
import 'package:miracle/features/patient/patient_list_screen.dart';
import 'package:miracle/views/pages/profile_page.dart';
import 'package:miracle/data/notifiers.dart';

/// Main scaffold used after login.
/// Pages: [0] Home  [1] Nearby/Map  [2] Profile
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static final List<Widget> _pages = [
    const HomeScreen(),
    const PatientListScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, index, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: _pages[index],
          bottomNavigationBar: _buildNavBar(index),
        );
      },
    );
  }

  Widget _buildNavBar(int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBar,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => selectedPageNotifier.value = 0,
              ),
              _NavItem(
                icon: Icons.location_on_rounded,
                label: 'Nearby',
                selected: selectedIndex == 1,
                onTap: () => selectedPageNotifier.value = 1,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: selectedIndex == 2,
                onTap: () => selectedPageNotifier.value = 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected
                ? AppColors.textOnPrimary
                : AppColors.textOnPrimary.withValues(alpha: 0.6),
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected
                  ? AppColors.textOnPrimary
                  : AppColors.textOnPrimary.withValues(alpha: 0.6),
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
