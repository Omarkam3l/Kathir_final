import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/offer.dart';
import '../entities/restaurant.dart';
import '../entities/meal.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Offer>>> getOffers();
  Future<Either<Failure, List<Restaurant>>> getTopRatedRestaurants();
  Future<Either<Failure, List<Meal>>> getAvailableMeals();
}

