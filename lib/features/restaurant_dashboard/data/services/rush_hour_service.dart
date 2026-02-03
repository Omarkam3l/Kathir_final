import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/rush_hour_config.dart';

/// Service for managing Rush Hour settings
/// 
/// This service provides safe, efficient access to rush hour configuration
/// using Supabase RPC functions that handle all business logic server-side.
/// 
/// Key features:
/// - Uses RPC functions for safe concurrent updates
/// - Handles validation errors gracefully
/// - No direct table access (uses SECURITY DEFINER RPCs)
/// - Proper error handling with typed exceptions
class RushHourService {
  final SupabaseClient _supabase;

  RushHourService(this._supabase);

  /// Fetches the current rush hour configuration for the authenticated restaurant
  /// 
  /// Returns: RushHourConfig with current settings
  /// 
  /// Throws: Exception if RPC call fails or user is not authenticated
  Future<RushHourConfig> getMyRushHour() async {
    try {
      final response = await _supabase.rpc('get_my_rush_hour') as Map<String, dynamic>;
      return RushHourConfig.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch rush hour settings: $e');
    }
  }

  /// Updates rush hour settings for the authenticated restaurant
  /// 
  /// Parameters:
  ///   - isActive: Whether rush hour is enabled
  ///   - startTime: Start datetime (required if isActive=true)
  ///   - endTime: End datetime (required if isActive=true)
  ///   - discountPercentage: Discount % (0-100)
  /// 
  /// Returns: Updated RushHourConfig
  /// 
  /// Throws: Exception if validation fails or RPC call fails
  Future<RushHourConfig> setRushHourSettings({
    required bool isActive,
    required DateTime? startTime,
    required DateTime? endTime,
    required int discountPercentage,
  }) async {
    // Client-side validation
    if (isActive) {
      if (startTime == null || endTime == null) {
        throw Exception('Start time and end time are required when activating rush hour');
      }
      
      if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
        throw Exception('End time must be after start time');
      }
    }

    if (discountPercentage < 0 || discountPercentage > 100) {
      throw Exception('Discount percentage must be between 0 and 100');
    }

    try {
      final response = await _supabase.rpc(
        'set_rush_hour_settings',
        params: {
          'p_is_active': isActive,
          'p_start_time': startTime?.toIso8601String(),
          'p_end_time': endTime?.toIso8601String(),
          'p_discount_percentage': discountPercentage,
        },
      ) as Map<String, dynamic>;

      return RushHourConfig.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle specific Postgres errors
      if (e.message.contains('End time must be after start time')) {
        throw Exception('End time must be after start time');
      } else if (e.message.contains('Discount percentage')) {
        throw Exception('Discount percentage must be between 0 and 100');
      } else if (e.message.contains('Not authenticated')) {
        throw Exception('You must be logged in to update rush hour settings');
      } else if (e.message.contains('not a restaurant')) {
        throw Exception('Only restaurants can set rush hour settings');
      } else {
        throw Exception('Failed to update rush hour settings: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to update rush hour settings: $e');
    }
  }

  /// Activates rush hour with the given settings
  /// 
  /// Convenience method for enabling rush hour
  Future<RushHourConfig> activateRushHour({
    required DateTime startTime,
    required DateTime endTime,
    required int discountPercentage,
  }) async {
    return setRushHourSettings(
      isActive: true,
      startTime: startTime,
      endTime: endTime,
      discountPercentage: discountPercentage,
    );
  }

  /// Deactivates rush hour
  /// 
  /// Convenience method for disabling rush hour
  /// Note: This preserves the settings for future reactivation
  Future<RushHourConfig> deactivateRushHour() async {
    return setRushHourSettings(
      isActive: false,
      startTime: null,
      endTime: null,
      discountPercentage: 0, // Ignored when deactivating
    );
  }
}
