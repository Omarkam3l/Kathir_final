import 'package:flutter/foundation.dart';
import '../../../../data/repo/auth_repository_impl.dart';
import '../../../../domain/usecase/verify_otp_usecase.dart';

class VerificationViewModel extends ChangeNotifier {
  final VerifyOtpUseCase _usecase;
  bool loading = false;
  String? error;
  VerificationViewModel({AuthRepositoryImpl? repo})
      : _usecase = VerifyOtpUseCase(repo ?? AuthRepositoryImpl());

  Future<bool> submit(String email, String otp) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _usecase(email.trim(), otp.trim());
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
