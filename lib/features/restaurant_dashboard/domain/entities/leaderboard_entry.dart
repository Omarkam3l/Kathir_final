/// Leaderboard entry entity representing a restaurant's ranking
class LeaderboardEntry {
  final String restaurantId;
  final String name;
  final int score;
  final int rank;
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.restaurantId,
    required this.name,
    required this.score,
    required this.rank,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      restaurantId: json['restaurant_profile_id'] as String,
      name: json['restaurant_name'] as String? ?? 'Unknown Restaurant',
      score: (json['score'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_profile_id': restaurantId,
      'restaurant_name': name,
      'score': score,
      'rank': rank,
      'avatar_url': avatarUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.restaurantId == restaurantId &&
        other.name == name &&
        other.score == score &&
        other.rank == rank &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return Object.hash(restaurantId, name, score, rank, avatarUrl);
  }

  @override
  String toString() {
    return 'LeaderboardEntry(restaurantId: $restaurantId, name: $name, score: $score, rank: $rank, avatarUrl: $avatarUrl)';
  }
}

/// User's restaurant rank information
class MyRestaurantRank {
  final int rank;
  final int score;
  final String restaurantName;

  const MyRestaurantRank({
    required this.rank,
    required this.score,
    required this.restaurantName,
  });

  factory MyRestaurantRank.fromJson(Map<String, dynamic> json) {
    return MyRestaurantRank(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      restaurantName: json['restaurant_name'] as String? ?? 'My Restaurant',
    );
  }

  @override
  String toString() {
    return 'MyRestaurantRank(rank: $rank, score: $score, restaurantName: $restaurantName)';
  }
}
