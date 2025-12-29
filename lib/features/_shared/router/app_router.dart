import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_dashboard_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_dashboard_screen.dart';
import 'package:kathir_final/features/splash/presentation/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import '../../authentication/presentation/blocs/auth_provider.dart';
import '../../meals/presentation/screens/meal_detail.dart';
import '../../user_home/domain/entities/meal_offer.dart';
import '../../user_home/domain/entities/restaurant.dart';
import '../../checkout/routes.dart';
import '../../orders/routes.dart';
import '../../restaurants/routes.dart';
import '../../user_home/routes.dart';
import '../../profile/routes.dart';
import '../../authentication/routes.dart';

class RouteNames {
  static const splash = 'splash';
  static const auth = 'auth';
  static const role = 'role';
  static const home = 'home';
  static const restaurantDashboard = 'restaurant_dashboard';
  static const ngoDashboard = 'ngo_dashboard';
  static const adminDashboard = 'admin_dashboard';
  static const product = 'product';
  static const cart = 'cart';
  static const checkout = 'checkout';
  static const settings = 'settings';
  static const profile = 'profile';
}

class AppRouter {
  final AuthProvider auth;
  final RouteObserver<PageRoute> observer = RouteObserver<PageRoute>();
  AppRouter({required this.auth});

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    observers: [observer],
    redirect: (context, state) {
      if (auth.isPasswordRecovery && state.matchedLocation != '/new-password') {
        return '/new-password';
      }
      final loggedIn = auth.isLoggedIn;
      final signingFlow = state.matchedLocation == '/role' ||
          state.matchedLocation == '/auth' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/new-password';

      // Allow splash screen at '/' if not logged in
      if (!loggedIn && state.matchedLocation == '/') {
        return null;
      }

      if (!loggedIn && state.matchedLocation != '/' && !signingFlow) {
        return '/auth';
      }
      if (loggedIn && (signingFlow || state.matchedLocation == '/')) {
        final role = auth.user?.role;
        if (role == 'restaurant') {
          return '/restaurant-dashboard';
        } else if (role == 'organization') {
          return '/ngo-dashboard';
        } else if (role == 'admin') {
          return '/admin-dashboard';
        }
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        name: RouteNames.splash,
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: RouteNames.restaurantDashboard,
        path: '/restaurant-dashboard',
        builder: (context, state) => const RestaurantDashboardScreen(),
      ),
      GoRoute(
        name: RouteNames.ngoDashboard,
        path: '/ngo-dashboard',
        builder: (context, state) => const NgoDashboardScreen(),
      ),
      GoRoute(
        name: RouteNames.adminDashboard,
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        name: RouteNames.product,
        path: '/meal/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MealOffer) {
            return ProductDetailPage(product: extra);
          }
          final id = state.pathParameters['id'] ?? '';
          return ProductDetailPage(
              product: MealOffer(
            id: id,
            title: '',
            location: '',
            imageUrl: '',
            originalPrice: 0,
            donationPrice: 0,
            quantity: 0,
            expiry: DateTime.now(),
            restaurant: const Restaurant(id: '', name: '', rating: 0),
          ));
        },
      ),
      ...checkoutRoutes(),
      ...restaurantRoutes(),
      ...homeRoutes(),
      ...profileRoutes(),
      ...authRoutes(),
      ...ordersRoutes(),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );

  static GoRouter of(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: true);
    return AppRouter(auth: auth).router;
  }
}

extension NavigationHelpers on BuildContext {
  void pushRoute(String location, {Object? extra}) {
    GoRouter.of(this).push(location, extra: extra);
  }

  void pushRouteNamed(String name,
      {Map<String, String> pathParams = const {},
      Map<String, String> queryParams = const {},
      Object? extra}) {
    final router = GoRouter.of(this);
    router.pushNamed(name,
        pathParameters: pathParams, queryParameters: queryParams, extra: extra);
  }

  void popRoute() => GoRouter.of(this).pop();
}
