import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class VerifyRecoveryOtpUseCase {
  final AuthRepository repo;
  const VerifyRecoveryOtpUseCase(this.repo);
  Future<Either<Failure, void>> call(String email, String otp) =>
      repo.verifyRecoveryOtp(email, otp);
}
