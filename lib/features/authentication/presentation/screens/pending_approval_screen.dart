import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../blocs/auth_provider.dart';

/// Screen shown to restaurant/NGO users whose accounts are pending approval.
class PendingApprovalScreen extends StatelessWidget {
  static const routeName = '/pending-approval';
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final isRestaurant = user?.role == 'rest';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 64,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Account Pending Approval',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                isRestaurant
                    ? 'Your restaurant account is being reviewed by our team. '
                        'This usually takes 1-2 business days.'
                    : 'Your organization account is being reviewed by our team. '
                        'This usually takes 1-2 business days.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // What happens next section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep(context, '1', 'Our team reviews your details', isDark),
                    const SizedBox(height: 8),
                    _buildStep(context, '2', 'You receive an email notification', isDark),
                    const SizedBox(height: 8),
                    _buildStep(context, '3', 'Start using all features!', isDark),
                  ],
                ),
              ),
              const Spacer(),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthProvider>().signOut();
                    context.go('/auth');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
          ),
        ),
      ],
    );
  }
}
