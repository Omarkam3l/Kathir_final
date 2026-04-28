import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../cart/data/services/cart_service.dart';
import '../../../user_home/domain/usecases/check_rush_hour_status.dart';

class CartItem {
  final MealOffer meal;
  int qty;
  
  CartItem({required this.meal, this.qty = 1});

  /// Calculate line total with given effective price
  double calculateLineTotal(double effectivePrice) {
    try {
      if (effectivePrice.isNaN || effectivePrice.isInfinite || effectivePrice < 0) {
        debugPrint('Warning: Invalid price for meal ${meal.id}: $effectivePrice');
        return 0.0;
      }
      final total = effectivePrice * qty;
      return total.isNaN || total.isInfinite ? 0.0 : total;
    } catch (e) {
      debugPrint('Error calculating line total: $e');
      return 0.0;
    }
  }
}

enum DeliveryMethod { pickup, delivery, donate }

class FoodieState extends ChangeNotifier {
  final CartService _cartService = CartService();
  final _supabase = Supabase.instance.client;
  
  final List<MealOffer> _favourites = [];
  final List<CartItem> _cart = [];
  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup;
  String? _promoCode;
  double _promoCodeDiscount = 0.0; // Percentage discount (0-100)
  bool _isLoadingCart = false;
  
  // Centralized Rush Hour cache - refreshed once for all items
  final Map<String, RushHourInfo> _rushHourCache = {};

  // ... (existing favourites logic)

  DeliveryMethod get deliveryMethod => _deliveryMethod;
  String? get promoCode => _promoCode;
  double get promoCodeDiscount => _promoCodeDiscount;
  bool get isLoadingCart => _isLoadingCart;

  void setDeliveryMethod(DeliveryMethod method) {
    _deliveryMethod = method;
    notifyListeners();
  }

  void setPromoCode(String code, double discountPercentage) {
    _promoCode = code;
    _promoCodeDiscount = discountPercentage.clamp(0.0, 100.0); // Ensure 0-100%
    notifyListeners();
  }

  void clearPromoCode() {
    _promoCode = null;
    _promoCodeDiscount = 0.0;
    notifyListeners();
  }

  // ... (existing favourites getters)
  List<MealOffer> get favourites => List.unmodifiable(_favourites);
  int get favouritesCount => _favourites.length;
  bool isFavourite(String id) => _favourites.any((m) => m.id == id);
  void addFavourite(MealOffer meal) {
    if (!_favourites.any((m) => m.id == meal.id)) {
      _favourites.add(meal);
      notifyListeners();
    }
  }

  void removeFavourite(String id) {
    _favourites.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void toggleFavourite(MealOffer meal) {
    if (isFavourite(meal.id)) {
      removeFavourite(meal.id);
    } else {
      addFavourite(meal);
    }
  }

  List<CartItem> get cartItems => List.unmodifiable(_cart);
  int get cartCount => _cart.fold<int>(0, (sum, item) => sum + item.qty);
  
  /// Get effective price for a meal (with Rush Hour discount if active)
  double getEffectivePrice(MealOffer meal) {
    final rushHourInfo = _rushHourCache[meal.restaurant.id];
    if (rushHourInfo != null) {
      return RushHourChecker.calculateEffectivePrice(
        meal.originalPrice,
        rushHourInfo.discountPercentage,
      );
    }
    return meal.donationPrice;
  }
  
  /// Check if a meal has active Rush Hour
  bool hasActiveRushHour(String restaurantId) {
    return _rushHourCache.containsKey(restaurantId);
  }
  
  /// Get Rush Hour info for a restaurant
  RushHourInfo? getRushHourInfo(String restaurantId) {
    return _rushHourCache[restaurantId];
  }
  
  /// Refresh Rush Hour cache for all restaurants in cart
  Future<void> _refreshRushHourCache() async {
    try {
      // Get unique restaurant IDs from cart
      final restaurantIds = _cart.map((item) => item.meal.restaurant.id).toSet();
      
      if (restaurantIds.isEmpty) {
        _rushHourCache.clear();
        return;
      }
      
      // Query all active Rush Hours for these restaurants in one call
      final now = DateTime.now();
      final response = await _supabase
          .from('rush_hours')
          .select('restaurant_id, discount_percentage, start_time, end_time')
          .inFilter('restaurant_id', restaurantIds.toList())
          .eq('is_active', true);
      
      // Clear old cache
      _rushHourCache.clear();
      
      // Build new cache
      for (final row in response) {
        final startTime = DateTime.parse(row['start_time'] as String);
        final endTime = DateTime.parse(row['end_time'] as String);
        
        // Only cache if currently active
        if (now.isAfter(startTime) && now.isBefore(endTime)) {
          _rushHourCache[row['restaurant_id'] as String] = RushHourInfo(
            isActive: true,
            discountPercentage: row['discount_percentage'] as int,
            endTime: endTime,
          );
        }
      }
      
      debugPrint('🔄 Rush Hour cache refreshed: ${_rushHourCache.length} active');
    } catch (e) {
      debugPrint('Error refreshing Rush Hour cache: $e');
    }
  }
  
  double get subtotal {
    try {
      final total = _cart.fold<double>(0.0, (sum, item) {
        final effectivePrice = getEffectivePrice(item.meal);
        final lineTotal = item.calculateLineTotal(effectivePrice);
        if (lineTotal.isNaN || lineTotal.isInfinite) {
          debugPrint('Warning: Invalid line total for meal ${item.meal.id}');
          return sum;
        }
        return sum + lineTotal;
      });
      return total.isNaN || total.isInfinite ? 0.0 : total;
    } catch (e) {
      debugPrint('Error calculating subtotal: $e');
      return 0.0;
    }
  }
  
  double get deliveryFee {
    if (_cart.isEmpty) return 0.0;
    switch (_deliveryMethod) {
      case DeliveryMethod.delivery:
        return 2.99;
      default:
        return 0.0;
    }
  }

  double get platformFee {
    if (_cart.isEmpty) return 0.0;
    if (_deliveryMethod == DeliveryMethod.donate) return 0.0;
    return 1.5;
  }

  // Calculate discount amount based on percentage
  double get discountAmount {
    if (_promoCodeDiscount <= 0) return 0.0;
    final totalBeforeDiscount = subtotal + deliveryFee + platformFee;
    return (totalBeforeDiscount * _promoCodeDiscount / 100.0);
  }
  
  double get total {
    try {
      final totalBeforeDiscount = subtotal + deliveryFee + platformFee;
      final discount = discountAmount;
      final finalTotal = totalBeforeDiscount - discount;
      return finalTotal.isNaN || finalTotal.isInfinite || finalTotal < 0 ? 0.0 : finalTotal;
    } catch (e) {
      debugPrint('Error calculating total: $e');
      return 0.0;
    }
  }

  /// Load cart from database
  Future<void> loadCart() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoadingCart = true;
    notifyListeners();

    try {
      final items = await _cartService.loadCart(userId);
      _cart.clear();
      _cart.addAll(items);
      
      // Refresh Rush Hour cache once for all items
      await _refreshRushHourCache();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      _isLoadingCart = false;
      notifyListeners();
    }
  }
  
  /// Refresh Rush Hour status and prices
  Future<void> refreshPrices() async {
    await _refreshRushHourCache();
    notifyListeners();
  }

  /// Add to cart (database + memory)
  Future<void> addToCart(MealOffer meal, {int qty = 1}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final idx = _cart.indexWhere((c) => c.meal.id == meal.id);
      if (idx >= 0) {
        final newQty = _cart[idx].qty + qty;
        if (newQty <= meal.quantity) {
          _cart[idx].qty = newQty;
          await _cartService.updateQuantity(userId, meal.id, newQty);
        } else {
          _cart[idx].qty = meal.quantity;
          await _cartService.updateQuantity(userId, meal.id, meal.quantity);
        }
      } else {
        final safeQty = qty > meal.quantity ? meal.quantity : qty;
        _cart.add(CartItem(meal: meal, qty: safeQty));
        await _cartService.addToCart(userId, meal.id, safeQty);
      }
      
      // Refresh Rush Hour cache after adding
      await _refreshRushHourCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  /// Increment quantity (database + memory)
  Future<void> increment(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final idx = _cart.indexWhere((c) => c.meal.id == id);
      if (idx >= 0) {
        final item = _cart[idx];
        if (item.qty < item.meal.quantity) {
          item.qty += 1;
          await _cartService.updateQuantity(userId, id, item.qty);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error incrementing cart: $e');
    }
  }

  /// Decrement quantity (database + memory)
  Future<void> decrement(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final idx = _cart.indexWhere((c) => c.meal.id == id);
      if (idx >= 0) {
        final item = _cart[idx];
        item.qty -= 1;
        if (item.qty <= 0) {
          _cart.removeAt(idx);
          await _cartService.removeFromCart(userId, id);
        } else {
          await _cartService.updateQuantity(userId, id, item.qty);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error decrementing cart: $e');
    }
  }

  /// Remove from cart (database + memory)
  Future<void> removeFromCart(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _cart.removeWhere((c) => c.meal.id == id);
      await _cartService.removeFromCart(userId, id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  /// Clear cart (database + memory)
  Future<void> clearCart() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _cart.clear();
      await _cartService.clearCart(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  /// Check if we can add more of this item to cart
  bool canAddMore(String mealId) {
    final idx = _cart.indexWhere((c) => c.meal.id == mealId);
    if (idx >= 0) {
      final item = _cart[idx];
      return item.qty < item.meal.quantity;
    }
    return true;
  }

  /// Get remaining quantity available for a meal
  int getRemainingQuantity(String mealId) {
    final idx = _cart.indexWhere((c) => c.meal.id == mealId);
    if (idx >= 0) {
      final item = _cart[idx];
      return item.meal.quantity - item.qty;
    }
    return 999;
  }
}
