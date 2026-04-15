import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class to check if a meal is in an active Rush Hour
class RushHourChecker {
  static Future<RushHourInfo?> checkMealRushHour(String restaurantId) async {
    try {
      final now = DateTime.now();
      
      final response = await Supabase.instance.client
          .from('rush_hours')
          .select('discount_percentage, start_time, end_time')
          .eq('restaurant_id', restaurantId)
          .eq('is_active', true)
          .maybeSingle();
      
      if (response == null) return null;
      
      final startTime = DateTime.parse(response['start_time'] as String);
      final endTime = DateTime.parse(response['end_time'] as String);
      
      if (now.isAfter(startTime) && now.isBefore(endTime)) {
        return RushHourInfo(
          isActive: true,
          discountPercentage: response['discount_percentage'] as int,
          endTime: endTime,
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Calculate effective price with Rush Hour discount
  static double calculateEffectivePrice(
    double originalPrice,
    int discountPercentage,
  ) {
    return originalPrice * (1 - discountPercentage / 100);
  }
}

/// Rush Hour information
class RushHourInfo {
  final bool isActive;
  final int discountPercentage;
  final DateTime endTime;
  
  const RushHourInfo({
    required this.isActive,
    required this.discountPercentage,
    required this.endTime,
  });
  
  String get timeRemaining {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    if (difference.isNegative) return 'Expired';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m left';
    if (difference.inHours < 24) return '${difference.inHours}h left';
    return '${difference.inDays}d left';
  }
}
