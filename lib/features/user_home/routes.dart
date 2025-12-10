import 'package:go_router/go_router.dart';
import '../_shared/screens/main_navigation_screen.dart';

List<GoRoute> homeRoutes() => [
  GoRoute(path: '/home', builder: (context, state) => const MainNavigationScreen(initialIndex: 0)),
  GoRoute(path: '/favourites', builder: (context, state) => const MainNavigationScreen(initialIndex: 1)),
  GoRoute(path: '/cart', builder: (context, state) => const MainNavigationScreen(initialIndex: 2)),
  GoRoute(path: '/alerts', builder: (context, state) => const MainNavigationScreen(initialIndex: 3)),
  GoRoute(path: '/profile', builder: (context, state) => const MainNavigationScreen(initialIndex: 4)),
];
