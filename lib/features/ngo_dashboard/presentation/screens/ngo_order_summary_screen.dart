import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

class NgoOrderSummaryScreen extends StatelessWidget {
  final String orderId;

  const NgoOrderSummaryScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: ResponsiveUtils.iconSize(context, 120),
                  height: ResponsiveUtils.iconSize(context, 120),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: ResponsiveUtils.iconSize(context, 80),
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                Text(
                  'Order Confirmed!',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 28),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Text(
                  'Your pickup request has been sent to the restaurants.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                Text(
                  'You will receive a notification when your order is ready for pickup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/ngo/orders'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'View Orders',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/ngo/home'),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
