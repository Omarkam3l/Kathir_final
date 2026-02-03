/// Meal entity with computed effective discount based on rush hour status
class MealWithEffectiveDiscount {
  final String id;
  final String restaurantId;
  final String title;
  final String? description;
  final String? category;
  final String? imageUrl;
  final double originalPrice;
  final double discountedPrice;
  final double effectivePrice;
  final int quantityAvailable;
  final DateTime expiryDate;
  final String? status;
  final String? location;
  final int effectiveDiscountPercentage;
  final bool rushHourActiveNow;
  final String? restaurantName;
  final double? restaurantRating;

  const MealWithEffectiveDiscount({
    required this.id,
    required this.restaurantId,
    required this.title,
    this.description,
    this.category,
    this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
    required this.effectivePrice,
    required this.quantityAvailable,
    required this.expiryDate,
    this.status,
    this.location,
    required this.effectiveDiscountPercentage,
    required this.rushHourActiveNow,
    this.restaurantName,
    this.restaurantRating,
  });

  factory MealWithEffectiveDiscount.fromJson(Map<String, dynamic> json) {
    return MealWithEffectiveDiscount(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      originalPrice: (json['original_price'] as num).toDouble(),
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      effectivePrice: (json['effective_price'] as num).toDouble(),
      quantityAvailable: (json['quantity_available'] as num).toInt(),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      status: json['status'] as String?,
      location: json['location'] as String?,
      effectiveDiscountPercentage:
          (json['effective_discount_percentage'] as num?)?.toInt() ?? 0,
      rushHourActiveNow: json['rush_hour_active_now'] as bool? ?? false,
      restaurantName: json['restaurant_name'] as String?,
      restaurantRating: (json['restaurant_rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'title': title,
      'description': description,
      'category': category,
      'image_url': imageUrl,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'effective_price': effectivePrice,
      'quantity_available': quantityAvailable,
      'expiry_date': expiryDate.toIso8601String(),
      'status': status,
      'location': location,
      'effective_discount_percentage': effectiveDiscountPercentage,
      'rush_hour_active_now': rushHourActiveNow,
      'restaurant_name': restaurantName,
      'restaurant_rating': restaurantRating,
    };
  }

  /// Returns the savings amount compared to original price
  double get savingsAmount => originalPrice - effectivePrice;

  /// Returns the savings percentage
  double get savingsPercentage =>
      ((originalPrice - effectivePrice) / originalPrice * 100);

  @override
  String toString() {
    return 'MealWithEffectiveDiscount(id: $id, title: $title, effectivePrice: $effectivePrice, rushHourActive: $rushHourActiveNow)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealWithEffectiveDiscount &&
        other.id == id &&
        other.effectivePrice == effectivePrice &&
        other.rushHourActiveNow == rushHourActiveNow;
  }

  @override
  int get hashCode {
    return Object.hash(id, effectivePrice, rushHourActiveNow);
  }
}
