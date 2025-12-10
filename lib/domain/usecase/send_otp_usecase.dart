import '../repo/forgot_password_repository.dart';

class SendOtpUseCase {
  final ForgotPasswordRepository repo;
  const SendOtpUseCase(this.repo);
  Future<void> call(String email) => repo.sendOtp(email);
}

