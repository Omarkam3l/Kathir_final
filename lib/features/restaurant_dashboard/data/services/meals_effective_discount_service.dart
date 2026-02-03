import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/meal_with_effective_discount.dart';

/// Service for fetching meals with effective discount (considering rush hour)
/// 
/// This service uses the meals_with_effective_discount view or RPC function
/// to ensure all meals are fetched with the correct pricing based on
/// current rush hour status.
/// 
/// IMPORTANT: Always use this service instead of querying meals directly
/// to ensure correct pricing in UI and checkout.
class MealsEffectiveDiscountService {
  final SupabaseClient _supabase;

  MealsEffectiveDiscountService(this._supabase);

  /// Fetches meals with effective discount using the RPC function
  /// 
  /// Parameters:
  ///   - restaurantId: Filter by restaurant (optional)
  ///   - category: Filter by category (optional)
  ///   - limit: Max number of results (default 50)
  ///   - offset: Pagination offset (default 0)
  /// 
  /// Returns: List of meals with computed effective prices
  /// 
  /// Throws: Exception if RPC call fails
  Future<List<MealWithEffectiveDiscount>> getMealsWithEffectiveDiscount({
    String? restaurantId,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_meals_with_effective_discount',
        params: {
          'p_restaurant_id': restaurantId,
          'p_category': category,
          'p_limit': limit,
          'p_offset': offset,
        },
      ) as List<dynamic>;

      return response
          .map((json) =>
              MealWithEffectiveDiscount.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch meals with effective discount: $e');
    }
  }

  /// Fetches meals for a specific restaurant with effective discount
  /// 
  /// Convenience method for restaurant dashboard
  Future<List<MealWithEffectiveDiscount>> getMyMealsWithEffectiveDiscount({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final restaurantId = _supabase.auth.currentUser?.id;
    if (restaurantId == null) {
      throw Exception('Not authenticated');
    }

    return getMealsWithEffectiveDiscount(
      restaurantId: restaurantId,
      category: category,
      limit: limit,
      offset: offset,
    );
  }

  /// Fetches all active meals with effective discount (for user browsing)
  /// 
  /// This is what users see when browsing meals
  Future<List<MealWithEffectiveDiscount>> getAllActiveMeals({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    return getMealsWithEffectiveDiscount(
      category: category,
      limit: limit,
      offset: offset,
    );
  }

  /// Calculates effective price for a single meal
  /// 
  /// Use this in checkout to ensure correct pricing
  /// 
  /// Parameters:
  ///   - mealId: The meal ID
  /// 
  /// Returns: Effective price considering rush hour
  /// 
  /// Throws: Exception if calculation fails
  Future<double> calculateEffectivePrice(String mealId) async {
    try {
      final response = await _supabase.rpc(
        'calculate_effective_price',
        params: {'p_meal_id': mealId},
      ) as num;

      return response.toDouble();
    } catch (e) {
      throw Exception('Failed to calculate effective price: $e');
    }
  }

  /// Fetches meals using the view (alternative to RPC)
  /// 
  /// This is simpler but offers less control over filtering
  /// Use RPC function for better performance with filters
  Future<List<MealWithEffectiveDiscount>> getMealsFromView({
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('meals_with_effective_discount')
          .select()
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) =>
              MealWithEffectiveDiscount.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch meals from view: $e');
    }
  }
}
