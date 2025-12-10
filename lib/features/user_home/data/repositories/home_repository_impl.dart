import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remote;
  const HomeRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<Offer>>> getOffers() async {
    try {
      final r = await remote.getOffers();
      return Right(r);
    } catch (e) {
      return Left(Failure('Failed to load offers', cause: e));
    }
  }

  @override
  Future<Either<Failure, List<Restaurant>>> getTopRatedRestaurants() async {
    try {
      final r = await remote.getTopRatedRestaurants();
      return Right(r);
    } catch (e) {
      return Left(Failure('Failed to load restaurants', cause: e));
    }
  }

  @override
  Future<Either<Failure, List<Meal>>> getAvailableMeals() async {
    try {
      final r = await remote.getAvailableMeals();
      return Right(r);
    } catch (e) {
      return Left(Failure('Failed to load meals', cause: e));
    }
  }
}

