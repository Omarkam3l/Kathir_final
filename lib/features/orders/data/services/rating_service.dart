import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit or update restaurant rating
  Future<void> submitRating({
    required String orderId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      debugPrint('🌟 ========== SUBMIT RATING START ==========');
      debugPrint('Order ID: $orderId');
      debugPrint('Rating: $rating stars');
      debugPrint('Review: ${reviewText ?? "(none)"}');

      final response = await _supabase.rpc('submit_restaurant_rating', params: {
        'p_order_id': orderId,
        'p_rating': rating,
        'p_review_text': reviewText,
      });

      debugPrint('Response: $response');

      if (response is Map && response['success'] != true) {
        final error = response['error'] ?? 'Failed to submit rating';
        debugPrint('❌ Rating submission failed: $error');
        throw Exception(error);
      }

      debugPrint('✅ Rating submitted successfully');
      debugPrint('==============================================');
    } catch (e, stackTrace) {
      debugPrint('❌ Error submitting rating: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if user can rate an order
  Future<Map<String, dynamic>> canRateOrder(String orderId) async {
    try {
      debugPrint('🔍 Checking if can rate order: $orderId');

      final response = await _supabase.rpc('can_rate_order', params: {
        'p_order_id': orderId,
      });

      debugPrint('Can rate response: $response');

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      return {
        'can_rate': false,
        'reason': 'Invalid response format',
      };
    } catch (e) {
      debugPrint('❌ Error checking rating eligibility: $e');
      return {
        'can_rate': false,
        'reason': 'Error checking eligibility: ${e.toString()}',
      };
    }
  }

  /// Get restaurant ratings
  Future<List<Map<String, dynamic>>> getRestaurantRatings({
    required String restaurantId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('📊 Fetching ratings for restaurant: $restaurantId');

      final response = await _supabase.rpc('get_restaurant_ratings', params: {
        'p_restaurant_id': restaurantId,
        'p_limit': limit,
        'p_offset': offset,
      });

      if (response is List) {
        final ratings = List<Map<String, dynamic>>.from(
          response.map((item) => Map<String, dynamic>.from(item)),
        );
        debugPrint('✅ Fetched ${ratings.length} ratings');
        return ratings;
      }

      debugPrint('⚠️ No ratings found or invalid format');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching ratings: $e');
      return [];
    }
  }

  /// Get rating for a specific order
  Future<Map<String, dynamic>?> getOrderRating(String orderId) async {
    try {
      final response = await _supabase
          .from('restaurant_ratings')
          .select('rating, review_text, created_at')
          .eq('order_id', orderId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('❌ Error fetching order rating: $e');
      return null;
    }
  }
}
