import 'package:kathir_final/features/user_home/data/models/meal_model.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/meal_repository.dart';

class GetAvailableMealsUseCase {
  final MealRepository repo;
  const GetAvailableMealsUseCase(this.repo);
  Future<Either<Failure, List<MealModel>>> call() => repo.fetchAvailableMeals();
}
