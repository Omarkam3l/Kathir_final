import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
  List<MealLocation> filteredMealMarkers = [];
  Meal? selectedMeal;
  double currentRadius = 10.0; // km

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
              latitude,
              longitude,
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
          'latitude': restaurantData['latitude'],
          'longitude': restaurantData['longitude'],
          'address_text': restaurantData['address_text'],
        };
        // Map database fields to model fields
        json['donation_price'] = json['discounted_price'];
        json['quantity'] = json['quantity_available']; // Fix quantity mapping
        json['expiry'] = json['expiry_date'];
        return MealModel.fromJson(json);
      }).toList();

      // Use actual restaurant coordinates from database
      mealMarkers = meals.where((meal) {
        // Filter out meals without valid coordinates
        return meal.restaurant.latitude != null && 
               meal.restaurant.longitude != null;
      }).map((meal) {
        return MealLocation(
          meal: meal,
          location: LatLng(
            meal.restaurant.latitude!,
            meal.restaurant.longitude!,
          ),
        );
      }).toList();

      if (mealMarkers.isNotEmpty) {
        selectedMeal = mealMarkers.first.meal;
      }

      // Apply initial radius filter
      filterByRadius(currentRadius);
    } catch (e) {
      debugPrint('Error loading meals: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void filterByRadius(double radiusKm) {
    currentRadius = radiusKm;
    
    filteredMealMarkers = mealMarkers.where((mealLocation) {
      final distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        mealLocation.location.latitude,
        mealLocation.location.longitude,
      ) / 1000; // Convert to km

      return distance <= radiusKm;
    }).toList();

    notifyListeners();
  }

  void selectMeal(Meal meal) {
    selectedMeal = meal;
    notifyListeners();
  }

  void clearSelection() {
    selectedMeal = null;
    notifyListeners();
  }

  void updateLocation(LatLng newLocation, String newLocationName) {
    currentLocation = newLocation;
    locationName = newLocationName;
    notifyListeners();
    // Reload meals and apply radius filter
    loadMeals();
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
