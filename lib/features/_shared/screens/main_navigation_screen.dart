import 'package:flutter/material.dart';
import 'package:kathir_final/features/user_home/presentation/screens/home_screen.dart';
import 'package:kathir_final/features/user_home/presentation/screens/map_placeholder_screen.dart';
import 'package:kathir_final/features/cart/presentation/screens/cart_screen.dart';
import 'package:kathir_final/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:kathir_final/features/profile/presentation/screens/profile_overview_screen.dart';
import 'package:kathir_final/features/_shared/widgets/home_bottom_nav_bar.dart';

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
    ProfileOverviewScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _index,
        onTap: _select,
      ),
    );
  }
}
