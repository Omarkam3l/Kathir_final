class Reward {
  final String id;
  final String rewardType;
  final String title;
  final String description;
  final int pointsCost;
  final int? discountPercentage;
  final double? discountAmount;
  final String? minTier;
  final bool isActive;
  final int validDays;
  final String icon;
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.rewardType,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.discountPercentage,
    this.discountAmount,
    this.minTier,
    required this.isActive,
    required this.validDays,
    required this.icon,
    required this.createdAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      rewardType: json['reward_type'],
      title: json['title'],
      description: json['description'],
      pointsCost: json['points_cost'],
      discountPercentage: json['discount_percentage'],
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      minTier: json['min_tier'],
      isActive: json['is_active'] ?? true,
      validDays: json['valid_days'] ?? 30,
      icon: json['icon'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool canRedeem(String userTier, int availablePoints) {
    // Check points
    if (availablePoints < pointsCost) return false;

    // Check tier requirement
    if (minTier == null) return true;

    final tierOrder = ['bronze', 'silver', 'gold', 'platinum'];
    final userTierIndex = tierOrder.indexOf(userTier);
    final minTierIndex = tierOrder.indexOf(minTier!);

    return userTierIndex >= minTierIndex;
  }
}

class UserReward {
  final String id;
  final String userId;
  final String rewardId;
  final String? transactionId;
  final String status;
  final DateTime redeemedAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? orderId;
  final Reward? reward;

  UserReward({
    required this.id,
    required this.userId,
    required this.rewardId,
    this.transactionId,
    required this.status,
    required this.redeemedAt,
    required this.expiresAt,
    this.usedAt,
    this.orderId,
    this.reward,
  });

  factory UserReward.fromJson(Map<String, dynamic> json) {
    return UserReward(
      id: json['id'],
      userId: json['user_id'],
      rewardId: json['reward_id'],
      transactionId: json['transaction_id'],
      status: json['status'],
      redeemedAt: DateTime.parse(json['redeemed_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at']) : null,
      orderId: json['order_id'],
      reward: json['rewards_catalog'] != null
          ? Reward.fromJson(json['rewards_catalog'])
          : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == 'active' && !isExpired;
}
