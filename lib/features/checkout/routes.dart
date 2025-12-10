import 'package:go_router/go_router.dart';
import 'presentation/screens/checkout_screen.dart';
import 'presentation/screens/coupons_screen.dart';
import 'presentation/screens/choose_address_screen.dart';
import 'presentation/screens/payment_method_screen.dart';
import 'presentation/screens/payment_screen.dart';

List<GoRoute> checkoutRoutes() => [
  GoRoute(path: CheckoutScreen.routeName, builder: (context, state) => const CheckoutScreen()),
  GoRoute(path: CouponsScreen.routeName, builder: (context, state) => const CouponsScreen()),
  GoRoute(path: ChooseAddressScreen.routeName, builder: (context, state) => const ChooseAddressScreen()),
  GoRoute(path: PaymentMethodScreen.routeName, builder: (context, state) => const PaymentMethodScreen()),
  GoRoute(path: PaymentScreen.routeName, builder: (context, state) => const PaymentScreen()),
];

