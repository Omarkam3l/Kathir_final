import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../authentication/presentation/blocs/auth_provider.dart';
import '../screens/splash_screen.dart';
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
      final loggedIn = auth.isLoggedIn;
      final signingFlow = state.matchedLocation == '/role' || state.matchedLocation == '/auth';
      if (!loggedIn && state.matchedLocation == '/') {
        return '/auth';
      }
      if (!loggedIn && state.matchedLocation != '/' && !signingFlow) {
        return '/auth';
      }
      if (loggedIn && (signingFlow || state.matchedLocation == '/')) {
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
