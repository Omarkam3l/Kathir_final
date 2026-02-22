import 'restaurant.dart';

class Meal {
  final String id;
  final String title;
  final String location;
  final String imageUrl;
  final double originalPrice;
  final double donationPrice;
  final int quantity;
  final DateTime expiry;
  final String description;
  final List<String> ingredients;
  final List<String> allergens;
  final double co2Savings;
  final DateTime? pickupTime;
  final Restaurant restaurant;
  
  // New fields for donation support
  final String category;
  final String unit;
  final String fulfillmentMethod;
  final String status;
  final bool isDonationAvailable;
  final DateTime? pickupDeadline;

  const Meal({
    required this.id,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.originalPrice,
    required this.donationPrice,
    required this.quantity,
    required this.expiry,
    required this.restaurant,
    this.description = '',
    this.ingredients = const [],
    this.allergens = const [],
    this.co2Savings = 0.0,
    this.pickupTime,
    this.category = 'meals',
    this.unit = 'portions',
    this.fulfillmentMethod = 'pickup',
    this.status = 'active',
    this.isDonationAvailable = false,
    this.pickupDeadline,
  });

  int get minutesLeft {
    final m = expiry.difference(DateTime.now()).inMinutes;
    return m < 0 ? 0 : m;
  }
  
  /// Minutes left until pickup deadline
  int get pickupMinutesLeft {
    if (pickupDeadline == null) return minutesLeft;
    final m = pickupDeadline!.difference(DateTime.now()).inMinutes;
    return m < 0 ? 0 : m;
  }
}


