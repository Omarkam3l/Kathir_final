import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';

import 'choose_address_screen.dart';
import 'payment_method_screen.dart';

class PaymentScreen extends StatelessWidget {
  static const routeName = '/payment';
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.white : AppColors.darkText;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : AppColors.white;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Row(
                children: [
                  _diamondButton(
                    context,
                    icon: Icons.arrow_back_ios_new,
                    onTap: () {
                      final router = GoRouter.of(context);
                      if (router.canPop()) {
                        router.pop();
                      } else {
                        router.go('/home');
                      }
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                child: Column(
                  children: [
                    _OptionCard(
                      title: 'Choose Address',
                      onTap: () => Navigator.of(context)
                          .pushNamed(ChooseAddressScreen.routeName),
                      isDarkMode: isDarkMode,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 18),
                    _OptionCard(
                      title: 'Payment Method',
                      onTap: () => Navigator.of(context)
                          .pushNamed(PaymentMethodScreen.routeName),
                      isDarkMode: isDarkMode,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diamondButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(
              icon,
              color: isDarkMode ? AppColors.white : AppColors.darkText,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.onTap,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
  });

  final String title;
  final VoidCallback onTap;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

