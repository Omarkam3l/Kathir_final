abstract class AuthRepository {
  Future<void> requestPasswordReset(String value);
  Future<void> verifyOtp(String email, String otp);
  Future<void> updatePassword(String newPassword);
}
