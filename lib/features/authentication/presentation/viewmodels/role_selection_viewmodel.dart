import 'package:flutter/foundation.dart';
import '../../../../core/utils/user_role.dart';
import 'auth_viewmodel.dart';

class RoleSelectionViewModel extends ChangeNotifier {
  final AuthViewModel authViewModel;
  UserRole selected = UserRole.user;
  RoleSelectionViewModel({required this.authViewModel});

  void selectRole(UserRole role) {
    selected = role;
    authViewModel.setRole(role);
    authViewModel.setMode(false);
    notifyListeners();
  }
}
