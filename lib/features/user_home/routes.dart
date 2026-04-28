import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../_shared/screens/main_navigation_screen.dart';
import 'presentation/screens/restaurant_search_screen.dart';
import 'presentation/screens/restaurant_meals_screen.dart';
import 'presentation/screens/all_rush_hour_meals_screen.dart';
import 'presentation/screens/all_meals_screen.dart';
import 'presentation/screens/all_restaurants_screen.dart';
import 'presentation/screens/all_ngos_screen.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'domain/entities/restaurant.dart';
import '../../di/global_injection/app_locator.dart';

List<GoRoute> homeRoutes() => [
  GoRoute(
    path: '/home',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 2), // Home = middle
  ),
  GoRoute(
    path: '/favorites',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
  ),
  GoRoute(
    path: '/favourites',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
  ),
  GoRoute(
    path: '/cart',
    builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
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
    path: '/meals/all',
    builder: (context, state) {
      return ChangeNotifierProvider.value(
        value: AppLocator.I.get<HomeViewModel>(),
        child: Consumer<HomeViewModel>(
          builder: (context, vm, _) => AllMealsScreen(meals: vm.meals),
        ),
      );
    },
  ),
  GoRoute(
    path: '/rush-hour-meals',
    builder: (context, state) => const AllRushHourMealsScreen(),
  ),
  GoRoute(
    path: '/restaurants/all',
    builder: (context, state) => const AllRestaurantsScreen(),
  ),
  GoRoute(
    path: '/ngos/all',
    builder: (context, state) => const AllNGOsScreen(),
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
  GoRoute(
    path: '/ngo/:id',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return NgoDetailsScreen(
        ngoId: state.pathParameters['id']!,
        ngoName: extra?['name'] ?? '',
        logoUrl: extra?['logo'],
        address: extra?['address'],
      );
    },
  ),
];
