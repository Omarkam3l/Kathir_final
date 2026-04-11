import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

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
              width: ResponsiveUtils.iconSize(context, 100),
              height: ResponsiveUtils.iconSize(context, 100),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: ResponsiveUtils.iconSize(context, 50),
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),
            
            // Loading Indicator
            SizedBox(
              width: ResponsiveUtils.iconSize(context, 40),
              height: ResponsiveUtils.iconSize(context, 40),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            
            // Loading Text
            Text(
              'Loading your account...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: ResponsiveUtils.fontSize(context, 16),
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
