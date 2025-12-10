import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/restaurant.dart';
import '../repositories/home_repository.dart';

class GetTopRatedRestaurants {
  final HomeRepository repo;
  const GetTopRatedRestaurants(this.repo);
  Future<Either<Failure, List<Restaurant>>> call() => repo.getTopRatedRestaurants();
}

