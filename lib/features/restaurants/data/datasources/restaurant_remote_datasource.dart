import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/data/models/restaurant_model.dart';
import '../../../user_home/domain/entities/restaurant.dart';

abstract class RestaurantRemoteDataSource {
  Future<List<Restaurant>> fetchTopRatedRestaurants();
}

class SupabaseRestaurantRemoteDataSource implements RestaurantRemoteDataSource {
  final SupabaseClient client;
  const SupabaseRestaurantRemoteDataSource(this.client);

  @override
  Future<List<Restaurant>> fetchTopRatedRestaurants() async {
    final res = await client
        .from('restaurants')
        .select()
        .order('rating', ascending: false);
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => RestaurantModel.fromJson(e)).toList();
  }
}
