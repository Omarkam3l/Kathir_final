import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';

/// Bottom navigation bar for the home screen
class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.bottomNavHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.darkText,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: AppDimensions.iconMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go('/favorites'),
            icon: const Icon(Icons.favorite_border, color: Colors.grey),
          ),
          IconButton(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.grey),
          ),
          IconButton(
            onPressed: () => context.go('/alerts'),
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

