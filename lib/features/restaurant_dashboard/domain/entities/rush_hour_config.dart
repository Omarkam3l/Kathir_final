/// Rush Hour configuration entity
class RushHourConfig {
  final String? id;
  final String restaurantId;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
  final int discountPercentage;
  final bool activeNow;

  const RushHourConfig({
    this.id,
    required this.restaurantId,
    required this.isActive,
    this.startTime,
    this.endTime,
    required this.discountPercentage,
    required this.activeNow,
  });

  factory RushHourConfig.fromJson(Map<String, dynamic> json) {
    return RushHourConfig(
      id: json['id'] as String?,
      restaurantId: json['restaurant_id'] as String,
      isActive: json['is_active'] as bool? ?? false,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      discountPercentage: (json['discount_percentage'] as num?)?.toInt() ?? 50,
      activeNow: json['active_now'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'is_active': isActive,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'discount_percentage': discountPercentage,
      'active_now': activeNow,
    };
  }

  RushHourConfig copyWith({
    String? id,
    String? restaurantId,
    bool? isActive,
    DateTime? startTime,
    DateTime? endTime,
    int? discountPercentage,
    bool? activeNow,
  }) {
    return RushHourConfig(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      activeNow: activeNow ?? this.activeNow,
    );
  }

  /// Returns a default inactive configuration
  factory RushHourConfig.defaultConfig(String restaurantId) {
    final now = DateTime.now();
    return RushHourConfig(
      restaurantId: restaurantId,
      isActive: false,
      startTime: DateTime(now.year, now.month, now.day, 21, 0), // 9 PM
      endTime: DateTime(now.year, now.month, now.day, 23, 0), // 11 PM
      discountPercentage: 50,
      activeNow: false,
    );
  }

  @override
  String toString() {
    return 'RushHourConfig(id: $id, isActive: $isActive, startTime: $startTime, endTime: $endTime, discount: $discountPercentage%, activeNow: $activeNow)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RushHourConfig &&
        other.id == id &&
        other.restaurantId == restaurantId &&
        other.isActive == isActive &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.discountPercentage == discountPercentage &&
        other.activeNow == activeNow;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      restaurantId,
      isActive,
      startTime,
      endTime,
      discountPercentage,
      activeNow,
    );
  }
}
