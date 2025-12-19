import 'package:flutter/material.dart';
import 'package:kathir_final/features/favorites/presentation/screens/favourites_screen.dart';
import 'package:kathir_final/features/user_home/presentation/screens/home_screen.dart';
import 'package:kathir_final/features/cart/presentation/screens/cart_screen.dart';
import 'package:kathir_final/features/profile/presentation/screens/notifications_screen.dart';
import 'package:kathir_final/features/profile/presentation/screens/profile_overview_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _index;
  final List<Widget> _pages = const [
    HomeScreen(),
    FavouritesScreen(),
    CartScreen(),
    NotificationsScreen(),
    ProfileOverviewScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: _select,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.navHome),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite_border), label: l10n.navFavourites),
          BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart_outlined), label: l10n.navCart),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_none), label: l10n.navAlerts),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: l10n.navProfile),
        ],
      ),
    );
  }
}
