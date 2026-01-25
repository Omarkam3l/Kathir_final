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
  });

  int get minutesLeft {
    final m = expiry.difference(DateTime.now()).inMinutes;
    return m < 0 ? 0 : m;
  }
}

