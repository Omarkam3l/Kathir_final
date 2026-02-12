import 'package:flutter/material.dart';
import '../../../user_home/domain/entities/meal.dart';

class NgoCartViewModel extends ChangeNotifier {
  // Cart items
  final List<CartItem> _cartItems = [];
  
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  
  int get cartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isEmpty => _cartItems.isEmpty;
  
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

  // Add to cart
  void addToCart(Meal meal, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item.meal.id == meal.id);
    
    if (existingIndex >= 0) {
      // Update quantity if already in cart
      final currentQty = _cartItems[existingIndex].quantity;
      final newQty = currentQty + quantity;
      
      // Check if we can add more
      if (newQty <= meal.quantity) {
        _cartItems[existingIndex] = CartItem(
          meal: meal,
          quantity: newQty,
        );
      }
    } else {
      // Add new item
      _cartItems.add(CartItem(meal: meal, quantity: quantity));
    }
    
    notifyListeners();
    debugPrint('✅ Added to cart: ${meal.title} (qty: $quantity)');
  }

  // Remove from cart
  void removeFromCart(String mealId) {
    _cartItems.removeWhere((item) => item.meal.id == mealId);
    notifyListeners();
    debugPrint('🗑️ Removed from cart: $mealId');
  }

  // Update quantity
  void updateQuantity(String mealId, int newQuantity) {
    final index = _cartItems.indexWhere((item) => item.meal.id == mealId);
    
    if (index >= 0) {
      if (newQuantity <= 0) {
        removeFromCart(mealId);
      } else if (newQuantity <= _cartItems[index].meal.quantity) {
        _cartItems[index] = CartItem(
          meal: _cartItems[index].meal,
          quantity: newQuantity,
        );
        notifyListeners();
      }
    }
  }

  // Increment quantity
  void increment(String mealId) {
    final index = _cartItems.indexWhere((item) => item.meal.id == mealId);
    if (index >= 0) {
      final currentQty = _cartItems[index].quantity;
      final maxQty = _cartItems[index].meal.quantity;
      
      if (currentQty < maxQty) {
        updateQuantity(mealId, currentQty + 1);
      }
    }
  }

  // Decrement quantity
  void decrement(String mealId) {
    final index = _cartItems.indexWhere((item) => item.meal.id == mealId);
    if (index >= 0) {
      final currentQty = _cartItems[index].quantity;
      updateQuantity(mealId, currentQty - 1);
    }
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    debugPrint('🗑️ Cart cleared');
  }

  // Get cart item by meal ID
  CartItem? getCartItem(String mealId) {
    try {
      return _cartItems.firstWhere((item) => item.meal.id == mealId);
    } catch (e) {
      return null;
    }
  }

  // Check if meal is in cart
  bool isInCart(String mealId) {
    return _cartItems.any((item) => item.meal.id == mealId);
  }
}

// Cart Item Model
class CartItem {
  final Meal meal;
  final int quantity;

  CartItem({
    required this.meal,
    required this.quantity,
  });
}
