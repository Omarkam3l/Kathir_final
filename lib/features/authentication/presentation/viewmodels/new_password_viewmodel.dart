import 'package:flutter/foundation.dart';
import '../../../../data/repo/auth_repository_impl.dart';
import '../../../../domain/usecase/update_password_usecase.dart';

class NewPasswordViewModel extends ChangeNotifier {
  final UpdatePasswordUseCase _usecase;
  bool loading = false;
  String? error;
  NewPasswordViewModel({AuthRepositoryImpl? repo})
      : _usecase = UpdatePasswordUseCase(repo ?? AuthRepositoryImpl());

  Future<bool> submit(String newPassword) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _usecase(newPassword);
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
