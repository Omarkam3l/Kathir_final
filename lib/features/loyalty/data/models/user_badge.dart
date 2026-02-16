class UserBadge {
  final String id;
  final String userId;
  final String badgeType;
  final String badgeName;
  final String badgeDescription;
  final String icon;
  final DateTime earnedAt;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.badgeName,
    required this.badgeDescription,
    required this.icon,
    required this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'],
      userId: json['user_id'],
      badgeType: json['badge_type'],
      badgeName: json['badge_name'],
      badgeDescription: json['badge_description'],
      icon: json['icon'],
      earnedAt: DateTime.parse(json['earned_at']),
    );
  }
}
