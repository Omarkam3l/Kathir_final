class LoyaltyProfile {
  final String userId;
  final int totalPoints;
  final int availablePoints;
  final int lifetimePoints;
  final String currentTier;
  final int totalOrders;
  final int totalDonations;
  final int mealsRescued;
  final double co2Saved;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyProfile({
    required this.userId,
    required this.totalPoints,
    required this.availablePoints,
    required this.lifetimePoints,
    required this.currentTier,
    required this.totalOrders,
    required this.totalDonations,
    required this.mealsRescued,
    required this.co2Saved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoyaltyProfile.fromJson(Map<String, dynamic> json) {
    return LoyaltyProfile(
      userId: json['user_id'],
      totalPoints: json['total_points'] ?? 0,
      availablePoints: json['available_points'] ?? 0,
      lifetimePoints: json['lifetime_points'] ?? 0,
      currentTier: json['current_tier'] ?? 'bronze',
      totalOrders: json['total_orders'] ?? 0,
      totalDonations: json['total_donations'] ?? 0,
      mealsRescued: json['meals_rescued'] ?? 0,
      co2Saved: (json['co2_saved'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get tierName {
    switch (currentTier) {
      case 'platinum':
        return 'Platinum';
      case 'gold':
        return 'Gold';
      case 'silver':
        return 'Silver';
      default:
        return 'Bronze';
    }
  }

  String get tierIcon {
    switch (currentTier) {
      case 'platinum':
        return '💎';
      case 'gold':
        return '👑';
      case 'silver':
        return '⭐';
      default:
        return '🥉';
    }
  }

  int get pointsToNextTier {
    switch (currentTier) {
      case 'bronze':
        return 200 - lifetimePoints;
      case 'silver':
        return 500 - lifetimePoints;
      case 'gold':
        return 1000 - lifetimePoints;
      default:
        return 0; // Already at max tier
    }
  }

  String get nextTierName {
    switch (currentTier) {
      case 'bronze':
        return 'Silver';
      case 'silver':
        return 'Gold';
      case 'gold':
        return 'Platinum';
      default:
        return 'Max Tier';
    }
  }
}
