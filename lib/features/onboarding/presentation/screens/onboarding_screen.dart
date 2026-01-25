import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/onboarding/data/onboarding_storage.dart';
import 'package:kathir_final/features/onboarding/presentation/widgets/onboarding_page_1.dart';
import 'package:kathir_final/features/onboarding/presentation/widgets/onboarding_page_2.dart';
import 'package:kathir_final/features/onboarding/presentation/widgets/onboarding_page_3.dart';
import 'package:kathir_final/features/authentication/presentation/viewmodels/auth_viewmodel.dart';

/// 3-page onboarding flow. PageView with dots; on completion navigates to /auth.
/// No business logic in UI: completion is delegated to [OnboardingStorage].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeAndGoToAuth() async {
    await OnboardingStorage.setOnboardingComplete();
    if (!mounted) return;
    context.go('/auth');
  }

  Future<void> _goToSignIn() async {
    await OnboardingStorage.setOnboardingComplete();
    if (!mounted) return;
    final vm = Provider.of<AuthViewModel>(context, listen: false);
    vm.setMode(true); // login
    context.go('/auth');
  }

  Future<void> _goToSignUp() async {
    await OnboardingStorage.setOnboardingComplete();
    if (!mounted) return;
    final vm = Provider.of<AuthViewModel>(context, listen: false);
    vm.setMode(false); // signup
    context.go('/auth');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          OnboardingPage1(
            onNext: _nextPage,
            onLogIn: _completeAndGoToAuth,
          ),
          OnboardingPage2(
            onBack: _previousPage,
            onSkip: _completeAndGoToAuth,
            onNext: _nextPage,
          ),
          OnboardingPage3(
            onBack: _previousPage,
            onSignUp: _goToSignUp,
            onSignIn: _goToSignIn,
          ),
        ],
      ),
    );
  }
}
