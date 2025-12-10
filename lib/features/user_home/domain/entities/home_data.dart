import '../../data/models/meal_model.dart';
import '../entities/restaurant.dart';

class HomeData {
  final List<MealModel> meals;
  final List<Restaurant> restaurants;
  const HomeData({required this.meals, required this.restaurants});
}

