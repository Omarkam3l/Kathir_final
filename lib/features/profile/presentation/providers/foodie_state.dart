import 'package:flutter/foundation.dart';
import '../../../user_home/domain/entities/meal_offer.dart';

class CartItem {
  final MealOffer meal;
  int qty;
  CartItem({required this.meal, this.qty = 1});

  double get lineTotal => meal.donationPrice * qty;
}

enum DeliveryMethod { pickup, delivery, donate }

class FoodieState extends ChangeNotifier {
  final List<MealOffer> _favourites = [];
  final List<CartItem> _cart = [];
  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup; // Defaults to Pickup (Free)
  String? _promoCode;

  // ... (existing favourites logic)

  DeliveryMethod get deliveryMethod => _deliveryMethod;
  String? get promoCode => _promoCode;

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
  
  double get subtotal => _cart.fold<double>(0.0, (sum, item) => sum + item.lineTotal);
  
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
    if (_deliveryMethod == DeliveryMethod.donate) return 0.0; // Fee Waived for donation
    return 1.5; // Standard fee
  }
  
  double get total => subtotal + deliveryFee + platformFee;

  void addToCart(MealOffer meal, {int qty = 1}) {
    final idx = _cart.indexWhere((c) => c.meal.id == meal.id);
    if (idx >= 0) {
      _cart[idx].qty += qty;
    } else {
      _cart.add(CartItem(meal: meal, qty: qty));
    }
    notifyListeners();
  }

  void increment(String id) {
    final idx = _cart.indexWhere((c) => c.meal.id == id);
    if (idx >= 0) {
      _cart[idx].qty += 1;
      notifyListeners();
    }
  }

  void decrement(String id) {
    final idx = _cart.indexWhere((c) => c.meal.id == id);
    if (idx >= 0) {
      final item = _cart[idx];
      item.qty -= 1;
      if (item.qty <= 0) {
        _cart.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String id) {
    _cart.removeWhere((c) => c.meal.id == id);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
