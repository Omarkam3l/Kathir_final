import 'package:supabase_flutter/supabase_flutter.dart';
import '../../di/global_injection/app_locator.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client = AppLocator.I.get<SupabaseClient>();

  Future<void> sendResetPasswordEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      token: otp,
      email: email,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
