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
  List<Restaurant> favoriteRestaurants = [];
  Set<String> favoriteRestaurantIds = {};
  
  // Category preferences
  List<String> subscribedCategories = [];
  bool isCategoriesLoading = false;
  
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
      // Parallel loading for better performance
      final results = await Future.wait([
        _loadFavoriteMeals(),
        _loadFavoriteRestaurants(),
      ]);
      
      // Results are already set in the individual methods
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavoriteMeals() async {
    try {
      // Step 1: Get favorite meal IDs (limit to 50 most recent)
      final favoritesRes = await _supabase
          .from('favorites')
          .select('meal_id, created_at')
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false)
          .limit(50);

      final mealIds = (favoritesRes as List)
          .map((f) => f['meal_id'] as String)
          .toList();

      if (mealIds.isEmpty) {
        favoriteMeals = [];
        favoriteMealIds = {};
        return;
      }

      // Step 2: Get meal details with restaurant info for those IDs
      final mealsRes = await _supabase
          .from('meals')
          .select('''
            id,
            title,
            location,
            image_url,
            original_price,
            discounted_price,
            quantity_available,
            expiry_date,
            restaurants:restaurant_id (
              restaurant_name,
              rating,
              profile_id
            )
          ''')
          .inFilter('id', mealIds)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String());

      favoriteMealIds = <String>{};
      favoriteMeals = (mealsRes as List).map((mealData) {
        final restaurantData = mealData['restaurants'];
        final mealId = mealData['id'] as String;
        
        favoriteMealIds.add(mealId);
        
        return MealOffer(
          id: mealId,
          title: mealData['title'] ?? 'Delicious Meal',
          location: mealData['location'] ?? 'Cairo, Egypt',
          imageUrl: mealData['image_url'] ?? '',
          originalPrice: (mealData['original_price'] as num?)?.toDouble() ?? 0.0,
          donationPrice: (mealData['discounted_price'] as num?)?.toDouble() ?? 0.0,
          quantity: mealData['quantity_available'] ?? 0,
          expiry: DateTime.parse(mealData['expiry_date']),
          restaurant: Restaurant(
            id: restaurantData?['profile_id'] ?? '',
            name: restaurantData?['restaurant_name'] ?? 'Unknown Restaurant',
            rating: (restaurantData?['rating'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading favorite meals: $e');
      favoriteMeals = [];
      favoriteMealIds = {};
    }
  }

  Future<void> _loadFavoriteRestaurants() async {
    try {
      // Step 1: Get favorite restaurant IDs (limit to 50 most recent)
      final favoritesRes = await _supabase
          .from('favorite_restaurants')
          .select('restaurant_id, created_at')
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false)
          .limit(50);

      final restaurantIds = (favoritesRes as List)
          .map((f) => f['restaurant_id'] as String)
          .toList();

      if (restaurantIds.isEmpty) {
        favoriteRestaurants = [];
        favoriteRestaurantIds = {};
        return;
      }

      // Step 2: Get restaurant details with profile for those IDs
      final restaurantsRes = await _supabase
          .from('restaurants')
          .select('''
            profile_id,
            restaurant_name,
            rating,
            profiles!inner(avatar_url)
          ''')
          .inFilter('profile_id', restaurantIds);

      favoriteRestaurantIds = <String>{};
      favoriteRestaurants = (restaurantsRes as List).map((restaurantData) {
        final profileData = restaurantData['profiles'];
        final restaurantId = restaurantData['profile_id'] as String;
        
        favoriteRestaurantIds.add(restaurantId);
        
        return Restaurant(
          id: restaurantId,
          name: restaurantData['restaurant_name'] ?? 'Unknown',
          rating: (restaurantData['rating'] as num?)?.toDouble() ?? 0.0,
          logoUrl: profileData?['avatar_url'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading favorite restaurants: $e');
      favoriteRestaurants = [];
      favoriteRestaurantIds = {};
    }
  }

  Future<List<MealOffer>> getMealsForRestaurant(String restaurantId) async {
    try {
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
          .eq('restaurant_id', restaurantId)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String());

      return (mealsRes as List).map((json) {
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
      debugPrint('Error getting meals for restaurant: $e');
      return [];
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

  Future<bool> favoriteRestaurant(String restaurantId) async {
    if (currentUserId == null) return false;

    try {
      // Add restaurant to favorite_restaurants table
      await _supabase.from('favorite_restaurants').insert({
        'user_id': currentUserId!,
        'restaurant_id': restaurantId,
      });

      favoriteRestaurantIds.add(restaurantId);

      // Reload favorites to update the list
      await loadFavorites();
      
      return true;
    } catch (e) {
      debugPrint('Error favoriting restaurant: $e');
      return false;
    }
  }

  Future<bool> unfavoriteRestaurant(String restaurantId) async {
    if (currentUserId == null) return false;

    try {
      // Remove restaurant from favorite_restaurants table
      await _supabase
          .from('favorite_restaurants')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('restaurant_id', restaurantId);

      favoriteRestaurantIds.remove(restaurantId);
      favoriteRestaurants.removeWhere((r) => r.id == restaurantId);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error unfavoriting restaurant: $e');
      return false;
    }
  }

  bool isRestaurantFavorite(String restaurantId) {
    return favoriteRestaurantIds.contains(restaurantId);
  }

  // =====================================================
  // CATEGORY PREFERENCES METHODS
  // =====================================================

  Future<void> loadCategoryPreferences() async {
    if (currentUserId == null) {
      debugPrint('❌ loadCategoryPreferences: No user ID');
      return;
    }

    isCategoriesLoading = true;
    notifyListeners();

    try {
      debugPrint('🔄 Loading category preferences for user: $currentUserId');
      final response = await _supabase
          .from('user_category_preferences')
          .select('category')
          .eq('user_id', currentUserId!)
          .eq('notifications_enabled', true);

      subscribedCategories = (response as List)
          .map((item) => item['category'] as String)
          .toList();
      
      debugPrint('✅ Loaded ${subscribedCategories.length} subscribed categories: $subscribedCategories');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading category preferences: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      isCategoriesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleCategorySubscription(String category) async {
    if (currentUserId == null) {
      debugPrint('❌ toggleCategorySubscription: No user ID');
      return false;
    }

    try {
      if (subscribedCategories.contains(category)) {
        // Unsubscribe
        debugPrint('🔄 Unsubscribing from category: $category for user: $currentUserId');
        await _supabase
            .from('user_category_preferences')
            .delete()
            .eq('user_id', currentUserId!)
            .eq('category', category);
        
        subscribedCategories.remove(category);
        debugPrint('✅ Successfully unsubscribed from: $category');
      } else {
        // Subscribe
        debugPrint('🔄 Subscribing to category: $category for user: $currentUserId');
        final result = await _supabase.from('user_category_preferences').insert({
          'user_id': currentUserId!,
          'category': category,
          'notifications_enabled': true,
        }).select();
        
        debugPrint('✅ Successfully subscribed to: $category');
        debugPrint('📊 Insert result: $result');
        
        subscribedCategories.add(category);
      }
      
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error toggling category subscription: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  bool isCategorySubscribed(String category) {
    return subscribedCategories.contains(category);
  }

  // Get all available meal categories
  List<Map<String, dynamic>> get availableCategories => [
    {'icon': Icons.restaurant, 'name': 'Meals', 'desc': 'Ready-to-eat meals'},
    {'icon': Icons.bakery_dining, 'name': 'Bakery', 'desc': 'Fresh bread & pastries'},
    {'icon': Icons.dinner_dining, 'name': 'Meat & Poultry', 'desc': 'Fresh meat & poultry'},
    {'icon': Icons.set_meal, 'name': 'Seafood', 'desc': 'Fresh fish & seafood'},
    {'icon': Icons.eco, 'name': 'Vegetables', 'desc': 'Farm fresh produce'},
    {'icon': Icons.cake, 'name': 'Desserts', 'desc': 'Sweet treats'},
    {'icon': Icons.shopping_basket, 'name': 'Groceries', 'desc': 'Pantry essentials'},
  ];
}
