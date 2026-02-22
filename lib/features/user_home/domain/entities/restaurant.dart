class Restaurant {
  final String id;
  final String name;
  final double rating;
  final String? logoUrl;
  final bool verified;
  final int reviewsCount;
  final double? latitude;
  final double? longitude;
  final String? addressText;

  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    this.logoUrl,
    this.verified = false,
    this.reviewsCount = 0,
    this.latitude,
    this.longitude,
    this.addressText,
  });
}

