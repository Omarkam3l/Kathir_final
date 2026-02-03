import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';

class NgoBottomNav extends StatelessWidget {
  final int currentIndex;

  const NgoBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.home,
              'Home',
              0,
              isDark,
              () => context.go('/ngo/home'),
            ),
            _buildNavItem(
              context,
              Icons.receipt_long,
              'Orders',
              1,
              isDark,
              () => context.go('/ngo/orders'),
            ),
            _buildMapFab(context, isDark),
            _buildNavItem(
              context,
              Icons.chat_bubble_outline,
              'Chats',
              3,
              isDark,
              () => context.go('/ngo/chats'),
            ),
            _buildNavItem(
              context,
              Icons.person_outline,
              'Profile',
              4,
              isDark,
              () => context.go('/ngo/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isDark,
    VoidCallback onTap,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? AppColors.primaryGreen
        : (isDark ? Colors.grey[500] : Colors.grey[400]);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFab(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.go('/ngo/map'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: currentIndex == 2
              ? AppColors.primaryGreen
              : (isDark ? Colors.black : const Color(0xFF0D1B12)),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.map,
          color: currentIndex == 2
              ? Colors.black
              : (isDark ? Colors.white : Colors.white),
          size: 24,
        ),
      ),
    );
  }
}
