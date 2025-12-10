import 'package:go_router/go_router.dart';
import 'presentation/restaurant_detail_screen.dart';

List<GoRoute> restaurantRoutes() => [
  GoRoute(path: RestaurantDetailScreen.routeName, builder: (context, state) => const RestaurantDetailScreen()),
];

