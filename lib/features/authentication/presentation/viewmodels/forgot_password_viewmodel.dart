import 'package:flutter/foundation.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final SendPasswordResetUseCase _usecase;
  bool loading = false;
  String? error;
  ForgotPasswordViewModel()
      : _usecase = AppLocator.I.get<SendPasswordResetUseCase>();

  Future<bool> submit(String email) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _usecase(email.trim());
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
