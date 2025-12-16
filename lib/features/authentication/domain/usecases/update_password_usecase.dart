import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  final AuthRepository repo;
  const UpdatePasswordUseCase(this.repo);
  Future<Either<Failure, void>> call(String newPassword) =>
      repo.updatePassword(newPassword);
}
