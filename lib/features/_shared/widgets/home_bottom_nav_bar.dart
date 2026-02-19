import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Bottom nav matching user home page design: Home, Favorites, [Cart - elevated], Orders, Profile.
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
                icon: Icons.home,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () {
                  if (onTap != null) {
                    onTap!(0);
                  } else {
                    context.go('/home');
                  }
                },
                filled: true,
              ),
              _NavItem(
                icon: Icons.favorite,
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
              // Elevated Cart Button
              Transform.translate(
                offset: const Offset(0, -24),
                child: GestureDetector(
                  onTap: () {
                    if (onTap != null) {
                      onTap!(2);
                    } else {
                      context.go('/cart');
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_basket,
                      size: 28,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.receipt_long,
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
                icon: Icons.person,
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
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool filled;

  const _NavItem({
    required this.icon,
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
              icon,
              size: 24,
              color: color,
              fill: (selected && filled) ? 1.0 : 0.0,
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
