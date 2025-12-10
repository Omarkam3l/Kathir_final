import 'package:flutter/foundation.dart';
import '../../../user_home/domain/entities/offer.dart';
import '../../../user_home/domain/entities/restaurant.dart';
import '../../../user_home/domain/entities/meal.dart';
import '../../../user_home/domain/usecases/get_offers.dart';
import '../../../user_home/domain/usecases/get_top_rated_restaurants.dart';
import '../../../user_home/domain/usecases/get_available_meals.dart';
import '../../../../core/errors/failure.dart';

enum HomeStatus { idle, loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final GetOffers getOffers;
  final GetTopRatedRestaurants getTopRestaurants;
  final GetAvailableMeals getMeals;

  HomeStatus status = HomeStatus.idle;
  List<Offer> offers = const [];
  List<Restaurant> restaurants = const [];
  List<Meal> meals = const [];
  Failure? failure;

  HomeViewModel({
    required this.getOffers,
    required this.getTopRestaurants,
    required this.getMeals,
  });

  Future<void> loadAll() async {
    status = HomeStatus.loading;
    notifyListeners();
    final o = await getOffers();
    final r = await getTopRestaurants();
    final m = await getMeals();
    o.fold((l) => failure = l, (v) => offers = v);
    r.fold((l) => failure = l, (v) => restaurants = v);
    m.fold((l) => failure = l, (v) => meals = v);
    status = failure == null ? HomeStatus.success : HomeStatus.error;
    notifyListeners();
  }
}

