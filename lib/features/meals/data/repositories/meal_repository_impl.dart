import 'package:kathir_final/features/user_home/data/models/meal_model.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../datasources/meal_remote_datasource.dart';
import '../../domain/repositories/meal_repository.dart';

class MealRepositoryImpl implements MealRepository {
  final MealRemoteDataSource remote;
  const MealRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<MealModel>>> fetchAvailableMeals() async {
    try {
      final r = await remote.fetchAvailableMeals();
      return Right(r);
    } catch (e) {
      return Left(Failure('fetchAvailableMeals failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, List<MealModel>>> fetchHighlights() async {
    try {
      final r = await remote.fetchHighlights();
      return Right(r);
    } catch (e) {
      return Left(Failure('fetchHighlights failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, List<MealModel>>> searchMeals(String query) async {
    try {
      final r = await remote.searchMeals(query);
      return Right(r);
    } catch (e) {
      return Left(Failure('searchMeals failed', cause: e));
    }
  }
}
