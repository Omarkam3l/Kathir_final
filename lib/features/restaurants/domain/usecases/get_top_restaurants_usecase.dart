import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/restaurant_repository.dart';
import '../../../user_home/domain/entities/restaurant.dart';

class GetTopRestaurantsUseCase {
  final RestaurantRepository repo;
  const GetTopRestaurantsUseCase(this.repo);
  Future<Either<Failure, List<Restaurant>>> call() => repo.fetchTopRatedRestaurants();
}
