import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/user_role.dart';
import '../../../../core/utils/auth_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/upload_legal_documents_usecase.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../../domain/usecases/create_or_get_profile_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/verify_signup_otp_usecase.dart';
import '../../domain/usecases/verify_recovery_otp_usecase.dart';
import '../../domain/usecases/update_password_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  final SignInUseCase signIn;
  final SignUpUseCase signUp;
  final UploadLegalDocumentsUseCase uploadDocs;
  final SocialLoginUseCase socialLogin;
  final CreateOrGetProfileUseCase createOrGetProfile;
  final SendPasswordResetUseCase sendPasswordReset;
  final VerifySignupOtpUseCase verifySignupOtp;
  final VerifyRecoveryOtpUseCase verifyRecoveryOtp;
  final UpdatePasswordUseCase updatePassword;

  bool loading = false;
  Failure? failure;
  UserEntity? user;

  bool isLogin = true;
  UserRole? selectedRole;
  
  // ✅ FIX: Store pending legal documents for upload after OTP verification
  List<int>? pendingLegalDocBytes;
  String? pendingLegalDocFileName;

  AuthViewModel({
    required this.signIn,
    required this.signUp,
    required this.uploadDocs,
    required this.socialLogin,
    required this.createOrGetProfile,
    required this.sendPasswordReset,
    required this.verifySignupOtp,
    required this.verifyRecoveryOtp,
    required this.updatePassword,
  });

  Future<bool> login(String email, String password) async {
    loading = true;
    notifyListeners();
    
    AuthLogger.info('login.attempt', ctx: {'email': email});
    
    final res = await signIn(email, password);
    final ok = res.fold((l) {
      failure = l;
      AuthLogger.errorLog('login.failed', ctx: {'email': email}, error: l.message);
      return false;
    }, (r) {
      user = r;
      final data = {
        'email': r.email,
        'full_name': r.fullName,
        'role': r.role,
        if (r.phoneNumber != null) 'phone_number': r.phoneNumber,
        'is_verified': r.isVerified,
      };
      
      AuthLogger.info('login.success', ctx: {
        'email': email,
        'userId': r.id,
        'role': r.role,
      });
      
      createOrGetProfile.call(r.id, data);
      return true;
    });
    
    loading = false;
    notifyListeners();
    return ok;
  }

  Future<bool> signup(SignUpRole role, String fullName, String email, String password,
      {String? organizationName, String? phone}) async {
    loading = true;
    notifyListeners();
    
    AuthLogger.info('signup.viewmodel.start', ctx: {
      'role': role.toString(),
      'email': email,
      'hasOrgName': organizationName != null,
      'hasPhone': phone != null,
    });
    
    final res = await signUp(
      role: role,
      fullName: fullName,
      email: email,
      password: password,
      organizationName: organizationName,
      phone: phone,
    );
    
    final ok = res.fold((l) {
      failure = l;
      AuthLogger.errorLog('signup.viewmodel.failed',
          ctx: {'role': role.toString(), 'email': email},
          error: l.message);
      return false;
    }, (r) {
      user = r;
      
      AuthLogger.info('signup.viewmodel.success', ctx: {
        'role': role.toString(),
        'email': email,
        'userId': r.id,
        'isVerified': r.isVerified,
      });
      
      if (user?.isVerified == true) {
        return true;
      }
      failure = const Failure('Please verify your email to complete signup');
      return false;
    });
    
    loading = false;
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithProvider(OAuthProvider provider) async {
    loading = true;
    notifyListeners();
    final res = await socialLogin(provider);
    final ok = res.fold((l) {
      failure = l;
      return false;
    }, (r) {
      user = r;
      return true;
    });
    loading = false;
    notifyListeners();
    return ok;
  }

  /// Returns (url, error). On success url is set; on failure error contains the message.
  Future<({String? url, String? error})> uploadLegalDoc(String userId, String fileName, List<int> bytes) async {
    AuthLogger.docUploadAttempt(userId: userId, fileName: fileName);
    
    final res = await uploadDocs(userId, fileName, bytes);
    final result = res.fold(
      (l) {
        AuthLogger.docUploadFailed(
          userId: userId,
          fileName: fileName,
          error: l.cause ?? l.message,
        );
        return (url: null, error: l.cause?.toString() ?? l.message);
      },
      (r) {
        AuthLogger.docUploadSuccess(userId: userId, fileName: fileName, url: r);
        return (url: r, error: null);
      },
    );
    
    // Save URL to database using atomic append RPC
    if (result.url != null && user != null) {
      try {
        final client = Supabase.instance.client;
        final role = user!.role;
        
        if (role == 'restaurant') {
          AuthLogger.dbOp(
            operation: 'rpc.append_restaurant_legal_doc',
            table: 'restaurants',
            userId: userId,
            extra: {'url': result.url},
          );
          
          // Call RPC function to atomically append URL
          final rpcResult = await client.rpc(
            'append_restaurant_legal_doc',
            params: {'p_url': result.url},
          );
          
          AuthLogger.info('legalDoc.saved', ctx: {
            'userId': userId,
            'role': role,
            'table': 'restaurants',
            'url': result.url,
            'updatedUrls': rpcResult['legal_docs_urls'],
          });
          
          // Verify URL was saved by reading back
          final verification = await client
              .from('restaurants')
              .select('legal_docs_urls')
              .eq('profile_id', userId)
              .single();
          
          final savedUrls = verification['legal_docs_urls'] as List?;
          if (savedUrls == null || !savedUrls.contains(result.url)) {
            AuthLogger.warn('legalDoc.verificationFailed', ctx: {
              'userId': userId,
              'expectedUrl': result.url,
              'actualUrls': savedUrls,
            });
          } else {
            AuthLogger.info('legalDoc.verified', ctx: {
              'userId': userId,
              'urlCount': savedUrls.length,
            });
          }
          
        } else if (role == 'ngo') {
          AuthLogger.dbOp(
            operation: 'rpc.append_ngo_legal_doc',
            table: 'ngos',
            userId: userId,
            extra: {'url': result.url},
          );
          
          // Call RPC function to atomically append URL
          final rpcResult = await client.rpc(
            'append_ngo_legal_doc',
            params: {'p_url': result.url},
          );
          
          AuthLogger.info('legalDoc.saved', ctx: {
            'userId': userId,
            'role': role,
            'table': 'ngos',
            'url': result.url,
            'updatedUrls': rpcResult['legal_docs_urls'],
          });
          
          // Verify URL was saved by reading back
          final verification = await client
              .from('ngos')
              .select('legal_docs_urls')
              .eq('profile_id', userId)
              .single();
          
          final savedUrls = verification['legal_docs_urls'] as List?;
          if (savedUrls == null || !savedUrls.contains(result.url)) {
            AuthLogger.warn('legalDoc.verificationFailed', ctx: {
              'userId': userId,
              'expectedUrl': result.url,
              'actualUrls': savedUrls,
            });
          } else {
            AuthLogger.info('legalDoc.verified', ctx: {
              'userId': userId,
              'urlCount': savedUrls.length,
            });
          }
        }
      } catch (e, stackTrace) {
        final table = user!.role == 'restaurant' ? 'restaurants' : 'ngos';
        AuthLogger.dbOpFailed(
          operation: 'rpc.append_legal_doc',
          table: table,
          userId: userId,
          extra: {'url': result.url},
          error: e,
          stackTrace: stackTrace,
        );
        debugPrint('Failed to save legal doc URL to database: $e');
        // Don't fail the whole operation, just log the error
      }
    }
    
    return result;
  }

  Future<bool> requestPasswordReset(String email) async {
    loading = true;
    failure = null;
    notifyListeners();
    final res = await sendPasswordReset(email);
    final ok = res.fold((l) {
      failure = l;
      return false;
    }, (_) => true);
    loading = false;
    notifyListeners();
    return ok;
  }

  Future<bool> confirmSignupCode(String email, String otp) async {
    loading = true;
    failure = null;
    notifyListeners();
    
    AuthLogger.info('confirmSignupCode.attempt', ctx: {'email': email});
    
    final res = await verifySignupOtp(email, otp);
    bool ok = false;
    
    await res.fold((l) async {
      failure = l;
      AuthLogger.errorLog('confirmSignupCode.failed',
          ctx: {'email': email},
          error: l.message);
      ok = false;
    }, (r) async {
      user = r;
      final data = {
        'email': r.email,
        'full_name': r.fullName,
        'role': r.role,
        if (r.phoneNumber != null) 'phone_number': r.phoneNumber,
        'is_verified': r.isVerified,
      };
      
      AuthLogger.info('confirmSignupCode.success', ctx: {
        'email': email,
        'userId': r.id,
        'role': r.role,
      });
      
      createOrGetProfile.call(r.id, data);
      
      // ✅ FIX: Upload pending legal documents AFTER successful OTP verification
      if (pendingLegalDocBytes != null && pendingLegalDocFileName != null) {
        AuthLogger.info('uploadPendingDocs.start', ctx: {
          'userId': r.id,
          'fileName': pendingLegalDocFileName,
        });
        
        try {
          final uploadResult = await uploadLegalDoc(
            r.id,
            pendingLegalDocFileName!,
            pendingLegalDocBytes!,
          );
          
          if (uploadResult.url != null) {
            AuthLogger.info('uploadPendingDocs.success', ctx: {
              'userId': r.id,
              'url': uploadResult.url,
            });
          } else {
            AuthLogger.warn('uploadPendingDocs.failed', ctx: {
              'userId': r.id,
              'error': uploadResult.error,
            });
          }
        } catch (e, stackTrace) {
          AuthLogger.errorLog('uploadPendingDocs.exception',
              ctx: {'userId': r.id},
              error: e,
              stackTrace: stackTrace);
        } finally {
          // Clear pending documents
          pendingLegalDocBytes = null;
          pendingLegalDocFileName = null;
        }
      }
      
      ok = true;
    });
    
    loading = false;
    notifyListeners();
    return ok;
  }

  Future<bool> confirmRecoveryCode(String email, String otp) async {
    loading = true;
    failure = null;
    notifyListeners();
    final res = await verifyRecoveryOtp(email, otp);
    final ok = res.fold((l) {
      failure = l;
      return false;
    }, (_) => true);
    loading = false;
    notifyListeners();
    return ok;
  }

  Future<bool> setNewPassword(String newPasswordValue) async {
    loading = true;
    failure = null;
    notifyListeners();
    final res = await updatePassword(newPasswordValue);
    final ok = res.fold((l) {
      failure = l;
      return false;
    }, (_) => true);
    loading = false;
    notifyListeners();
    return ok;
  }

  void setRole(UserRole role) {
    selectedRole = role;
    notifyListeners();
  }

  void toggleMode() {
    isLogin = !isLogin;
    notifyListeners();
  }

  void setMode(bool login) {
    isLogin = login;
    notifyListeners();
  }
}
