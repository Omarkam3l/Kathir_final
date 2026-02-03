import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NgoProfileViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  bool isLoading = true;
  String? error;
  
  // Profile data
  String location = 'Cairo, Egypt';
  int mealsClaimed = 0;
  double carbonSaved = 0;
  bool isVerified = true;

  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get NGO profile
      final profileRes = await _supabase
          .from('ngos')
          .select('*')
          .eq('profile_id', userId)
          .single();

      // Get stats from orders
      final completedRes = await _supabase
          .from('orders')
          .select('id')
          .eq('ngo_id', userId)
          .eq('status', 'completed');
      
      mealsClaimed = (completedRes as List).length;
      carbonSaved = mealsClaimed * 2.5; // Avg 2.5kg CO2 per meal

      // Update location if available
      if (profileRes['address_text'] != null) {
        location = profileRes['address_text'];
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}
