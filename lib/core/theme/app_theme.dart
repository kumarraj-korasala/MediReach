// ============================================================
// MediReach — Centralized Theme Constants
// Change values here to update the ENTIRE app at once.
// ============================================================
import 'package:flutter/material.dart';

class AppColors {
  // ── Primary palette ──────────────────────────────────────
  static const Color primary      = Color(0xFF26A69A); // teal
  static const Color primaryDark  = Color(0xFF00796B);
  static const Color primaryLight = Color(0xFF80CBC4);

  // ── Background ───────────────────────────────────────────
  static const Color background   = Color(0xFFF5F5F5);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color navBar       = Color(0xFF26A69A);

  // ── Status ───────────────────────────────────────────────
  static const Color statusGreen  = Color(0xFF4CAF50);
  static const Color statusAmber  = Color(0xFFFFC107);
  static const Color statusRed    = Color(0xFFF44336);
  static const Color statusBlue   = Color(0xFF2196F3);

  // ── Chip / tag colours ───────────────────────────────────
  static const Color chipPHC      = Color(0xFF2196F3); // blue
  static const Color chipCHC      = Color(0xFFF44336); // red
  static const Color chipHospital = Color(0xFF4CAF50); // green

  // ── Emergency banner ─────────────────────────────────────
  static const Color emergencyBg  = Color(0xFFFFEBEE);
  static const Color emergencyBorder = Color(0xFFEF9A9A);

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Card border ──────────────────────────────────────────
  static const Color cardBorder   = Color(0xFFE0E0E0);
}

class AppTextStyles {
  // ── Font family (change once to apply everywhere) ─────────
  static const String fontFamily = 'Roboto'; // or swap to 'Poppins' etc.

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

class AppDimens {
  // ── Border radius ─────────────────────────────────────────
  static const double radiusSmall  = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge  = 20.0;
  static const double radiusPill   = 50.0;

  // ── Padding ───────────────────────────────────────────────
  static const double paddingPage   = 16.0;
  static const double paddingCard   = 12.0;
  static const double gapSmall      = 8.0;
  static const double gapMedium     = 12.0;
  static const double gapLarge      = 16.0;

  // ── Card elevation ────────────────────────────────────────
  static const double elevationCard = 1.5;
}

// ── Reusable card decoration ─────────────────────────────────
BoxDecoration get appCardDecoration => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
  border: Border.all(color: AppColors.cardBorder),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ],
);
