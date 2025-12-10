import 'package:kathir_final/features/user_home/data/models/meal_model.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';

abstract class MealRepository {
  Future<Either<Failure, List<MealModel>>> fetchAvailableMeals();
  Future<Either<Failure, List<MealModel>>> fetchHighlights();
  Future<Either<Failure, List<MealModel>>> searchMeals(String query);
}
