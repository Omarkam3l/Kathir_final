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
  
  // Smart loading: TTL tracking
  DateTime? _lastFetchTime;
  static const _ttl = Duration(minutes: 2);

  HomeViewModel({
    required this.getOffers,
    required this.getTopRestaurants,
    required this.getMeals,
  });

  bool get _isDataStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _ttl;
  }

  /// Smart load: only fetch if data is missing or stale
  Future<void> loadIfNeeded() async {
    // Skip if data exists and is fresh
    if (meals.isNotEmpty && !_isDataStale) {
      return;
    }
    
    // Skip if already loading (in-flight guard)
    if (status == HomeStatus.loading) {
      return;
    }
    
    await loadAll();
  }

  Future<void> loadAll({bool forceRefresh = false}) async {
    // Skip if data is fresh and not forcing refresh
    if (!forceRefresh && meals.isNotEmpty && !_isDataStale) {
      return;
    }
    
    status = HomeStatus.loading;
    notifyListeners();
    
    final o = await getOffers();
    final r = await getTopRestaurants();
    final m = await getMeals();
    
    o.fold((l) => failure = l, (v) => offers = v);
    r.fold((l) => failure = l, (v) => restaurants = v);
    m.fold((l) => failure = l, (v) => meals = v);
    
    _lastFetchTime = DateTime.now();
    status = failure == null ? HomeStatus.success : HomeStatus.error;
    notifyListeners();
  }
  
  /// Clear state on logout
  void clearState() {
    status = HomeStatus.idle;
    offers = const [];
    restaurants = const [];
    meals = const [];
    failure = null;
    _lastFetchTime = null;
    notifyListeners();
  }
}

