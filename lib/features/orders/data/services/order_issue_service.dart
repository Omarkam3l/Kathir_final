import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class OrderIssueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Report an issue with an order
  Future<String> reportIssue({
    required String orderId,
    required String issueType,
    required String description,
    XFile? photo,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get order details to get restaurant_id (which is the restaurant's profile_id)
      final orderResponse = await _supabase
          .from('orders')
          .select('restaurant_id')
          .eq('id', orderId)
          .single();

      final restaurantId = orderResponse['restaurant_id'] as String;

      // Upload photo if provided
      String? photoUrl;
      if (photo != null) {
        photoUrl = await _uploadIssuePhoto(userId, orderId, photo);
      }

      // Create issue report
      // Note: restaurant_id in order_issues references restaurants(profile_id)
      final issueResponse = await _supabase
          .from('order_issues')
          .insert({
            'order_id': orderId,
            'user_id': userId,
            'restaurant_id': restaurantId,
            'issue_type': issueType,
            'description': description,
            'photo_url': photoUrl,
          })
          .select()
          .single();

      return issueResponse['id'] as String;
    } catch (e) {
      debugPrint('Error reporting issue: $e');
      rethrow;
    }
  }

  /// Upload issue photo to storage
  Future<String> _uploadIssuePhoto(
    String userId,
    String orderId,
    XFile photo,
  ) async {
    try {
      final bytes = await photo.readAsBytes();
      
      // Get file extension from name or mime type
      String fileExt = 'jpg'; // default
      if (photo.name.contains('.')) {
        fileExt = photo.name.split('.').last.toLowerCase();
      } else if (photo.mimeType != null) {
        // Extract extension from mime type (e.g., "image/jpeg" -> "jpeg")
        final mimeType = photo.mimeType!;
        if (mimeType.contains('/')) {
          fileExt = mimeType.split('/').last;
          // Normalize common types
          if (fileExt == 'jpeg') fileExt = 'jpg';
        }
      }
      
      // Ensure valid image extension
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
        fileExt = 'jpg';
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$orderId/$fileName';

      // Determine content type
      String contentType = 'image/jpeg'; // default
      switch (fileExt) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      await _supabase.storage.from('order-issues').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage
          .from('order-issues')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading issue photo: $e');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Take photo with camera
  Future<XFile?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Get user's reported issues
  Future<List<Map<String, dynamic>>> getUserIssues() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('order_issues')
          .select('''
            *,
            orders!order_id(order_number, total_amount),
            restaurants!restaurant_id(restaurant_name)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting user issues: $e');
      return [];
    }
  }

  /// Get issue details
  Future<Map<String, dynamic>?> getIssueDetails(String issueId) async {
    try {
      final response = await _supabase
          .from('order_issues')
          .select('''
            *,
            orders!order_id(order_number, total_amount, created_at),
            restaurants!restaurant_id(restaurant_name, phone)
          ''')
          .eq('id', issueId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error getting issue details: $e');
      return null;
    }
  }

  /// Check if order already has a reported issue
  Future<bool> hasReportedIssue(String orderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('order_issues')
          .select('id')
          .eq('order_id', orderId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking for existing issue: $e');
      return false;
    }
  }
}
