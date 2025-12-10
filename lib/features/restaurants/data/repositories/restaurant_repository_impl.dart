import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../datasources/restaurant_remote_datasource.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../../../user_home/domain/entities/restaurant.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDataSource remote;
  const RestaurantRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<Restaurant>>> fetchTopRatedRestaurants() async {
    try {
      final r = await remote.fetchTopRatedRestaurants();
      return Right(r);
    } catch (e) {
      return Left(Failure('fetchTopRatedRestaurants failed', cause: e));
    }
  }
}
