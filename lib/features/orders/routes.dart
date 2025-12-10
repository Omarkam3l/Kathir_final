import 'package:go_router/go_router.dart';
import 'presentation/screens/my_orders_screen.dart';
import 'presentation/screens/order_details_screen.dart';
import 'presentation/screens/order_tracking_screen.dart';

List<GoRoute> ordersRoutes() => [
  GoRoute(path: MyOrdersScreen.routeName, builder: (context, state) => const MyOrdersScreen()),
  GoRoute(path: OrderDetailsScreen.routeName, builder: (context, state) => const OrderDetailsScreen()),
  GoRoute(path: OrderTrackingScreen.routeName, builder: (context, state) => const OrderTrackingScreen()),
];

