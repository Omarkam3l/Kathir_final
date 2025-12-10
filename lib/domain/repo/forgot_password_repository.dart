abstract class ForgotPasswordRepository {
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String otp);
  Future<void> updatePassword(String newPassword);
}

