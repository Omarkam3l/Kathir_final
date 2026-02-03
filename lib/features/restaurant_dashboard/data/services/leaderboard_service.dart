import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// Service for fetching restaurant leaderboard data
/// 
/// This service provides a safe, efficient way to get leaderboard data
/// from Supabase without exposing raw tables or causing N+1 queries.
/// 
/// Key features:
/// - Uses RPC functions for efficient server-side computation
/// - In-memory caching to reduce API calls
/// - Proper error handling with typed exceptions
/// - No client-side joins or heavy sorting
class LeaderboardService {
  final SupabaseClient _supabase;
  
  // In-memory cache
  Map<String, List<LeaderboardEntry>>? _cache;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  LeaderboardService(this._supabase);

  /// Fetches the restaurant leaderboard for a given period
  /// 
  /// Parameters:
  ///   - period: 'week', 'month', or 'all'
  ///   - forceRefresh: if true, bypasses cache
  /// 
  /// Returns: List of LeaderboardEntry sorted by rank
  /// 
  /// Throws: Exception if the RPC call fails
  Future<List<LeaderboardEntry>> fetchLeaderboard(
    String period, {
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _isCacheValid() && _cache != null) {
      final cached = _cache![period];
      if (cached != null) {
        return cached;
      }
    }

    try {
      // Call the RPC function
      final response = await _supabase.rpc(
        'get_restaurant_leaderboard',
        params: {'period_filter': period},
      ) as List<dynamic>;

      // Parse response
      final entries = response
          .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      _cache ??= {};
      _cache![period] = entries;
      _cacheTimestamp = DateTime.now();

      return entries;
    } catch (e) {
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }

  /// Fetches the current user's restaurant rank
  /// 
  /// Parameters:
  ///   - period: 'week', 'month', or 'all'
  /// 
  /// Returns: MyRestaurantRank or null if not found
  /// 
  /// Throws: Exception if the RPC call fails
  Future<MyRestaurantRank?> fetchMyRank(String period) async {
    try {
      final response = await _supabase.rpc(
        'get_my_restaurant_rank',
        params: {'period_filter': period},
      ) as List<dynamic>;

      if (response.isEmpty) {
        return null;
      }

      return MyRestaurantRank.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch my rank: $e');
    }
  }

  /// Clears the in-memory cache
  void clearCache() {
    _cache = null;
    _cacheTimestamp = null;
  }

  /// Checks if the cache is still valid
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }
}
