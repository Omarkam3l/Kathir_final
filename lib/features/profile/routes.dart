import 'package:go_router/go_router.dart';
import 'presentation/screens/profile_overview_screen.dart';
import 'presentation/screens/user_profile_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/change_password_screen.dart';
import '../checkout/presentation/screens/choose_address_screen.dart';
import '../orders/presentation/screens/my_orders_screen.dart';
import 'presentation/screens/add_card_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/help_screen.dart';
import 'presentation/screens/privacy_screen.dart';
import 'presentation/screens/about_screen.dart';

List<GoRoute> profileRoutes() => [
  GoRoute(path: ProfileOverviewScreen.routeName, builder: (context, state) => const ProfileOverviewScreen()),
  GoRoute(path: '/profile/user', builder: (context, state) => const UserProfileScreen()),
  GoRoute(path: '/profile/settings', builder: (context, state) => const SettingsScreen()),
  GoRoute(path: '/profile/change-password', builder: (context, state) => const ChangePasswordScreen()),
  GoRoute(path: '/profile/saved-addresses', builder: (context, state) => const ChooseAddressScreen()),
  GoRoute(path: '/profile/order-history', builder: (context, state) => const MyOrdersScreen()),
  GoRoute(path: '/profile/cards', builder: (context, state) => const AddCardScreen()),
  GoRoute(path: '/profile/add-card', builder: (context, state) => const AddCardScreen()),
  GoRoute(path: '/profile/alerts', builder: (context, state) => const NotificationsScreen()),
  GoRoute(path: '/profile/notifications', builder: (context, state) => const NotificationsScreen()),
  GoRoute(path: '/profile/help', builder: (context, state) => const HelpScreen()),
  GoRoute(path: '/profile/privacy', builder: (context, state) => const PrivacyScreen()),
  GoRoute(path: AboutScreen.routeName, builder: (context, state) => const AboutScreen()),
];

