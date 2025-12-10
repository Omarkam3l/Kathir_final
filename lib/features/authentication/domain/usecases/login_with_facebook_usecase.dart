import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithFacebookUseCase {
  final AuthRepository repo;
  const LoginWithFacebookUseCase(this.repo);
  Future<Either<Failure, UserEntity>> call() => repo.signInWithFacebook();
}

