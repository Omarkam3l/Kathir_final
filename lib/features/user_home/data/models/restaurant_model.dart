import '../../domain/entities/restaurant.dart';

class RestaurantModel extends Restaurant {
  const RestaurantModel({
    required super.id,
    required super.name,
    required super.rating,
    super.logoUrl,
    super.verified,
    super.reviewsCount,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      logoUrl: json['logo_url'],
      verified: json['verified'] ?? false,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'logo_url': logoUrl,
        'verified': verified,
        'reviews_count': reviewsCount,
      };
}

