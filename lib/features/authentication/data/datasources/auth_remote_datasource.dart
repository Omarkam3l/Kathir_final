import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/user_role.dart';
import '../../../../core/utils/storage_constants.dart';
import '../../../../core/supabase/supabase_helper.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUpUser(String fullName, String email, String password);
  Future<UserModel> signUpNGO(
      String orgName, String fullName, String email, String password,
      {String? phone});
  Future<UserModel> signUpRestaurant(
      String orgName, String fullName, String email, String password,
      {String? phone});
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithFacebook();
  Future<UserModel> signInWithApple();
  Future<void> signOut();
  Future<String> uploadDocuments(
      String userId, String fileName, List<int> bytes,
      {String bucket});
  Future<void> sendPasswordResetEmail(String email);
  Future<UserModel> verifySignupOtp(String email, String otp);
  Future<void> verifyRecoveryOtp(String email, String otp);
  Future<void> updatePassword(String newPassword);
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final SupabaseClient client;
  final SupabaseHelper helper;
  const SupabaseAuthRemoteDataSource(this.client, this.helper);

  // profile upsert handled elsewhere when needed; auth flow returns auth.users

  @override
  Future<UserModel> signIn(String email, String password) async {
    final res =
        await client.auth.signInWithPassword(email: email, password: password);
    return UserModelFactory.fromAuthUser(res.user!);
  }

  @override
  Future<UserModel> signUpUser(
      String fullName, String email, String password) async {
    final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': UserRole.user.wireValue},
        emailRedirectTo: kIsWeb
            ? Uri.base.toString()
            : 'io.supabase.flutter://login-callback/');
    if (res.session == null) {
      return UserModelFactory.fromAuthUser(res.user!);
    }
    return UserModelFactory.fromAuthUser(res.user!);
  }

  @override
  Future<UserModel> signUpNGO(
      String orgName, String fullName, String email, String password,
      {String? phone}) async {
    final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': UserRole.ngo.wireValue},
        emailRedirectTo: kIsWeb
            ? Uri.base.toString()
            : 'io.supabase.flutter://login-callback/');
    if (res.session == null) {
      return UserModelFactory.fromAuthUser(res.user!);
    }
    return UserModelFactory.fromAuthUser(res.user!);
  }

  @override
  Future<UserModel> signUpRestaurant(
      String orgName, String fullName, String email, String password,
      {String? phone}) async {
    final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': UserRole.restaurant.wireValue,
          // TODO: Add organization_name to restaurant table after profile creation
          'phone': phone,
        },
        emailRedirectTo: kIsWeb
            ? Uri.base.toString()
            : 'io.supabase.flutter://login-callback/');
    if (res.session == null) {
      return UserModelFactory.fromAuthUser(res.user!);
    }
    return UserModelFactory.fromAuthUser(res.user!);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.toString() : null,
    );
    await _waitForSession();
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Google sign-in did not complete');
    }
    return UserModelFactory.fromAuthUser(user);
  }

  @override
  Future<UserModel> signInWithFacebook() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? Uri.base.toString() : null,
    );
    await _waitForSession();
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Facebook sign-in did not complete');
    }
    return UserModelFactory.fromAuthUser(user);
  }

  @override
  Future<UserModel> signInWithApple() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? Uri.base.toString() : null,
    );
    await _waitForSession();
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Apple sign-in did not complete');
    }
    return UserModelFactory.fromAuthUser(user);
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  @override
  Future<String> uploadDocuments(
      String userId, String fileName, List<int> bytes,
      {String bucket = StorageConstants.legalDocsBucket}) {
    final path = '$userId/$fileName';
    return helper.uploadDocument(bucket: bucket, path: path, bytes: bytes);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb
          ? Uri.base.toString()
          : 'io.supabase.flutter://login-callback/',
    );
  }

  @override
  Future<UserModel> verifySignupOtp(String email, String otp) async {
    await client.auth.verifyOTP(type: OtpType.signup, token: otp, email: email);
    final s = await _waitForSession();
    final u = client.auth.currentUser;
    if (u == null && s?.user == null) {
      throw const AuthException('Verification failed');
    }
    return UserModelFactory.fromAuthUser(u ?? s!.user);
  }

  @override
  Future<void> verifyRecoveryOtp(String email, String otp) async {
    await client.auth.verifyOTP(
      type: OtpType.recovery,
      token: otp,
      email: email,
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }
}

extension on SupabaseAuthRemoteDataSource {
  Future<Session?> _waitForSession(
      {Duration timeout = const Duration(seconds: 60)}) async {
    if (client.auth.currentSession != null) {
      return client.auth.currentSession;
    }
    final completer = Completer<Session?>();
    late StreamSubscription sub;
    sub = client.auth.onAuthStateChange.listen((event) {
      final session = client.auth.currentSession;
      if (session != null) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(session);
      }
    });
    return completer.future.timeout(timeout, onTimeout: () {
      sub.cancel();
      return client.auth.currentSession;
    });
  }
}
