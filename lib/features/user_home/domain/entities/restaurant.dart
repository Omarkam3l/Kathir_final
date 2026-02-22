class Restaurant {
  final String id;
  final String name;
  final double rating;
  final String? logoUrl;
  final bool verified;
  final int reviewsCount;

  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    this.logoUrl,
    this.verified = false,
    this.reviewsCount = 0,
  });
}

