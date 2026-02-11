import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_home_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_map_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_profile_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_meal_detail_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_chat_list_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_chat_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/screens/ngo_notifications_screen.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/viewmodels/ngo_home_viewmodel.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/viewmodels/ngo_map_viewmodel.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/viewmodels/ngo_profile_viewmodel.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/viewmodels/ngo_chat_list_viewmodel.dart';
import 'package:kathir_final/features/ngo_dashboard/presentation/viewmodels/ngo_chat_viewmodel.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_dashboard_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/meals_list_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_orders_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_order_detail_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/add_meal_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/meal_details_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/edit_meal_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_profile_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_chat_list_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_chat_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_leaderboard_screen.dart';
import 'package:kathir_final/features/restaurant_dashboard/presentation/screens/restaurant_surplus_settings_screen.dart';
import 'package:kathir_final/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:provider/provider.dart';
import '../../authentication/presentation/blocs/auth_provider.dart';
import '../../authentication/presentation/screens/pending_approval_screen.dart';
import '../../authentication/presentation/screens/auth_splash_screen.dart';
import '../../meals/presentation/screens/meal_detail.dart';
import '../../meals/presentation/screens/meal_detail_new.dart';
import '../../user_home/presentation/screens/all_meals_screen.dart';
import '../../user_home/presentation/viewmodels/favorites_viewmodel.dart';
import '../../user_home/domain/entities/meal_offer.dart';
import '../../user_home/domain/entities/meal.dart';
import '../../user_home/domain/entities/restaurant.dart';
import '../../checkout/routes.dart';
import '../../orders/routes.dart';
import '../../restaurants/routes.dart';
import '../../user_home/routes.dart';
import '../../profile/routes.dart';
import '../../authentication/routes.dart';

class RouteNames {
  static const onboarding = 'onboarding';
  static const auth = 'auth';
  static const role = 'role';
  static const home = 'home';
  static const restaurantDashboard = 'restaurant_dashboard';
  static const ngoDashboard = 'ngo_dashboard';
  static const adminDashboard = 'admin_dashboard';
  static const pendingApproval = 'pending_approval';
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
      final location = state.matchedLocation;
      final isInitialized = auth.isInitialized;
      final isLoggedIn = auth.isLoggedIn;
      final user = auth.user;
      
      // Define route categories for cleaner logic
      final isAuthSplash = location == '/auth-splash';
      final isOnboarding = location == '/';
      final isAuthFlow = location == '/role' ||
          location == '/auth' ||
          location == '/login' ||
          location == '/forgot-password' ||
          location == '/verify-otp' ||
          location == '/new-password';
      final isPendingApproval = location == '/pending-approval';
      
      // RULE 1: Password recovery takes precedence
      if (auth.isPasswordRecovery && location != '/new-password') {
        return '/new-password';
      }
      
      // RULE 2: Show splash screen while initializing (only if logged in)
      // This prevents redirect loops on logout
      if (!isInitialized && isLoggedIn && !isAuthSplash) {
        return '/auth-splash';
      }
      
      // RULE 3: Not logged in - allow onboarding and auth flows
      if (!isLoggedIn) {
        // Allow onboarding screen
        if (isOnboarding) return null;
        
        // Allow auth flow screens
        if (isAuthFlow) return null;
        
        // Redirect everything else to auth
        return '/auth';
      }
      
      // RULE 4: Logged in and initialized - route based on user state
      if (isLoggedIn && isInitialized) {
        final role = user?.role;
        
        // If on auth flow or onboarding, redirect to appropriate dashboard
        if (isAuthFlow || isOnboarding) {
          // Check approval status (now guaranteed to be accurate)
          if (user != null && user.needsApproval) {
            // If approval status is still unknown, stay on splash
            if (user.isApprovalStatusUnknown) {
              return '/auth-splash';
            }
            
            // If not approved, go to pending screen
            if (!user.isApproved) {
              return '/pending-approval';
            }
          }
          
          // Approved users or users who don't need approval - go to dashboard
          if (role == 'restaurant') {
            return '/restaurant-dashboard';
          } else if (role == 'ngo') {
            return '/ngo/home';
          } else if (role == 'admin') {
            return '/admin-dashboard';
          }
          return '/home';
        }
        
        // If trying to access pending approval but actually approved, redirect
        if (isPendingApproval && user != null) {
          if (!user.needsApproval || user.isApproved) {
            if (role == 'restaurant') {
              return '/restaurant-dashboard';
            } else if (role == 'ngo') {
              return '/ngo/home';
            } else if (role == 'admin') {
              return '/admin-dashboard';
            }
            return '/home';
          }
        }
        
        // RULE 5: Role-based access control - prevent unauthorized access
        // Restaurant trying to access NGO routes
        if (role == 'restaurant' && (location.startsWith('/ngo') || location == '/ngo-dashboard')) {
          return '/restaurant-dashboard';
        }
        
        // NGO trying to access Restaurant routes
        if (role == 'ngo' && (location.startsWith('/restaurant') || location == '/restaurant-dashboard')) {
          return '/ngo/home';
        }
        
        // Restaurant trying to access User routes
        if (role == 'restaurant' && (
          location.startsWith('/home') || 
          location.startsWith('/meal/') || 
          location.startsWith('/meals/') ||
          location.startsWith('/cart') || 
          location.startsWith('/checkout') ||
          location.startsWith('/payment') ||
          location.startsWith('/order-summary') ||
          location.startsWith('/orders') || 
          (location.startsWith('/profile') && location != '/profile/change-password') ||
          location.startsWith('/favorites') ||
          location.startsWith('/favourites') ||
          location.startsWith('/my-orders')
        )) {
          return '/restaurant-dashboard';
        }
        
        // NGO trying to access User routes
        if (role == 'ngo' && (
          location.startsWith('/home') || 
          location.startsWith('/meal/') || 
          location.startsWith('/meals/') ||
          location.startsWith('/cart') || 
          location.startsWith('/checkout') ||
          location.startsWith('/payment') ||
          location.startsWith('/order-summary') ||
          location.startsWith('/orders') || 
          (location.startsWith('/profile') && location != '/profile/change-password') ||
          location.startsWith('/favorites') ||
          location.startsWith('/favourites') ||
          location.startsWith('/my-orders')
        )) {
          return '/ngo/home';
        }
        
        // User trying to access Restaurant routes
        if (role == 'user' && (location.startsWith('/restaurant') || location == '/restaurant-dashboard')) {
          return '/home';
        }
        
        // User trying to access NGO routes
        if (role == 'user' && (location.startsWith('/ngo') || location == '/ngo-dashboard')) {
          return '/home';
        }
        
        // Admin trying to access other dashboards
        if (role == 'admin' && (location.startsWith('/restaurant') || location.startsWith('/ngo') || location == '/restaurant-dashboard' || location == '/ngo-dashboard')) {
          return '/admin-dashboard';
        }
        
        // Non-admin trying to access admin dashboard
        if (role != 'admin' && (location.startsWith('/admin') || location == '/admin-dashboard')) {
          if (role == 'restaurant') {
            return '/restaurant-dashboard';
          } else if (role == 'ngo') {
            return '/ngo/home';
          }
          return '/home';
        }
      }
      
      // Allow navigation to current location
      return null;
    },

    routes: [
      GoRoute(
        name: RouteNames.onboarding,
        path: '/',
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      GoRoute(
        path: '/auth-splash',
        builder: (context, state) => const AuthSplashScreen(),
      ),
      GoRoute(
        name: RouteNames.restaurantDashboard,
        path: '/restaurant-dashboard',
        builder: (context, state) => const RestaurantDashboardScreen(),
      ),
      GoRoute(
        path: '/restaurant-dashboard/meals',
        builder: (context, state) => const MealsListScreen(),
      ),
      GoRoute(
        path: '/restaurant-dashboard/orders',
        builder: (context, state) => const RestaurantOrdersScreen(),
      ),
      GoRoute(
        path: '/restaurant-dashboard/order-detail/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return RestaurantOrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/restaurant-dashboard/add-meal',
        builder: (context, state) => const AddMealScreen(),
      ),
      GoRoute(
        path: '/restaurant-dashboard/meal/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MealDetailsScreen(mealId: id);
        },
      ),
      GoRoute(
        path: '/restaurant-dashboard/edit-meal/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditMealScreen(mealId: id);
        },
      ),
      GoRoute(
        path: '/restaurant-dashboard/profile',
        builder: (context, state) => const RestaurantProfileScreen(),
      ),
      GoRoute(
        path: '/restaurant/chats',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => NgoChatListViewModel(),
          child: const RestaurantChatListScreen(),
        ),
      ),
      GoRoute(
        path: '/restaurant/chat/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final otherPartyName = extra?['otherPartyName'] ?? 'NGO';
          
          return ChangeNotifierProvider(
            create: (_) => NgoChatViewModel(
              conversationId: conversationId,
              restaurantName: otherPartyName,
            ),
            child: RestaurantChatScreen(
              conversationId: conversationId,
              otherPartyName: otherPartyName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/restaurant-dashboard/leaderboard',
        builder: (context, state) => const RestaurantLeaderboardScreen(),
      ),
      GoRoute(
        path: '/restaurant-dashboard/surplus-settings',
        builder: (context, state) => const RestaurantSurplusSettingsScreen(),
      ),
      // NGO Dashboard Routes
      GoRoute(
        name: RouteNames.ngoDashboard,
        path: '/ngo-dashboard',
        redirect: (context, state) => '/ngo/home',
      ),
      GoRoute(
        path: '/ngo/home',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => NgoHomeViewModel(),
          child: const NgoHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/ngo/map',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => NgoMapViewModel(),
          child: const NgoMapScreen(),
        ),
      ),
      GoRoute(
        path: '/ngo/profile',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => NgoProfileViewModel(),
          child: const NgoProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/ngo/orders',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'NGO Orders - Coming Soon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/ngo-notifications',
        builder: (context, state) => const NgoNotificationsScreen(),
      ),
      GoRoute(
        path: '/ngo/chats',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => NgoChatListViewModel(),
          child: const NgoChatListScreen(),
        ),
      ),
      GoRoute(
        path: '/ngo/chat/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final restaurantName = extra?['restaurantName'] ?? 'Restaurant';
          
          return ChangeNotifierProvider(
            create: (_) => NgoChatViewModel(
              conversationId: conversationId,
              restaurantName: restaurantName,
            ),
            child: NgoChatScreen(
              conversationId: conversationId,
              restaurantName: restaurantName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/ngo/meal/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Meal) {
            return NgoMealDetailScreen(meal: extra);
          }
          // Fallback if no meal data provided
          return const Scaffold(
            body: Center(
              child: Text('Meal not found'),
            ),
          );
        },
      ),
      GoRoute(
        name: RouteNames.adminDashboard,
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        name: RouteNames.pendingApproval,
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // All meals route
      GoRoute(
        path: '/meals/all',
        builder: (context, state) {
          final extra = state.extra as List<MealOffer>?;
          return AllMealsScreen(meals: extra ?? []);
        },
      ),

      GoRoute(
        name: RouteNames.product,
        path: '/meal/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MealOffer) {
            return ChangeNotifierProvider(
              create: (_) => FavoritesViewModel()..loadFavorites(),
              child: MealDetailScreen(product: extra),
            );
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
