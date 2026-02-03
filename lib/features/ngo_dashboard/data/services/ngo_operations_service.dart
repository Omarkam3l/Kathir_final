import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for calling NGO-specific Supabase Edge Functions
class NgoOperationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Claim a meal with advanced validation and order creation
  Future<Map<String, dynamic>> claimMeal({
    required String mealId,
    required String ngoId,
    int quantity = 1,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ngo-operations',
        body: {
          'action': 'claim_meal',
          'meal_id': mealId,
          'ngo_id': ngoId,
          'quantity': quantity,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to claim meal: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error claiming meal: $e');
    }
  }

  /// Get nearby meals based on location
  Future<List<dynamic>> getNearbyMeals({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ngo-operations',
        body: {
          'action': 'get_nearby_meals',
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to fetch nearby meals: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      return data['meals'] as List<dynamic>;
    } catch (e) {
      throw Exception('Error fetching nearby meals: $e');
    }
  }

  /// Get comprehensive NGO statistics
  Future<Map<String, dynamic>> getNgoStats() async {
    try {
      final response = await _supabase.functions.invoke(
        'ngo-operations',
        body: {
          'action': 'get_ngo_stats',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to fetch stats: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      return data['stats'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  /// Calculate environmental and social impact
  Future<Map<String, dynamic>> calculateImpact() async {
    try {
      final response = await _supabase.functions.invoke(
        'ngo-operations',
        body: {
          'action': 'calculate_impact',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to calculate impact: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      return data['impact'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error calculating impact: $e');
    }
  }
}
