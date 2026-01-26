import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

/// Bottom nav matching design: Home, Map, [Cart - elevated], Orders, Profile.
class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.white;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    const selected = AppColors.primary;
    const unselected = AppColors.grey;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
            selectedColor: selected,
            unselectedColor: unselected,
          ),
          _NavItem(
            icon: Icons.map_outlined,
            label: 'Map',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
            selectedColor: selected,
            unselectedColor: unselected,
          ),
          _CenterCartButton(onTap: () => onTap(2)),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
            selectedColor: selected,
            unselectedColor: unselected,
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            selected: currentIndex == 4,
            onTap: () => onTap(4),
            selectedColor: selected,
            unselectedColor: unselected,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterCartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterCartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_basket,
              size: 28,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
