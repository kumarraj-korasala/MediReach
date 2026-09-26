// ============================================================
// MediReach — Rural Audio Voice Assistant Helper
// Provides visual and audible feedback for low-literacy users.
// ============================================================
import 'package:flutter/material.dart';
import 'package:miracle/core/localization/app_localizations.dart';
import 'package:miracle/core/theme/app_theme.dart';

class TtsHelper {
  static void speakDialog({
    required BuildContext context,
    required String title,
    required String messageEn,
    required String messageTe,
    required String messageHi,
  }) {
    final lang = appLanguageNotifier.value;
    String message;
    String langName;

    if (lang == AppLanguage.te) {
      message = messageTe;
      langName = 'తెలుగు వాయిస్ గైడెన్స్ (Telugu Audio)';
    } else if (lang == AppLanguage.hi) {
      message = messageHi;
      langName = 'हिंदी वॉइस मार्गदर्शन (Hindi Audio)';
    } else {
      message = messageEn;
      langName = 'English Voice Guidance';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
        title: Row(
          children: [
            const Icon(Icons.volume_up_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.heading.copyWith(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Text(
                langName,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.graphic_eq_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 6),
                Text('Playing Audio Readout...',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close Audio', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
  }
}
