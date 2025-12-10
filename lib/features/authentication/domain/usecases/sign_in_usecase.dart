import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repo;
  const SignInUseCase(this.repo);
  Future<Either<Failure, UserEntity>> call(String email, String password) => repo.signIn(email, password);
}

