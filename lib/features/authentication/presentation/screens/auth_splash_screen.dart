import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

/// Splash screen shown while initializing authentication state
/// This prevents race conditions by ensuring user profile is loaded
/// before any routing decisions are made
class AuthSplashScreen extends StatelessWidget {
  static const routeName = '/auth-splash';
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 50,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 32),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
            const SizedBox(height: 24),
            
            // Loading Text
            Text(
              'Loading your account...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
