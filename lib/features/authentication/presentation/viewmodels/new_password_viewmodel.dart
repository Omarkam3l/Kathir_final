import 'package:flutter/foundation.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../domain/usecases/update_password_usecase.dart';

class NewPasswordViewModel extends ChangeNotifier {
  final UpdatePasswordUseCase _usecase;
  bool loading = false;
  String? error;
  NewPasswordViewModel() : _usecase = AppLocator.I.get<UpdatePasswordUseCase>();

  Future<bool> submit(String newPassword) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _usecase(newPassword);
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
