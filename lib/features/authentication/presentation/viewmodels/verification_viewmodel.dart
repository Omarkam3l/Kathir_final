import 'package:flutter/foundation.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../domain/usecases/verify_recovery_otp_usecase.dart';
import '../../domain/usecases/verify_signup_otp_usecase.dart';

class VerificationViewModel extends ChangeNotifier {
  final VerifyRecoveryOtpUseCase _recovery;
  final VerifySignupOtpUseCase _signup;
  bool loading = false;
  String? error;
  VerificationViewModel()
      : _recovery = AppLocator.I.get<VerifyRecoveryOtpUseCase>(),
        _signup = AppLocator.I.get<VerifySignupOtpUseCase>();

  Future<bool> submitRecovery(String email, String otp) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _recovery(email.trim(), otp.trim());
      res.fold((l) {
        throw Exception(l.message);
      }, (_) {});
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitSignup(String email, String otp) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _signup(email.trim(), otp.trim());
      res.fold((l) {
        throw Exception(l.message);
      }, (_) {});
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
