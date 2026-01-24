import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/onboarding/presentation/widgets/onboarding_pagination_dots.dart';

/// Page 3: "Join the Movement" — central icon circle, Sign Up, Sign In.
class OnboardingPage3 extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  const OnboardingPage3({
    super.key,
    required this.onBack,
    required this.onSignUp,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.darkText;
    final mutedColor = AppColors.grey;

    return SafeArea(
      child: Column(
        children: [
          // Top: Back only
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back, color: textColor, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.white.withOpacity(0.1)
                        : AppColors.black.withOpacity(0.05),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          // Center: gradient circle + volunteer_activism + floating badges
          Expanded(
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Blur behind
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 80,
                        ),
                      ],
                    ),
                  ),
                  // Main circle
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.surfaceDark,
                                AppColors.backgroundDark,
                              ]
                            : [
                                AppColors.primary.withOpacity(0.12),
                                AppColors.primarySoft.withOpacity(0.08),
                              ],
                      ),
                      border: Border.all(
                        color: AppColors.white.withOpacity(isDark ? 0.1 : 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      size: 100,
                      color: AppColors.primary,
                    ),
                  ),
                  // Floating: restaurant (top-right)
                  Positioned(
                    top: 0,
                    right: 24,
                    child: _FloatingBadge(
                      icon: Icons.restaurant,
                      color: AppColors.primary,
                    ),
                  ),
                  // Floating: diversity_1 (bottom-left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _FloatingBadge(
                      icon: Icons.diversity_1,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Title, subtitle, dots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  'Join the Movement',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Connecting users, restaurants, and NGOs to distribute surplus food. Together, let's end hunger and waste.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                OnboardingPaginationDots(pageCount: 3, currentPage: 2),
              ],
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.darkText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.white.withOpacity(0.05) : AppColors.dividerLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
