import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/onboarding/data/onboarding_storage.dart';
import 'package:kathir_final/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Root screen at '/'. Shows onboarding on first launch; otherwise redirects to /auth.
/// Handles async load of [OnboardingStorage.hasSeenOnboarding].
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  Future<bool>? _hasSeenFuture;

  @override
  void initState() {
    super.initState();
    _hasSeenFuture = OnboardingStorage.hasSeenOnboarding();
  }

  void _redirectToAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<bool>(
        future: _hasSeenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final hasSeen = snapshot.data ?? false;
          if (hasSeen) {
            _redirectToAuth();
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return const OnboardingScreen();
        },
      ),
    );
  }
}
