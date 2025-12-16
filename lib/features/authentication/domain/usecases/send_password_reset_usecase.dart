import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository repo;
  const SendPasswordResetUseCase(this.repo);
  Future<Either<Failure, void>> call(String email) => repo.sendPasswordResetEmail(email);
}
