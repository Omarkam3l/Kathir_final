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
  const SupabaseHomeRemoteDataSource(this.client);

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
        'reviews_count': 0,
      });
    }).toList();
  }

  @override
  Future<List<Meal>> getAvailableMeals() async {
    final res = await client.from('meals').select('''
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
      restaurant_id,
      restaurants!inner(
        profile_id,
        restaurant_name,
        rating,
        address_text
      )
    ''').or('status.eq.active,status.is.null')
      .gt('quantity_available', 0)
      .gt('expiry_date', DateTime.now().toIso8601String())
      .order('created_at', ascending: false);
    
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) {
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
        'status': e['status'] ?? 'active',
        'unit': e['unit'] ?? 'portions',
        'fulfillment_method': e['fulfillment_method'] ?? 'pickup',
        'is_donation_available': e['is_donation_available'] ?? true,
        'pickup_deadline': e['pickup_deadline'],
        'pickup_time': e['pickup_time'],
        'ingredients': e['ingredients'] ?? [],
        'allergens': e['allergens'] ?? [],
        'co2_savings': e['co2_savings'] ?? 0.0,
        'restaurant': {
          'id': restaurant?['profile_id'] ?? e['restaurant_id'],
          'name': restaurant?['restaurant_name'] ?? 'Unknown Restaurant',
          'rating': restaurant?['rating'] ?? 0.0,
        },
      });
    }).toList();
  }
}

