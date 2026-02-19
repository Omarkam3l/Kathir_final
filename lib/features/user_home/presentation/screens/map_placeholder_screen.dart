import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Placeholder for the Map tab. Can be replaced with a real map later.
class MapPlaceholderScreen extends StatelessWidget {
  const MapPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textMain = isDark ? AppColors.white : AppColors.darkText;
    const muted = AppColors.grey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Map',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find surplus meals near you.\nComing soon.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
