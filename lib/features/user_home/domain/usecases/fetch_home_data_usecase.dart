import '../entities/home_data.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../meals/domain/repositories/meal_repository.dart';
import '../../../restaurants/domain/repositories/restaurant_repository.dart';

class FetchHomeDataUseCase {
  final MealRepository mealRepo;
  final RestaurantRepository restaurantRepo;
  const FetchHomeDataUseCase(
      {required this.mealRepo, required this.restaurantRepo});

  Future<Either<Failure, HomeData>> call() async {
    final m = await mealRepo.fetchAvailableMeals();
    final r = await restaurantRepo.fetchTopRatedRestaurants();
    return m.fold(
      (lf) => Left(lf),
      (meals) => r.fold(
        (lr) => Left(lr),
        (restaurants) =>
            Right(HomeData(meals: meals, restaurants: restaurants)),
      ),
    );
  }
}
