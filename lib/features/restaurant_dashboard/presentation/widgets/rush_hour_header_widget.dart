import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Rush Hour Header Widget
/// 
/// Displays the Rush Hour title, description, and ON/OFF toggle switch.
class RushHourHeaderWidget extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;
  final bool isDark;

  const RushHourHeaderWidget({
    super.key,
    required this.isActive,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D241B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Rush Hour',
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1B140D),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryGreen.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isActive ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? AppColors.primaryGreen
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
