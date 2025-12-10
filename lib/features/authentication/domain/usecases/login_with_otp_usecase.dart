import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithOtpUseCase {
  final AuthRepository repo;
  const LoginWithOtpUseCase(this.repo);
  Future<Either<Failure, UserEntity>> call(String email) async {
    // For OTP we reuse signIn() once session exists, callers should listen to onAuthStateChange
    return repo.signIn(email, '');
  }
}

