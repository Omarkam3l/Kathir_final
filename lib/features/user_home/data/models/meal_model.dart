import '../../domain/entities/meal.dart';
import 'restaurant_model.dart';

class MealModel extends Meal {
  const MealModel({
    required super.id,
    required super.title,
    required super.location,
    required super.imageUrl,
    required super.originalPrice,
    required super.donationPrice,
    required super.quantity,
    required super.expiry,
    required super.restaurant,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['image_url'] ?? '',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      donationPrice: (json['donation_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      expiry: DateTime.tryParse(json['expiry']?.toString() ?? '') ?? DateTime.now(),
      restaurant: RestaurantModel.fromJson(json['restaurant'] is Map<String, dynamic>
          ? json['restaurant'] as Map<String, dynamic>
          : {
              'id': json['restaurant_id'],
              'name': json['restaurant_name'],
              'rating': json['restaurant_rating'],
            }),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        'image_url': imageUrl,
        'original_price': originalPrice,
        'donation_price': donationPrice,
        'quantity': quantity,
        'expiry': expiry.toIso8601String(),
        'restaurant_id': restaurant.id,
      };
}
