import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../cart/data/services/cart_service.dart';

class CartItem {
  final MealOffer meal;
  int qty;
  CartItem({required this.meal, this.qty = 1});

  double get lineTotal {
    try {
      final price = meal.donationPrice;
      if (price.isNaN || price.isInfinite || price < 0) {
        print('Warning: Invalid price for meal ${meal.id}: $price');
        return 0.0;
      }
      final total = price * qty;
      return total.isNaN || total.isInfinite ? 0.0 : total;
    } catch (e) {
      print('Error calculating line total: $e');
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
  bool _isLoadingCart = false;

  // ... (existing favourites logic)

  DeliveryMethod get deliveryMethod => _deliveryMethod;
  String? get promoCode => _promoCode;
  bool get isLoadingCart => _isLoadingCart;

  void setDeliveryMethod(DeliveryMethod method) {
    _deliveryMethod = method;
    notifyListeners();
  }

  void setPromoCode(String code) {
    _promoCode = code;
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
  
  double get subtotal {
    try {
      final total = _cart.fold<double>(0.0, (sum, item) {
        final lineTotal = item.lineTotal;
        if (lineTotal.isNaN || lineTotal.isInfinite) {
          print('Warning: Invalid line total for meal ${item.meal.id}');
          return sum;
        }
        return sum + lineTotal;
      });
      return total.isNaN || total.isInfinite ? 0.0 : total;
    } catch (e) {
      print('Error calculating subtotal: $e');
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
  
  double get total {
    try {
      final sum = subtotal + deliveryFee + platformFee;
      return sum.isNaN || sum.isInfinite ? 0.0 : sum;
    } catch (e) {
      print('Error calculating total: $e');
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
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      _isLoadingCart = false;
      notifyListeners();
    }
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
