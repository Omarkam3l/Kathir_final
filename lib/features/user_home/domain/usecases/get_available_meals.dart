import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/meal.dart';
import '../repositories/home_repository.dart';

class GetAvailableMeals {
  final HomeRepository repo;
  const GetAvailableMeals(this.repo);
  Future<Either<Failure, List<Meal>>> call() => repo.getAvailableMeals();
}

