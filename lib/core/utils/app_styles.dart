import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Centralized text styles and common widget styles
class AppStyles {
  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.darkText,
    letterSpacing: -0.5,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.darkText,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 20,
    color: AppColors.darkText,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.darkText,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.darkText,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondaryAccent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
    ),
  );

  // Card Shadows
  static List<BoxShadow> get defaultCardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get hoverCardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

