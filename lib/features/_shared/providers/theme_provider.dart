import 'package:flutter/foundation.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = false;
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
