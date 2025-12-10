import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../user_home/domain/entities/restaurant.dart';

abstract class RestaurantRepository {
  Future<Either<Failure, List<Restaurant>>> fetchTopRatedRestaurants();
}
