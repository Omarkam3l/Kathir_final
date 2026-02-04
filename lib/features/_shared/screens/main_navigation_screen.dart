import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/features/user_home/presentation/screens/home_screen.dart';
import 'package:kathir_final/features/user_home/presentation/screens/favorites_screen_new.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:kathir_final/features/cart/presentation/screens/cart_screen.dart';
import 'package:kathir_final/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:kathir_final/features/profile/presentation/screens/user_profile_screen_new.dart';
import 'package:kathir_final/features/_shared/widgets/home_bottom_nav_bar.dart';

/// Main shell: Home, Favorites, Cart (center), Orders, Profile.
/// Matches the Kathir user_home_page bottom nav design.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _index;

  static final List<Widget> _pages = [
    const HomeScreen(),
    ChangeNotifierProvider(
      create: (_) => FavoritesViewModel()..loadFavorites(),
      child: const FavoritesScreenNew(),
    ),
    const CartScreen(),
    const MyOrdersScreen(),
    const UserProfileScreenNew(),
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
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _index,
        onTap: _select,
      ),
    );
  }
}
