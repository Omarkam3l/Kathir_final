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
  });

  int get minutesLeft {
    final m = expiry.difference(DateTime.now()).inMinutes;
    return m < 0 ? 0 : m;
  }
}

