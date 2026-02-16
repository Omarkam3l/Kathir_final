import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loyalty_profile.dart';
import '../models/user_badge.dart';
import '../models/reward.dart';

class LoyaltyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user's loyalty profile
  Future<LoyaltyProfile?> getLoyaltyProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_loyalty')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return LoyaltyProfile.fromJson(response);
    } catch (e) {
      print('Error fetching loyalty profile: $e');
      rethrow;
    }
  }

  // Get user's badges
  Future<List<UserBadge>> getUserBadges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_badges')
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return (response as List)
          .map((json) => UserBadge.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching badges: $e');
      return [];
    }
  }

  // Get available rewards from catalog
  Future<List<Reward>> getAvailableRewards() async {
    try {
      final response = await _supabase
          .from('rewards_catalog')
          .select()
          .eq('is_active', true)
          .order('points_cost', ascending: true);

      return (response as List)
          .map((json) => Reward.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching rewards: $e');
      return [];
    }
  }

  // Get user's redeemed rewards
  Future<List<UserReward>> getUserRewards({String? status}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from('user_rewards')
          .select('*, rewards_catalog(*)')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('redeemed_at', ascending: false);

      return (response as List)
          .map((json) => UserReward.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching user rewards: $e');
      return [];
    }
  }

  // Redeem a reward
  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc('redeem_reward', params: {
        'p_user_id': userId,
        'p_reward_id': rewardId,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error redeeming reward: $e');
      rethrow;
    }
  }

  // Get points history
  Future<List<Map<String, dynamic>>> getPointsHistory({int limit = 20}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('loyalty_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching points history: $e');
      return [];
    }
  }

  // Check if user can redeem reward
  Future<bool> canRedeemReward(String rewardId) async {
    try {
      final profile = await getLoyaltyProfile();
      if (profile == null) return false;

      final rewards = await getAvailableRewards();
      final reward = rewards.firstWhere((r) => r.id == rewardId);

      return reward.canRedeem(profile.currentTier, profile.availablePoints);
    } catch (e) {
      print('Error checking reward eligibility: $e');
      return false;
    }
  }
}
