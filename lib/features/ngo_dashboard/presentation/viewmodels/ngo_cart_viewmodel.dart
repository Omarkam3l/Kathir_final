import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/domain/entities/meal.dart';
import '../../../user_home/data/models/meal_model.dart';

/// NGO Cart ViewModel - Database-backed cart using cart_items table
/// 
/// Refactored to use Supabase cart_items table instead of in-memory storage.
/// Works for all authenticated users (users, NGOs, restaurants).
class NgoCartViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // State
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _cartItems.isEmpty;
  
  int get cartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  
  // Calculations
  double get subtotal {
    return _cartItems.fold(0.0, (sum, item) => 
      sum + (item.meal.donationPrice * item.quantity));
  }
  
  double get deliveryFee => 0.0; // Free for NGOs
  double get serviceFee => 0.0; // Free for NGOs
  double get total => subtotal + deliveryFee + serviceFee;
  
  double get co2Savings {
    return _cartItems.fold(0.0, (sum, item) => 
      sum + (2.5 * item.quantity)); // 2.5kg CO2 per meal
  }

  /// Load cart items from database
  Future<void> loadCart() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ No authenticated user');
      _cartItems = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Loading cart for user: $userId');
      
      // Fetch cart items with meal details
      final response = await _supabase
          .from('cart_items')
          .select('''
            id,
            profile_id,
            meal_id,
            quantity,
            created_at,
            updated_at,
            meals!inner(
              id,
              title,
              description,
              category,
              image_url,
              original_price,
              discounted_price,
              quantity_available,
              expiry_date,
              location,
              unit,
              fulfillment_method,
              is_donation_available,
              status,
              pickup_deadline,
              pickup_time,
              ingredients,
              allergens,
              co2_savings,
              restaurant_id,
              restaurants!inner(
                profile_id,
                restaurant_name,
                rating
              )
            )
          ''')
          .eq('profile_id', userId)
          .order('created_at', ascending: false);

      _cartItems = (response as List).map((json) {
        try {
          final mealData = json['meals'];
          final restaurantData = mealData['restaurants'];
          
          // Transform to match Meal model structure
          mealData['restaurant'] = {
            'id': restaurantData['profile_id']?.toString() ?? '',
            'name': restaurantData['restaurant_name'] ?? 'Unknown Restaurant',
            'rating': (restaurantData['rating'] as num?)?.toDouble() ?? 0.0,
            'logo_url': '',
            'verified': true,
            'reviews_count': 0,
          };
          
          // Map fields
          mealData['donation_price'] = mealData['discounted_price'] ?? 0.0;
          mealData['quantity'] = mealData['quantity_available'] ?? 0;
          mealData['expiry'] = mealData['expiry_date'];
          
          final meal = MealModel.fromJson(mealData);
          
          return CartItem(
            id: json['id'],
            meal: meal,
            quantity: json['quantity'] ?? 1,
          );
        } catch (e) {
          debugPrint('❌ Error parsing cart item: $e');
          return null;
        }
      }).whereType<CartItem>().toList();

      debugPrint('✅ Loaded ${_cartItems.length} cart items');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading cart: $e');
      _cartItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add meal to cart (upsert)
  Future<void> addToCart(Meal meal, {int quantity = 1}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ No authenticated user');
      return;
    }

    try {
      debugPrint('🔄 Adding to cart: ${meal.title} (qty: $quantity)');
      
      // Check if item already exists
      final existing = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('profile_id', userId)
          .eq('meal_id', meal.id)
          .maybeSingle();

      if (existing != null) {
        // Update existing item
        final newQty = (existing['quantity'] as int) + quantity;
        
        // Check max quantity
        if (newQty > meal.quantity) {
          debugPrint('⚠️ Cannot add more - max quantity reached');
          return;
        }
        
        await _supabase
            .from('cart_items')
            .update({'quantity': newQty, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
        
        debugPrint('✅ Updated cart item quantity to $newQty');
      } else {
        // Insert new item
        await _supabase.from('cart_items').insert({
          'profile_id': userId,
          'meal_id': meal.id,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ Added new cart item');
      }

      // Reload cart
      await loadCart();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding to cart: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String mealId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('🗑️ Removing from cart: $mealId');
      
      await _supabase
          .from('cart_items')
          .delete()
          .eq('profile_id', userId)
          .eq('meal_id', mealId);

      debugPrint('✅ Removed from cart');
      
      // Reload cart
      await loadCart();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error removing from cart: $e');
      notifyListeners();
    }
  }

  /// Update quantity
  Future<void> updateQuantity(String mealId, int newQuantity) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (newQuantity <= 0) {
        await removeFromCart(mealId);
        return;
      }

      debugPrint('🔄 Updating quantity for $mealId to $newQuantity');
      
      await _supabase
          .from('cart_items')
          .update({
            'quantity': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('profile_id', userId)
          .eq('meal_id', mealId);

      debugPrint('✅ Updated quantity');
      
      // Reload cart
      await loadCart();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating quantity: $e');
      notifyListeners();
    }
  }

  /// Increment quantity
  Future<void> increment(String mealId) async {
    final item = _cartItems.firstWhere((item) => item.meal.id == mealId);
    final currentQty = item.quantity;
    final maxQty = item.meal.quantity;
    
    if (currentQty < maxQty) {
      await updateQuantity(mealId, currentQty + 1);
    } else {
      debugPrint('⚠️ Cannot increment - max quantity reached');
    }
  }

  /// Decrement quantity
  Future<void> decrement(String mealId) async {
    final item = _cartItems.firstWhere((item) => item.meal.id == mealId);
    await updateQuantity(mealId, item.quantity - 1);
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('🗑️ Clearing cart');
      
      await _supabase
          .from('cart_items')
          .delete()
          .eq('profile_id', userId);

      debugPrint('✅ Cart cleared');
      
      _cartItems = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error clearing cart: $e');
      notifyListeners();
    }
  }

  /// Get cart item by meal ID
  CartItem? getCartItem(String mealId) {
    try {
      return _cartItems.firstWhere((item) => item.meal.id == mealId);
    } catch (e) {
      return null;
    }
  }

  /// Check if meal is in cart
  bool isInCart(String mealId) {
    return _cartItems.any((item) => item.meal.id == mealId);
  }
}

/// Cart Item Model - now includes database ID
class CartItem {
  final String? id; // Database ID
  final Meal meal;
  final int quantity;

  CartItem({
    this.id,
    required this.meal,
    required this.quantity,
  });
}
