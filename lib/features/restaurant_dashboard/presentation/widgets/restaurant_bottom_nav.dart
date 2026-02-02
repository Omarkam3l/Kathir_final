import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';

/// Restaurant bottom navigation bar with route-aware selection
/// 
/// This widget uses go_router to navigate between screens and
/// automatically highlights the current tab based on the route.
/// 
/// Navigation items:
/// - Home: /restaurant-dashboard
/// - Meals: /restaurant-dashboard/meals
/// - Orders: /restaurant-dashboard/orders
/// - Rank: /restaurant-dashboard/leaderboard
/// - Profile: /restaurant-dashboard/profile
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
    
    if (location.contains('/leaderboard')) {
      return 3;
    } else if (location.contains('/profile')) {
      return 4;
    } else if (location.contains('/orders')) {
      return 2;
    } else if (location.contains('/meals')) {
      return 1;
    } else {
      return 0; // Home
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Meals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Rank',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
