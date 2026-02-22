import 'package:go_router/go_router.dart';
import '../_shared/screens/main_navigation_screen.dart';
import 'presentation/screens/restaurant_search_screen.dart';
import 'presentation/screens/restaurant_meals_screen.dart';
import 'domain/entities/restaurant.dart';

List<GoRoute> homeRoutes() => [
  GoRoute(
    path: '/home',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
  ),
  GoRoute(
    path: '/favorites',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
  ),
  GoRoute(
    path: '/favourites',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
  ),
  GoRoute(
    path: '/cart',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
  ),
  GoRoute(
    path: '/my-orders',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
  ),
  GoRoute(
    path: '/profile',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 4),
  ),
  GoRoute(
    path: '/restaurant-search',
    builder: (context, state) => const RestaurantSearchScreen(),
  ),
  GoRoute(
    path: '/restaurant/:id/meals',
    builder: (context, state) {
      final restaurant = state.extra as Restaurant;
      return RestaurantMealsScreen(restaurant: restaurant);
    },
  ),
];
