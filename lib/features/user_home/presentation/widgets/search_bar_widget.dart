import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Search field + filter (tune) button.
class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onFilterTap;
  final String hint;

  const SearchBarWidget({
    super.key,
    required this.onQueryChanged,
    this.onFilterTap,
    this.hint = 'Search for meals...',
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.glassCardBg; // ← استخدام اللون من AppColors
    const textMain = Color(0xFF0F1B3D);
    const muted = Color(0xFF6B7A99);
    final border = AppColors.glassCardBorder; // ← استخدام اللون من AppColors

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onQueryChanged,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMain,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: muted,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 22, color: muted),                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onFilterTap ?? () => context.push('/restaurant-search'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.map_outlined,
                  size: 22,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
