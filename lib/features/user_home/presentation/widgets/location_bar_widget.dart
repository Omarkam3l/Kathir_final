import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Location bar: icon, city/area, expand_more.
class LocationBarWidget extends StatelessWidget {
  final String location;
  final VoidCallback? onTap;

  const LocationBarWidget({
    super.key,
    this.location = 'Downtown, San Francisco',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppColors.white : AppColors.darkText;
    final primary = AppColors.primary;
    final muted = AppColors.grey;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 20, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more, size: 20, color: muted),
          ],
        ),
      ),
    );
  }
}
