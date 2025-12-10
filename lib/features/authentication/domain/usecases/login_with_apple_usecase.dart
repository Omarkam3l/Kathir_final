import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithAppleUseCase {
  final AuthRepository repo;
  const LoginWithAppleUseCase(this.repo);
  Future<Either<Failure, UserEntity>> call() => repo.signInWithApple();
}

