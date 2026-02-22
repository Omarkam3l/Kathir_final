import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:kathir_final/features/favorites/presentation/screens/favourites_screen.dart';
import 'package:kathir_final/features/user_home/presentation/screens/home_screen.dart';
import 'package:kathir_final/features/cart/presentation/screens/cart_screen.dart';
import 'package:kathir_final/features/profile/presentation/screens/notifications_screen.dart';
import 'package:kathir_final/features/profile/presentation/screens/profile_overview_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
=======
import 'package:kathir_final/features/user_home/presentation/screens/home_screen.dart';
import 'package:kathir_final/features/user_home/presentation/screens/map_placeholder_screen.dart';
import 'package:kathir_final/features/cart/presentation/screens/cart_screen.dart';
import 'package:kathir_final/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:kathir_final/features/profile/presentation/screens/user_profile_screen_new.dart';
import 'package:kathir_final/features/_shared/widgets/home_bottom_nav_bar.dart';
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f

/// Main shell: Home, Map, Cart (center), Orders, Profile.
/// Matches the Kathir user_home_page bottom nav design.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _index;

  static const List<Widget> _pages = [
    HomeScreen(),
    MapPlaceholderScreen(),
    CartScreen(),
    MyOrdersScreen(),
    UserProfileScreenNew(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update index if initialIndex changes
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _index = widget.initialIndex.clamp(0, _pages.length - 1);
      });
    }
  }

  void _select(int i) {
    if (_index != i) {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _index,
        onTap: _select,
<<<<<<< HEAD
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.navHome),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite_border), label: l10n.navFavourites),
          BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart_outlined), label: l10n.navCart),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_none), label: l10n.navAlerts),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: l10n.navProfile),
        ],
=======
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
      ),
    );
  }
}
