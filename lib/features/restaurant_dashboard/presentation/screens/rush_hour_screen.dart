import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/services/rush_hour_service.dart';
import '../viewmodels/rush_hour_viewmodel.dart';
import '../widgets/rush_hour_active_info_widget.dart';
import '../widgets/rush_hour_discount_card_widget.dart';
import '../widgets/rush_hour_header_widget.dart';

/// Rush Hour Settings Screen
/// 
/// Allows restaurants to activate/deactivate rush hour with automatic
/// 1-hour duration and countdown timer.
class RushHourScreen extends StatelessWidget {
  const RushHourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RushHourViewModel(
        RushHourService(Supabase.instance.client),
      )..loadRushHourConfig(),
      child: const _RushHourScreenContent(),
    );
  }
}

class _RushHourScreenContent extends StatelessWidget {
  const _RushHourScreenContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewModel = context.watch<RushHourViewModel>();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF221910) : const Color(0xFFF8F7F6),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Rush Hour Settings'),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF2D241B) : Colors.white,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RushHourHeaderWidget(
                    isActive: viewModel.isActive,
                    onToggle: () => viewModel.toggleActive(),
                    isDark: isDark,
                  ),
                  if (viewModel.isRushHourActive) ...[
                    const SizedBox(height: 24),
                    RushHourActiveInfoWidget(
                      startTime: viewModel.startTime!,
                      endTime: viewModel.endTime!,
                      remainingSeconds: viewModel.remainingSeconds,
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: 16),
                  RushHourDiscountCardWidget(
                    discountPercentage: viewModel.discountPercentage,
                    onChanged: (value) => viewModel.setDiscountPercentage(value),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(context, viewModel, isDark),
                  if (viewModel.config?.activeNow == true) ...[
                    const SizedBox(height: 16),
                    _buildActiveNowBanner(isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    RushHourViewModel viewModel,
    bool isDark,
  ) {
    return ElevatedButton(
      onPressed: viewModel.isSaving
          ? null
          : () async {
              final message = await viewModel.saveSettings();
              if (context.mounted && message != null) {
                final isError = message.contains('Error') ||
                    message.contains('Failed') ||
                    message.contains('Exception');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: isError ? Colors.red : Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: viewModel.isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Save Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildActiveNowBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rush Hour Active Now!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All meals are showing rush hour discount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
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
