import 'package:flutter/material.dart';
import '../../user_home/presentation/screens/home_screen.dart';
import '../../favorites/presentation/screens/favourites_screen.dart';
import '../../cart/presentation/screens/cart_screen.dart';
import '../../profile/presentation/screens/notifications_screen.dart';
<<<<<<< HEAD
import '../../profile/presentation/screens/profile_overview_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
=======
import '../../profile/presentation/screens/user_profile_screen_new.dart';
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f

class NavItem {
  final String key;
  final IconData icon;
  final String label;
  final Widget Function() builder;
  const NavItem({required this.key, required this.icon, required this.label, required this.builder});
}

class DrawerItem {
  final IconData icon;
  final String label;
  final String path;
  const DrawerItem({required this.icon, required this.label, required this.path});
}

class UiConfig {
  static List<NavItem> navItems() => const [
        NavItem(key: 'home', icon: Icons.home, label: 'Home', builder: HomeScreen.new),
        NavItem(key: 'favourites', icon: Icons.favorite_border, label: 'Favourites', builder: FavouritesScreen.new),
        NavItem(key: 'cart', icon: Icons.shopping_cart_outlined, label: 'Cart', builder: CartScreen.new),
        NavItem(key: 'alerts', icon: Icons.notifications_none, label: 'Alerts', builder: NotificationsScreen.new),
        NavItem(key: 'profile', icon: Icons.person_outline, label: 'Profile', builder: UserProfileScreenNew.new),
      ];

<<<<<<< HEAD
  static List<DrawerItem> drawerItems(AppLocalizations l10n) => [
        DrawerItem(icon: Icons.person, label: l10n.drawerMyProfile, path: ProfileOverviewScreen.routeName),
        DrawerItem(icon: Icons.favorite, label: l10n.drawerMyFavourites, path: '/favourites'),
        DrawerItem(icon: Icons.shopping_cart, label: l10n.drawerCart, path: '/cart'),
        DrawerItem(icon: Icons.notifications, label: l10n.drawerNotification, path: '/alerts'),
        DrawerItem(icon: Icons.credit_card, label: l10n.drawerMyCards, path: '/profile/cards'),
        DrawerItem(icon: Icons.settings, label: l10n.drawerSettings, path: '/profile/settings'),
        DrawerItem(icon: Icons.map, label: l10n.drawerSavedAddresses, path: '/profile/saved-addresses'),
        DrawerItem(icon: Icons.lock_outline, label: l10n.drawerChangePassword, path: '/profile/change-password'),
        DrawerItem(icon: Icons.history, label: l10n.drawerOrderHistory, path: '/profile/order-history'),
        DrawerItem(icon: Icons.help_center, label: l10n.drawerHelp, path: '/profile/help'),
        DrawerItem(icon: Icons.privacy_tip_outlined, label: l10n.drawerPrivacyPolicy, path: '/profile/privacy'),
        DrawerItem(icon: Icons.info_outline, label: l10n.drawerAboutUs, path: '/about'),
=======
  static List<DrawerItem> drawerItems() => const [
        DrawerItem(icon: Icons.person, label: 'My Profile', path: UserProfileScreenNew.routeName),
        DrawerItem(icon: Icons.favorite, label: 'My Favourites', path: '/favourites'),
        DrawerItem(icon: Icons.shopping_cart, label: 'Cart', path: '/cart'),
        DrawerItem(icon: Icons.notifications, label: 'Notification', path: '/alerts'),
        DrawerItem(icon: Icons.credit_card, label: 'My Cards', path: '/profile/cards'),
        DrawerItem(icon: Icons.settings, label: 'Settings', path: '/profile/settings'),
        DrawerItem(icon: Icons.map, label: 'Saved Addresses', path: '/profile/saved-addresses'),
        DrawerItem(icon: Icons.lock_outline, label: 'Change Password', path: '/profile/change-password'),
        DrawerItem(icon: Icons.history, label: 'Order History', path: '/profile/order-history'),
        DrawerItem(icon: Icons.help_center, label: 'Help', path: '/profile/help'),
        DrawerItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', path: '/profile/privacy'),
        DrawerItem(icon: Icons.info_outline, label: 'About us', path: '/about'),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
      ];
}
