import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';

/// Restaurant bottom navigation bar with custom design
/// 
/// Features:
/// - Centered home button with elevated circular design
/// - Underline indicator for active items
/// - Custom layout with 5 items (2 left, 1 center, 2 right)
/// 
/// Navigation items:
/// - Home: /restaurant-dashboard (center, elevated)
/// - Orders: /restaurant-dashboard/orders (left)
/// - Meals: /restaurant-dashboard/meals (left)
/// - Chats: /restaurant-dashboard/chats (right)
/// - Profile: /restaurant-dashboard/profile (right)
class RestaurantBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const RestaurantBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  /// Determines the current index based on the route
  static int getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    
    if (location.contains('/profile')) {
      return 4;
    } else if (location.contains('/leaderboard')) {
      return 3;
    } else if (location.contains('/orders')) {
      return 1;
    } else if (location.contains('/meals')) {
      return 2;
    } else {
      return 0; // Home
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2D241B) : Colors.white;
    final inactiveColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom nav items
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Orders
                Flexible(
                  child: _buildNavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Orders',
                    index: 1,
                    isActive: currentIndex == 1,
                    color: inactiveColor,
                    activeColor: AppColors.primaryGreen,
                  ),
                ),
                
                // Meals
                Flexible(
                  child: _buildNavItem(
                    icon: Icons.restaurant_menu_outlined,
                    activeIcon: Icons.restaurant_menu,
                    label: 'Meals',
                    index: 2,
                    isActive: currentIndex == 2,
                    color: inactiveColor,
                    activeColor: AppColors.primaryGreen,
                  ),
                ),
                
                // Spacer for center button
                SizedBox(width: screenWidth * 0.2),
                
                // Leaderboard
                Flexible(
                  child: _buildNavItem(
                    icon: Icons.leaderboard_outlined,
                    activeIcon: Icons.leaderboard,
                    label: 'Leaderboard',
                    index: 3,
                    isActive: currentIndex == 3,
                    color: inactiveColor,
                    activeColor: AppColors.primaryGreen,
                  ),
                ),
                
                // Profile
                Flexible(
                  child: _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    index: 4,
                    isActive: currentIndex == 4,
                    color: inactiveColor,
                    activeColor: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          
          // Centered elevated Home button
          Positioned(
            top: -20,
            left: screenWidth / 2 - 32,
            child: GestureDetector(
              onTap: () => onTap(0),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: currentIndex == 0 
                      ? AppColors.primaryGreen 
                      : (isDark ? const Color(0xFF1B140D) : const Color(0xFF2D2D2D)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (currentIndex == 0 
                          ? AppColors.primaryGreen 
                          : Colors.black).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
    required Color color,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? activeColor : color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            // Underline indicator
            Container(
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
