import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/models/loyalty_profile.dart';

class TierProgressCard extends StatelessWidget {
  final LoyaltyProfile profile;

  const TierProgressCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = profile.currentTier == 'platinum' 
        ? 1.0 
        : (profile.lifetimePoints % _getTierThreshold(profile.currentTier)) / _getTierThreshold(profile.currentTier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                profile.currentTier == 'platinum' 
                    ? 'Max Tier Reached!' 
                    : 'Progress to ${profile.nextTierName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.darkText,
                ),
              ),
              if (profile.currentTier != 'platinum')
                Text(
                  '${profile.pointsToNextTier} points to go',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  int _getTierThreshold(String tier) {
    switch (tier) {
      case 'bronze': return 200;
      case 'silver': return 500;
      case 'gold': return 1000;
      default: return 1000;
    }
  }
}
