import 'package:shared_preferences/shared_preferences.dart';

/// Key for persisting whether the user has completed onboarding (first-launch only).
const String _keyOnboardingComplete = 'has_seen_onboarding';

/// Handles persistence of onboarding completion for first-launch logic.
/// No business logic; only storage read/write.
class OnboardingStorage {
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }
}
