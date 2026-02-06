import 'package:go_router/go_router.dart';
import 'presentation/screens/my_orders_screen_new.dart';
import 'presentation/screens/order_details_screen.dart';
import 'presentation/screens/order_tracking_screen.dart';
import 'presentation/screens/order_qr_screen.dart';
import 'presentation/screens/order_summary_screen.dart';

List<GoRoute> ordersRoutes() => [
  GoRoute(
    path: '/my-orders',
    builder: (context, state) => const MyOrdersScreenNew(),
  ),
  GoRoute(
    path: '/order-details',
    builder: (context, state) => const OrderDetailsScreen(),
  ),
  GoRoute(
    path: '/order-tracking/:orderId',
    builder: (context, state) {
      final orderId = state.pathParameters['orderId'] ?? '';
      return OrderTrackingScreen(orderId: orderId);
    },
  ),
  GoRoute(
    path: '/order-qr/:orderId',
    builder: (context, state) {
      final orderId = state.pathParameters['orderId'] ?? '';
      return OrderQRScreen(orderId: orderId);
    },
  ),
  GoRoute(
    path: '/order-summary/:orderId',
    builder: (context, state) {
      final orderId = state.pathParameters['orderId'] ?? '';
      return OrderSummaryScreen(orderId: orderId);
    },
  ),
];

