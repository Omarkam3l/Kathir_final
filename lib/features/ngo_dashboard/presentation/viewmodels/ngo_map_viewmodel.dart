import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/data/models/meal_model.dart';
import '../../../user_home/domain/entities/meal.dart';

class MealLocation {
  final Meal meal;
  final LatLng location;

  MealLocation({required this.meal, required this.location});
}

class NgoMapViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  bool isLoading = true;
  String? error;
  
  // Location
  String locationName = 'Cairo, Egypt';
  LatLng currentLocation = const LatLng(30.0444, 31.2357); // Cairo coordinates
  
  // Meals with locations
  List<MealLocation> mealMarkers = [];
  Meal? selectedMeal;

  Future<void> loadMeals() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('meals')
          .select('''
            id,
            title,
            description,
            category,
            image_url,
            original_price,
            discounted_price,
            quantity_available,
            expiry_date,
            pickup_deadline,
            status,
            location,
            unit,
            fulfillment_method,
            is_donation_available,
            ingredients,
            allergens,
            co2_savings,
            pickup_time,
            created_at,
            updated_at,
            restaurant_id,
            restaurants!inner(
              profile_id,
              restaurant_name,
              rating,
              address_text
            )
          ''')
          .eq('is_donation_available', true)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String())
          .order('expiry_date', ascending: true)
          .limit(20);

      final meals = (res as List).map((json) {
        final restaurantData = json['restaurants'];
        json['restaurant'] = {
          'id': restaurantData['profile_id'],
          'name': restaurantData['restaurant_name'] ?? 'Unknown',
          'rating': restaurantData['rating'] ?? 0.0,
          'logo_url': '',
          'verified': true,
          'reviews_count': 0,
        };
        // Map database fields to model fields
        json['donation_price'] = json['discounted_price'];
        json['quantity'] = json['quantity_available']; // Fix quantity mapping
        json['expiry'] = json['expiry_date'];
        return MealModel.fromJson(json);
      }).toList();

      // Generate random locations around Cairo for demo
      // In production, you'd get actual restaurant coordinates
      mealMarkers = meals.asMap().entries.map((entry) {
        final index = entry.key;
        final meal = entry.value;
        
        // Generate locations in a radius around Cairo
        final latOffset = (index % 5 - 2) * 0.02;
        final lngOffset = ((index ~/ 5) % 5 - 2) * 0.02;
        
        return MealLocation(
          meal: meal,
          location: LatLng(
            currentLocation.latitude + latOffset,
            currentLocation.longitude + lngOffset,
          ),
        );
      }).toList();

      if (mealMarkers.isNotEmpty) {
        selectedMeal = mealMarkers.first.meal;
      }
    } catch (e) {
      debugPrint('Error loading meals: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectMeal(Meal meal) {
    selectedMeal = meal;
    notifyListeners();
  }

  void clearSelection() {
    selectedMeal = null;
    notifyListeners();
  }

  Future<void> claimMeal(Meal meal, BuildContext context) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('orders').insert({
        'user_id': userId,
        'ngo_id': userId,
        'restaurant_id': meal.restaurant.id,
        'meal_id': meal.id,
        'status': 'pending',
        'delivery_type': 'donation',
        'subtotal': meal.donationPrice,
        'total_amount': meal.donationPrice,
      });

      await _supabase
          .from('meals')
          .update({'status': 'reserved'})
          .eq('id', meal.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully claimed: ${meal.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await loadMeals();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
