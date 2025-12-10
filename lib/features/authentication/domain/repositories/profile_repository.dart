import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getById(String id);
  Future<Either<Failure, ProfileEntity>> createOrUpdate(String id, Map<String, dynamic> data);
}
