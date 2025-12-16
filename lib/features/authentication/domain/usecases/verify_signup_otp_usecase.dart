import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifySignupOtpUseCase {
  final AuthRepository repo;
  const VerifySignupOtpUseCase(this.repo);
  Future<Either<Failure, UserEntity>> call(String email, String otp) =>
      repo.verifySignupOtp(email, otp);
}
