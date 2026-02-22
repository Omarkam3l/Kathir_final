import '../../domain/entities/restaurant.dart';

class RestaurantModel extends Restaurant {
  const RestaurantModel({
    required super.id,
    required super.name,
    required super.rating,
    super.logoUrl,
    super.verified,
    super.reviewsCount,
    super.latitude,
    super.longitude,
    super.addressText,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      logoUrl: json['logo_url'],
      verified: json['verified'] ?? false,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressText: json['address_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'logo_url': logoUrl,
        'verified': verified,
        'reviews_count': reviewsCount,
        'latitude': latitude,
        'longitude': longitude,
        'address_text': addressText,
      };
}
