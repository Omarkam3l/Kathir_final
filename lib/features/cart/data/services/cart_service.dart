import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../user_home/domain/entities/restaurant.dart';
import '../../../profile/presentation/providers/foodie_state.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Load cart from database
  Future<List<CartItem>> loadCart(String userId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('''
            id,
            meal_id,
            quantity,
            created_at,
            meals (
              id,
              title,
              image_url,
              original_price,
              discounted_price,
              quantity_available,
              expiry_date,
              location,
              restaurant_id,
              restaurants (
                profile_id,
                restaurant_name,
                rating
              )
            )
          ''')
          .eq('user_id', userId);

      final List<CartItem> cartItems = [];

      for (final json in response as List) {
        final mealData = json['meals'];
        if (mealData == null) {
          // Meal was deleted, remove from cart
          await _supabase
              .from('cart_items')
              .delete()
              .eq('id', json['id']);
          continue;
        }

        final restaurantData = mealData['restaurants'];
        
        // Parse prices with null safety
        final originalPrice = (mealData['original_price'] as num?)?.toDouble();
        final discountedPrice = (mealData['discounted_price'] as num?)?.toDouble();
        
        // Skip meals with invalid prices (NULL or NaN)
        // Note: 0 is valid for free meals!
        if (originalPrice == null || discountedPrice == null || 
            originalPrice.isNaN || discountedPrice.isNaN ||
            originalPrice < 0 || discountedPrice < 0) {
          print('Skipping meal ${mealData['id']} - invalid prices: original=$originalPrice, discounted=$discountedPrice');
          // Remove invalid item from cart
          await _supabase
              .from('cart_items')
              .delete()
              .eq('id', json['id']);
          continue;
        }

        // Parse expiry date safely
        DateTime expiryDate;
        try {
          expiryDate = DateTime.parse(mealData['expiry_date']);
        } catch (e) {
          print('Invalid expiry date for meal ${mealData['id']}: ${mealData['expiry_date']}');
          expiryDate = DateTime.now().add(const Duration(days: 1));
        }

        final meal = MealOffer(
          id: mealData['id'],
          title: mealData['title'] ?? 'Unknown Meal',
          location: mealData['location'] ?? 'Cairo, Egypt',
          imageUrl: mealData['image_url'] ?? '',
          originalPrice: originalPrice,
          donationPrice: discountedPrice,
          quantity: (mealData['quantity_available'] as int?) ?? 0,
          expiry: expiryDate,
          restaurant: Restaurant(
            id: restaurantData?['profile_id'] ?? '',
            name: restaurantData?['restaurant_name'] ?? 'Restaurant',
            rating: (restaurantData?['rating'] as num?)?.toDouble() ?? 0.0,
          ),
        );

        final quantity = (json['quantity'] as int?) ?? 1;
        if (quantity > 0) {
          cartItems.add(CartItem(
            meal: meal,
            qty: quantity,
          ));
        }
      }

      return cartItems;
    } catch (e) {
      print('Error loading cart: $e');
      return [];
    }
  }

  /// Add item to cart (or update quantity if exists)
  Future<void> addToCart(String userId, String mealId, int quantity) async {
    try {
      // Use upsert to handle both insert and update
      await _supabase.from('cart_items').upsert(
        {
          'user_id': userId,
          'meal_id': mealId,
          'quantity': quantity,
        },
        onConflict: 'user_id,meal_id', // Update if exists
      );
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  /// Update cart item quantity
  Future<void> updateQuantity(String userId, String mealId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(userId, mealId);
        return;
      }

      await _supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('user_id', userId)
          .eq('meal_id', mealId);
    } catch (e) {
      print('Error updating cart quantity: $e');
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String userId, String mealId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .eq('meal_id', mealId);
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart(String userId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  /// Get cart item count
  Future<int> getCartCount(String userId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('quantity')
          .eq('user_id', userId);

      int total = 0;
      for (final item in response as List) {
        total += (item['quantity'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }
}
