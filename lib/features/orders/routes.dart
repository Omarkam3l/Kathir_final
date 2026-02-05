import 'package:go_router/go_router.dart';
import 'presentation/screens/my_orders_screen.dart';
import 'presentation/screens/order_details_screen.dart';
import 'presentation/screens/order_tracking_screen.dart';
import 'presentation/screens/order_summary_screen.dart';

List<GoRoute> ordersRoutes() => [
  GoRoute(path: MyOrdersScreen.routeName, builder: (context, state) => const MyOrdersScreen()),
  GoRoute(path: OrderDetailsScreen.routeName, builder: (context, state) => const OrderDetailsScreen()),
  GoRoute(path: OrderTrackingScreen.routeName, builder: (context, state) => const OrderTrackingScreen()),
  GoRoute(
    path: '/order-summary',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return OrderSummaryScreen(
        items: extra?['items'] ?? [],
        total: extra?['total'] ?? 0.0,
        subtotal: extra?['subtotal'] ?? 0.0,
        deliveryFee: extra?['deliveryFee'] ?? 0.0,
        orderId: extra?['orderId'] ?? '',
      );
    },
  ),
];

