import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NgoProfileViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // State
  bool isLoading = true;
  bool isUpdating = false;
  String? error;
  
  // Profile data
  String organizationName = 'Unnamed Organization';
  String location = 'Cairo, Egypt';
  String? profileImageUrl;
  int mealsClaimed = 0;
  double carbonSaved = 0;
  bool isVerified = true;
  double? latitude;
  double? longitude;
  String? addressText;

  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get NGO profile - use maybeSingle to handle missing records
      final profileRes = await _supabase
          .from('ngos')
          .select('*')
          .eq('profile_id', userId)
          .maybeSingle();

      // If NGO record doesn't exist, create it
      if (profileRes == null) {
        debugPrint('NGO record not found, creating one...');
        await _supabase.from('ngos').insert({
          'profile_id': userId,
          'organization_name': 'Unnamed Organization',
          'address_text': 'Cairo, Egypt',
          'legal_docs_urls': [],
        });
        
        // Reload after creation
        final newProfileRes = await _supabase
            .from('ngos')
            .select('*')
            .eq('profile_id', userId)
            .single();
        
        organizationName = newProfileRes['organization_name'] ?? 'Unnamed Organization';
        location = newProfileRes['address_text'] ?? 'Cairo, Egypt';
      } else {
        organizationName = profileRes['organization_name'] ?? 'Unnamed Organization';
        location = profileRes['address_text'] ?? 'Cairo, Egypt';
        latitude = profileRes['latitude'] as double?;
        longitude = profileRes['longitude'] as double?;
        addressText = profileRes['address_text'] as String?;
      }

      // Get profile image from profiles table (using avatar_url column)
      final userProfile = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      profileImageUrl = userProfile?['avatar_url'];

      // Get stats from orders - try to load but don't fail if there's an error
      try {
        final completedRes = await _supabase
            .from('orders')
            .select('id')
            .eq('ngo_id', userId)
            .inFilter('status', ['completed', 'delivered']); // Use correct enum values
        
        mealsClaimed = (completedRes as List).length;
        carbonSaved = mealsClaimed * 2.5; // Avg 2.5kg CO2 per meal
      } catch (statsError) {
        debugPrint('Error loading stats: $statsError');
        // Keep default values (0) if stats fail to load
        mealsClaimed = 0;
        carbonSaved = 0;
      }

    } catch (e) {
      debugPrint('Error loading profile: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrganizationProfile({
    required String name,
    required String address,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update NGO table with upsert to handle missing records
      await _supabase.from('ngos').upsert({
        'profile_id': userId,
        'organization_name': name,
        'address_text': address,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'profile_id');

      // Update local state
      organizationName = name;
      location = address;

      debugPrint('Profile updated successfully: $name, $address');

      isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      error = e.toString();
      isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return false;

      isUpdating = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Delete old image if exists
      if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
        try {
          // Extract the path from the URL
          final uri = Uri.parse(profileImageUrl!);
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 3) {
            final oldPath = pathSegments.sublist(2).join('/');
            await _supabase.storage.from('profile-images').remove([oldPath]);
            debugPrint('Deleted old image: $oldPath');
          }
        } catch (e) {
          debugPrint('Error deleting old image: $e');
        }
      }

      // Read image as bytes (works on all platforms including web)
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName'; // Store in user's folder

      debugPrint('Uploading image to: $filePath');

      await _supabase.storage.from('profile-images').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileExt),
          upsert: true,
        ),
      );

      // Get public URL
      final imageUrl = _supabase.storage.from('profile-images').getPublicUrl(filePath);
      debugPrint('Image uploaded successfully: $imageUrl');

      // Update profiles table with avatar_url column
      await _supabase.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', userId);

      debugPrint('Profile table updated with new image URL in avatar_url column');

      profileImageUrl = imageUrl;
      isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      error = e.toString();
      isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  Future<bool> updateLocation(double lat, double lng, String address) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('ngos').update({
        'latitude': lat,
        'longitude': lng,
        'address_text': address,
      }).eq('profile_id', userId);

      latitude = lat;
      longitude = lng;
      addressText = address;
      location = address;

      isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating location: $e');
      error = e.toString();
      isUpdating = false;
      notifyListeners();
      return false;
    }
  }
}
