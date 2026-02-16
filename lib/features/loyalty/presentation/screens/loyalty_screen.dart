import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/models/loyalty_profile.dart';
import '../../data/models/user_badge.dart';
import '../../data/models/reward.dart';
import '../../data/services/loyalty_service.dart';
import '../widgets/loyalty_header_card.dart';
import '../widgets/tier_progress_card.dart';
import '../widgets/badges_section.dart';
import '../widgets/rewards_section.dart';
import '../widgets/stats_section.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final LoyaltyService _loyaltyService = LoyaltyService();
  
  LoyaltyProfile? _profile;
  List<UserBadge> _badges = [];
  List<Reward> _availableRewards = [];
  List<UserReward> _userRewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _loyaltyService.getLoyaltyProfile(),
        _loyaltyService.getUserBadges(),
        _loyaltyService.getAvailableRewards(),
        _loyaltyService.getUserRewards(status: 'active'),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as LoyaltyProfile?;
          _badges = results[1] as List<UserBadge>;
          _availableRewards = results[2] as List<Reward>;
          _userRewards = results[3] as List<UserReward>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading loyalty data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _redeemReward(Reward reward) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Redeem ${reward.title}?'),
          content: Text(
            'This will cost ${reward.pointsCost} points. '
            'The reward will be valid for ${reward.validDays} days.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Redeem'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Redeem reward
      final result = await _loyaltyService.redeemReward(reward.id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${reward.title} redeemed successfully!'),
              backgroundColor: AppColors.success,
            ),
          );

          // Reload data
          _loadData();
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to redeem reward'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    if (_isLoading) {
      return Container(
        color: bg,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
        ),
      );
    }

    if (_profile == null) {
      return Container(
        color: bg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No loyalty profile found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: bg,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with points and tier
              LoyaltyHeaderCard(profile: _profile!),
              
              const SizedBox(height: 16),
              
              // Tier progress
              TierProgressCard(profile: _profile!),
              
              const SizedBox(height: 24),
              
              // Stats
              StatsSection(profile: _profile!),
              
              const SizedBox(height: 24),
              
              // Badges
              BadgesSection(badges: _badges),
              
              const SizedBox(height: 24),
              
              // Active Rewards
              if (_userRewards.isNotEmpty) ...[
                Text(
                  'Active Rewards',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                ..._userRewards.map((userReward) => _buildActiveRewardCard(userReward, isDark)),
                const SizedBox(height: 24),
              ],
              
              // Available Rewards
              RewardsSection(
                rewards: _availableRewards,
                profile: _profile!,
                onRedeemReward: _redeemReward,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRewardCard(UserReward userReward, bool isDark) {
    final reward = userReward.reward;
    if (reward == null) return const SizedBox.shrink();

    final daysLeft = userReward.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reward.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires in $daysLeft days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ACTIVE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
