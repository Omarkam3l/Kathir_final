import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/meal_offer.dart';
import 'rush_hour_meal_card.dart';

/// Rush Hour Section - Simple display of rush hour meals
class RushHourSection extends StatelessWidget {
  final List<MealOffer> rushHourMeals;
  final bool isLoading;
  final VoidCallback? onSeeAll;

  const RushHourSection({
    super.key,
    required this.rushHourMeals,
    this.isLoading = false,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader(isDark),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: isLoading
              ? _buildLoadingState()
              : rushHourMeals.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rushHourMeals.length,
                      itemBuilder: (context, index) {
                        final meal = rushHourMeals[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 220,
                            child: RushHourMealCard(
                              offer: meal,
                              showRushHourBadge: true,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D241B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_outlined,
              size: 48,
              color: AppColors.primaryGreen.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عروض Rush Hour حالياً',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1B140D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'تحقق مرة أخرى لاحقاً للحصول على عروض مذهلة!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bolt,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Rush Hour Deals',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1B140D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'LIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Limited time offers - Grab them fast!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
      ],
    );
  }
}
