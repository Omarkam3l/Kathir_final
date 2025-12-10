import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasource/auth_remote_datasource.dart';
import '../../domain/repo/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _ds;
  AuthRepositoryImpl({AuthRemoteDataSource? dataSource})
      : _ds = dataSource ?? AuthRemoteDataSource();

  @override
  Future<void> requestPasswordReset(String value) async {
    if (!value.contains('@')) {
      throw const AuthException('Invalid email');
    }
    await _ds.sendResetPasswordEmail(value);
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    await _ds.verifyOtp(email, otp);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 8) {
      throw const AuthException('Weak password');
    }
    await _ds.updatePassword(newPassword);
  }
}
