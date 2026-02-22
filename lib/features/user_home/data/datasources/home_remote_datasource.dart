import 'package:supabase/supabase.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/entities/meal.dart';
import '../models/offer_model.dart';
import '../models/restaurant_model.dart';
import '../models/meal_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<Offer>> getOffers();
  Future<List<Restaurant>> getTopRatedRestaurants();
  Future<List<Meal>> getAvailableMeals();
}

class SupabaseHomeRemoteDataSource implements HomeRemoteDataSource {
  final SupabaseClient client;
  SupabaseHomeRemoteDataSource(this.client);

  @override
  Future<List<Offer>> getOffers() async {
    final res = await client.from('offers').select();
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => OfferModel.fromJson(e)).toList();
  }

  @override
  Future<List<Restaurant>> getTopRatedRestaurants() async {
    final res = await client
        .from('restaurants')
        .select('''
          profile_id,
          restaurant_name,
          rating,
          rating_count,
          profiles!inner(avatar_url)
        ''')
        .order('rating', ascending: false)
        .limit(10);
    
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) {
      final profileData = e['profiles'] as Map<String, dynamic>?;
      return RestaurantModel.fromJson({
        'id': e['profile_id'],
        'name': e['restaurant_name'] ?? 'Unknown Restaurant',
        'rating': e['rating'] ?? 0.0,
        'logo_url': profileData?['avatar_url'],
        'verified': true,
        'reviews_count': e['rating_count'] ?? 0,  // ✅ Now fetches real count from database
      });
    }).toList();
  }

  // Cache for meals data (increased from 30s to 2 minutes for better performance)
  List<Meal>? _cachedMeals;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 2);

  @override
  Future<List<Meal>> getAvailableMeals() async {
    // Return cached data if still valid
    if (_cachedMeals != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedMeals!;
    }

    // OPTIMIZED: Fetch only essential columns including restaurant location
    final res = await client.from('meals').select('''
      id,
      title,
      image_url,
      original_price,
      discounted_price,
      quantity_available,
      expiry_date,
      location,
      category,
      restaurant_id,
      description,
      restaurants!inner(
        profile_id,
        restaurant_name,
        rating,
        latitude,
        longitude,
        address_text
      )
    ''').eq('status', 'active')
      .gt('quantity_available', 0)
      .gt('expiry_date', DateTime.now().toIso8601String())
      .order('updated_at', ascending: false)  // Sort by updated_at to show republished meals first
      .limit(20); // Pagination: fetch first 20 meals
    
    final data = (res as List).cast<Map<String, dynamic>>();
    final meals = data.map((e) {
      // Transform to match MealModel expectations
      final restaurant = e['restaurants'] as Map<String, dynamic>?;
      return MealModel.fromJson({
        'id': e['id'],
        'title': e['title'] ?? '',
        'location': e['location'] ?? 'Pickup at restaurant',
        'image_url': e['image_url'] ?? '',
        'original_price': e['original_price'],
        'donation_price': e['discounted_price'], // Map discounted_price to donation_price
        'quantity': e['quantity_available'], // Map quantity_available to quantity
        'expiry': e['expiry_date'], // Map expiry_date to expiry
        'description': e['description'] ?? '',
        'category': e['category'] ?? 'Meals',
        'status': 'active', // Always active due to filter
        'unit': 'portions', // Default value
        'fulfillment_method': 'pickup', // Default value
        'is_donation_available': true, // Default value
        'pickup_deadline': null,
        'pickup_time': null,
        'ingredients': [],
        'allergens': [],
        'co2_savings': 0.0,
        'restaurant': {
          'id': restaurant?['profile_id'] ?? e['restaurant_id'],
          'name': restaurant?['restaurant_name'] ?? 'Unknown Restaurant',
          'rating': restaurant?['rating'] ?? 0.0,
          'latitude': restaurant?['latitude'],
          'longitude': restaurant?['longitude'],
          'address_text': restaurant?['address_text'],
        },
      });
    }).toList();

    // Cache the results
    _cachedMeals = meals;
    _cacheTime = DateTime.now();

    return meals;
  }
}

