import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/user_role.dart';
import '../../../../core/utils/storage_constants.dart';
import '../../../../core/utils/auth_logger.dart';
import '../../../../core/supabase/supabase_helper.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUpUser(String fullName, String email, String password, {required String phone});
  Future<UserModel> signUpNGO(
      String orgName, String fullName, String email, String password,
      {required String phone});
  Future<UserModel> signUpRestaurant(
      String orgName, String fullName, String email, String password,
      {required String phone});
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
    try {
      AuthLogger.info('signIn.attempt', ctx: {'email': email});
      
      final res =
          await client.auth.signInWithPassword(email: email, password: password);
      
      AuthLogger.info('signIn.success', ctx: {
        'email': email,
        'userId': res.user?.id,
        'hasSession': res.session != null,
      });
      
      return UserModelFactory.fromAuthUser(res.user!);
    } catch (e, stackTrace) {
      AuthLogger.errorLog('signIn.failed',
          ctx: {'email': email},
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserModel> signUpUser(
      String fullName, String email, String password, {required String phone}) async {
    try {
      AuthLogger.signupAttempt(role: 'user', email: email);
      
      final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': UserRole.user.wireValue,
            'phone_number': phone,
          },
          emailRedirectTo: kIsWeb
              ? Uri.base.toString()
              : 'io.supabase.flutter://login-callback/');
      
      final userId = res.user?.id;
      final hasSession = res.session != null;
      final emailConfirmed = res.user?.emailConfirmedAt != null;
      
      AuthLogger.signupResult(
        role: 'user',
        email: email,
        userId: userId,
        hasSession: hasSession,
        emailConfirmed: emailConfirmed,
      );
      
      if (!hasSession) {
        AuthLogger.otpRequested(email: email, type: 'signup');
      }
      
      return UserModelFactory.fromAuthUser(res.user!);
    } catch (e, stackTrace) {
      AuthLogger.errorLog('signUpUser.failed',
          ctx: {'role': 'user', 'email': email},
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserModel> signUpNGO(
      String orgName, String fullName, String email, String password,
      {required String phone}) async {
    try {
      AuthLogger.signupAttempt(role: 'ngo', email: email);
      
      AuthLogger.info('signUpNGO.metadata', ctx: {
        'email': email,
        'fullName': fullName,
        'orgName': orgName,
        'hasPhone': true,
        'role': UserRole.ngo.wireValue,
      });
      
      final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': UserRole.ngo.wireValue,
            'organization_name': orgName,
            'phone_number': phone,
          },
          emailRedirectTo: kIsWeb
              ? Uri.base.toString()
              : 'io.supabase.flutter://login-callback/');
      
      final userId = res.user?.id;
      final hasSession = res.session != null;
      final emailConfirmed = res.user?.emailConfirmedAt != null;
      
      AuthLogger.signupResult(
        role: 'ngo',
        email: email,
        userId: userId,
        hasSession: hasSession,
        emailConfirmed: emailConfirmed,
      );
      
      if (!hasSession) {
        AuthLogger.otpRequested(email: email, type: 'signup');
      }
      
      return UserModelFactory.fromAuthUser(res.user!);
    } on AuthException catch (e, stackTrace) {
      // Supabase-specific auth error
      AuthLogger.errorLog('signUpNGO.authException',
          ctx: {
            'role': 'ngo',
            'email': email,
            'orgName': orgName,
            'statusCode': e.statusCode,
            'message': e.message,
          },
          error: e,
          stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      // Generic error
      AuthLogger.errorLog('signUpNGO.failed',
          ctx: {
            'role': 'ngo',
            'email': email,
            'orgName': orgName,
            'errorType': e.runtimeType.toString(),
          },
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserModel> signUpRestaurant(
      String orgName, String fullName, String email, String password,
      {required String phone}) async {
    try {
      AuthLogger.signupAttempt(role: 'restaurant', email: email);
      
      AuthLogger.info('signUpRestaurant.metadata', ctx: {
        'email': email,
        'fullName': fullName,
        'orgName': orgName,
        'hasPhone': true,
        'role': UserRole.restaurant.wireValue,
      });
      
      final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': UserRole.restaurant.wireValue,
            'organization_name': orgName,
            'phone_number': phone,
          },
          emailRedirectTo: kIsWeb
              ? Uri.base.toString()
              : 'io.supabase.flutter://login-callback/');
      
      final userId = res.user?.id;
      final hasSession = res.session != null;
      final emailConfirmed = res.user?.emailConfirmedAt != null;
      
      AuthLogger.signupResult(
        role: 'restaurant',
        email: email,
        userId: userId,
        hasSession: hasSession,
        emailConfirmed: emailConfirmed,
      );
      
      if (!hasSession) {
        AuthLogger.otpRequested(email: email, type: 'signup');
      }
      
      return UserModelFactory.fromAuthUser(res.user!);
    } on AuthException catch (e, stackTrace) {
      // Supabase-specific auth error
      AuthLogger.errorLog('signUpRestaurant.authException',
          ctx: {
            'role': 'restaurant',
            'email': email,
            'orgName': orgName,
            'statusCode': e.statusCode,
            'message': e.message,
          },
          error: e,
          stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      // Generic error
      AuthLogger.errorLog('signUpRestaurant.failed',
          ctx: {
            'role': 'restaurant',
            'email': email,
            'orgName': orgName,
            'errorType': e.runtimeType.toString(),
          },
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
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
      {String bucket = StorageConstants.legalDocsBucket}) async {
    AuthLogger.docUploadAttempt(userId: userId, fileName: fileName);
    
    final path = '$userId/$fileName';
    
    try {
      final url = await helper.uploadDocument(bucket: bucket, path: path, bytes: bytes);
      AuthLogger.docUploadSuccess(userId: userId, fileName: fileName, url: url);
      return url;
    } catch (e, stackTrace) {
      AuthLogger.docUploadFailed(
        userId: userId,
        fileName: fileName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AuthLogger.otpRequested(email: email, type: 'recovery');
      
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? Uri.base.toString()
            : 'io.supabase.flutter://login-callback/',
      );
      
      AuthLogger.info('passwordReset.emailSent', ctx: {'email': email});
    } catch (e, stackTrace) {
      AuthLogger.otpRequestFailed(
        email: email,
        type: 'recovery',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<UserModel> verifySignupOtp(String email, String otp) async {
    try {
      AuthLogger.otpVerifyAttempt(email: email, type: 'signup');
      
      await client.auth.verifyOTP(type: OtpType.signup, token: otp, email: email);
      final s = await _waitForSession();
      final u = client.auth.currentUser;
      
      if (u == null && s?.user == null) {
        AuthLogger.otpVerifyResult(
          email: email,
          type: 'signup',
          success: false,
        );
        throw const AuthException('Verification failed');
      }
      
      final userId = (u ?? s!.user).id;
      AuthLogger.otpVerifyResult(
        email: email,
        type: 'signup',
        success: true,
        userId: userId,
      );
      
      return UserModelFactory.fromAuthUser(u ?? s!.user);
    } catch (e, stackTrace) {
      AuthLogger.errorLog('verifySignupOtp.failed',
          ctx: {'email': email, 'type': 'signup'},
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> verifyRecoveryOtp(String email, String otp) async {
    try {
      AuthLogger.otpVerifyAttempt(email: email, type: 'recovery');
      
      await client.auth.verifyOTP(
        type: OtpType.recovery,
        token: otp,
        email: email,
      );
      
      AuthLogger.otpVerifyResult(
        email: email,
        type: 'recovery',
        success: true,
      );
    } catch (e, stackTrace) {
      AuthLogger.errorLog('verifyRecoveryOtp.failed',
          ctx: {'email': email, 'type': 'recovery'},
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
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
