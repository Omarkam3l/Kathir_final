import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasource/auth_remote_datasource.dart';
import '../../domain/repo/forgot_password_repository.dart';

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  final AuthRemoteDataSource ds;
  ForgotPasswordRepositoryImpl(this.ds);

  @override
  Future<void> sendOtp(String email) async {
    if (!email.contains('@')) {
      throw const AuthException('Invalid email');
    }
    await ds.sendResetPasswordEmail(email);
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    await ds.verifyOtp(email, otp);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 8) {
      throw const AuthException('Weak password');
    }
    await ds.updatePassword(newPassword);
  }
}

