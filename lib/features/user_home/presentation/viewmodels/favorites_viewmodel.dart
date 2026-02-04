import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/meal_offer.dart';
import '../../domain/entities/restaurant.dart';

class FavoritesViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool isLoading = true;
  String? error;
  List<MealOffer> favoriteMeals = [];
  Set<String> favoriteMealIds = {};
  
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> loadFavorites() async {
    if (currentUserId == null) {
      error = 'User not authenticated';
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Get favorite meal IDs
      final favoritesRes = await _supabase
          .from('favorites')
          .select('meal_id')
          .eq('user_id', currentUserId!);

      favoriteMealIds = (favoritesRes as List)
          .map((f) => f['meal_id'] as String)
          .toSet();

      if (favoriteMealIds.isEmpty) {
        favoriteMeals = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      // Get meal details with restaurant info
      final mealsRes = await _supabase
          .from('meals')
          .select('''
            *,
            restaurants:restaurant_id (
              restaurant_name,
              rating,
              address_text,
              profile_id
            )
          ''')
          .inFilter('id', favoriteMealIds.toList())
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String());

      favoriteMeals = (mealsRes as List).map((json) {
        final restaurantData = json['restaurants'];
        return MealOffer(
          id: json['id'],
          title: json['title'] ?? 'Delicious Meal',
          location: json['location'] ?? 'Cairo, Egypt',
          imageUrl: json['image_url'] ?? '',
          originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
          donationPrice: (json['discounted_price'] as num?)?.toDouble() ?? 0.0,
          quantity: json['quantity_available'] ?? 0,
          expiry: DateTime.parse(json['expiry_date']),
          restaurant: Restaurant(
            id: restaurantData?['profile_id'] ?? '',
            name: restaurantData?['restaurant_name'] ?? 'Unknown Restaurant',
            rating: (restaurantData?['rating'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String mealId) async {
    if (currentUserId == null) return false;

    try {
      if (favoriteMealIds.contains(mealId)) {
        // Remove from favorites
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', currentUserId!)
            .eq('meal_id', mealId);
        
        favoriteMealIds.remove(mealId);
        favoriteMeals.removeWhere((meal) => meal.id == mealId);
      } else {
        // Add to favorites
        await _supabase.from('favorites').insert({
          'user_id': currentUserId!,
          'meal_id': mealId,
        });
        
        favoriteMealIds.add(mealId);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  bool isFavorite(String mealId) {
    return favoriteMealIds.contains(mealId);
  }
}
