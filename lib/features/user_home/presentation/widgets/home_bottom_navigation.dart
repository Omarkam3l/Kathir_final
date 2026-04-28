import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';

/// Bottom navigation bar for the home screen
class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({super.key});

  String _getCurrentRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/favorites') || location.startsWith('/favourites')) {
      return 'favorites';
    } else if (location.startsWith('/meals')) {
      return 'meals';
    } else if (location.startsWith('/my-orders') || location.startsWith('/orders')) {
      return 'orders';
    } else if (location.startsWith('/profile')) {
      return 'profile';
    }
    return 'home';
  }

  @override
  Widget build(BuildContext context) {
  final currentRoute = _getCurrentRoute(context);

  return ClipRRect(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(22),
    ),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: AppDimensions.bottomNavHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(22),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2), // optional شيك
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
              isActive: currentRoute == 'favorites',
              onTap: () => context.go('/favorites'),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.restaurant_menu_outlined,
              activeIcon: Icons.restaurant_menu,
              isActive: currentRoute == 'meals',
              onTap: () => context.go('/meals/all'),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              isActive: currentRoute == 'home',
              onTap: () => context.go('/home'),
              isCenter: true,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              isActive: currentRoute == 'orders',
              onTap: () => context.go('/my-orders'),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              isActive: currentRoute == 'profile',
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
    bool isCenter = false,
  }) {
    if (isCenter) {
      return IconButton(
        onPressed: onTap,
        icon: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.darkText,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            color: Colors.white,
            size: AppDimensions.iconMedium,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isActive ? activeIcon : icon,
        color: isActive ? AppColors.primary : Colors.grey,
        size: AppDimensions.iconMedium,
      ),
    );
  }
}

