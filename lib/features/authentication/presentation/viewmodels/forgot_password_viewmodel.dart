import 'package:flutter/foundation.dart';
import '../../../../data/repo/auth_repository_impl.dart';
import '../../../../domain/usecase/request_password_reset_usecase.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final RequestPasswordResetUseCase _usecase;
  bool loading = false;
  String? error;
  ForgotPasswordViewModel({AuthRepositoryImpl? repo})
      : _usecase = RequestPasswordResetUseCase(repo ?? AuthRepositoryImpl());

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
