import '../repo/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repo;
  const VerifyOtpUseCase(this.repo);
  Future<void> call(String email, String otp) => repo.verifyOtp(email, otp);
}
