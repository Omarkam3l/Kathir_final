import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class CreateOrGetProfileUseCase {
  final ProfileRepository repo;
  const CreateOrGetProfileUseCase(this.repo);
  Future<Either<Failure, ProfileEntity>> call(String id, Map<String, dynamic> data) => repo.createOrUpdate(id, data);
}
