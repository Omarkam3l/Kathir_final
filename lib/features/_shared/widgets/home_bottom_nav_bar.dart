import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Bottom nav matching user home page design: Favorites, Meals, [Home - elevated], Orders, Profile.
class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A2E22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                label: 'Favorites',
                selected: currentIndex == 1,
                onTap: () {
                  if (onTap != null) {
                    onTap!(1);
                  } else {
                    context.go('/favorites');
                  }
                },
                filled: false,
              ),
              _NavItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
                label: 'Meals',
                selected: currentIndex == 5,
                onTap: () {
                  if (onTap != null) {
                    onTap!(5);
                  } else {
                    context.go('/meals/all');
                  }
                },
                filled: false,
              ),
              // Elevated Home Button
              Transform.translate(
                offset: const Offset(0, -24),
                child: GestureDetector(
                  onTap: () {
                    if (onTap != null) {
                      onTap!(0);
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: currentIndex == 0 ? AppColors.primary : AppColors.darkText,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (currentIndex == 0 ? AppColors.primary : AppColors.darkText)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Orders',
                selected: currentIndex == 3,
                onTap: () {
                  if (onTap != null) {
                    onTap!(3);
                  } else {
                    context.go('/my-orders');
                  }
                },
                filled: false,
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                selected: currentIndex == 4,
                onTap: () {
                  if (onTap != null) {
                    onTap!(4);
                  } else {
                    context.go('/profile');
                  }
                },
                filled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool filled;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primaryGreen
        : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected && activeIcon != null ? activeIcon! : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
