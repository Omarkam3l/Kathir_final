import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/data/models/meal_model.dart';

abstract class MealRemoteDataSource {
  Future<List<MealModel>> fetchAvailableMeals();
  Future<List<MealModel>> fetchHighlights();
  Future<List<MealModel>> searchMeals(String query);
}

class SupabaseMealRemoteDataSource implements MealRemoteDataSource {
  final SupabaseClient client;
  const SupabaseMealRemoteDataSource(this.client);

  @override
  Future<List<MealModel>> fetchAvailableMeals() async {
    final res = await client.from('meals').select(
        'id,title,location,image_url,original_price,donation_price,quantity,expiry,restaurant:restaurants(id,name,rating)');
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => MealModel.fromJson(e)).toList();
  }

  @override
  Future<List<MealModel>> fetchHighlights() async {
    final res = await client
        .from('meals')
        .select(
            'id,title,location,image_url,original_price,donation_price,quantity,expiry,restaurant:restaurants(id,name,rating)')
        .lte('expiry',
            DateTime.now().add(const Duration(hours: 6)).toIso8601String());
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => MealModel.fromJson(e)).toList();
  }

  @override
  Future<List<MealModel>> searchMeals(String query) async {
    final res = await client
        .from('meals')
        .select(
            'id,title,location,image_url,original_price,donation_price,quantity,expiry,restaurant:restaurants(id,name,rating)')
        .ilike('title', '%$query%');
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => MealModel.fromJson(e)).toList();
  }
}
