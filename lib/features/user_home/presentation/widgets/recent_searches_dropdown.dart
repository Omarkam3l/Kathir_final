import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import '../../domain/entities/recent_search.dart';

/// Dropdown body — designed to sit inside the same card as the search field.
/// No border/shadow/margin — the parent container handles that.
class RecentSearchesDropdown extends StatelessWidget {
  final List<RecentSearch> searches;
  final bool isLoading;
  final ValueChanged<String> onSearchTap;
  final ValueChanged<String> onDeleteTap;
  final VoidCallback onClearAll;

  const RecentSearchesDropdown({
    super.key,
    required this.searches,
    required this.isLoading,
    required this.onSearchTap,
    required this.onDeleteTap,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppColors.white : AppColors.darkText;
    final divider = isDark ? AppColors.dividerDark : const Color(0xFFEEEEEE);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: divider),
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
          child: Row(
            children: [
              const Icon(Icons.history, size: 16, color: AppColors.grey),
              const SizedBox(width: 6),
              Text(
                'Recent Searches',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
              const Spacer(),
              if (searches.isNotEmpty)
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Body
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (searches.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Text(
              'No recent searches',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.grey,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searches.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: divider),
            itemBuilder: (context, index) {
              final item = searches[index];
              return _SearchItem(
                query: item.query,
                textColor: textMain,
                onTap: () => onSearchTap(item.query),
                onDelete: () => onDeleteTap(item.id),
              );
            },
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SearchItem extends StatelessWidget {
  final String query;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SearchItem({
    required this.query,
    required this.textColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: AppColors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                query,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 16, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
