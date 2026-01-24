import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/user_role.dart';
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
import '../../domain/usecases/update_profile_legal_docs_usecase.dart';

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
  final UpdateProfileLegalDocsUseCase updateProfileLegalDocs;

  bool loading = false;
  Failure? failure;
  UserEntity? user;

  bool isLogin = true;
  UserRole? selectedRole;

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
    required this.updateProfileLegalDocs,
  });

  Future<bool> login(String email, String password) async {
    loading = true;
    notifyListeners();
    final res = await signIn(email, password);
    final ok = res.fold((l) {
      failure = l;
      return false;
    }, (r) {
      user = r;
      final data = {
        'email': r.email,
        'full_name': r.fullName,
        'role': r.role,
        if (r.phoneNumber != null) 'phone_number': r.phoneNumber,
        if (r.organizationName != null) 'organization_name': r.organizationName,
        'is_verified': r.isVerified,
      };
      // Fire and forget profile upsert; rely on RLS with auth.uid()
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
    final res = await signUp(role: role, fullName: fullName, email: email, password: password, organizationName: organizationName, phone: phone);
    final ok = res.fold((l) {
      failure = l;
      return false;
    }, (r) {
      user = r;
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

  Future<String?> uploadLegalDoc(String userId, String fileName, List<int> bytes) async {
    final res = await uploadDocs(userId, fileName, bytes);
    final url = res.fold((l) => null, (r) => r);
    if (url != null) {
      try {
        await updateProfileLegalDocs(userId, url);
      } catch (_) {}
    }
    return url;
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
    final res = await verifySignupOtp(email, otp);
    final ok = res.fold((l) {
      failure = l;
      return false;
    }, (r) {
      user = r;
      final data = {
        'email': r.email,
        'full_name': r.fullName,
        'role': r.role,
        if (r.phoneNumber != null) 'phone_number': r.phoneNumber,
        if (r.organizationName != null) 'organization_name': r.organizationName,
        'is_verified': r.isVerified,
      };
      createOrGetProfile.call(r.id, data);
      return true;
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
