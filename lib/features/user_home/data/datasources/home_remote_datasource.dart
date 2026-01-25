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
    final res = await client.from('restaurants').select().order('rating', ascending: false);
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => RestaurantModel.fromJson(e)).toList();
  }

  @override
  Future<List<Meal>> getAvailableMeals() async {
    final res = await client.from('meals').select(
        'id,title,location,image_url,original_price,donation_price,quantity,expiry,restaurant:restaurants(id,name,rating)');
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => MealModel.fromJson(e)).toList();
  }
}

