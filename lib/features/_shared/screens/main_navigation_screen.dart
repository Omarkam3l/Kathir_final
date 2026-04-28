import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/features/user_home/presentation/screens/home_screen.dart';
import 'package:kathir_final/features/user_home/presentation/screens/favorites_screen_new.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import 'package:kathir_final/features/cart/presentation/screens/cart_screen.dart';
import 'package:kathir_final/features/orders/presentation/screens/my_orders_screen_new.dart';
import 'package:kathir_final/features/profile/presentation/screens/user_profile_screen_new.dart';
import 'package:kathir_final/features/_shared/widgets/home_bottom_nav_bar.dart';
import 'package:kathir_final/features/profile/presentation/providers/foodie_state.dart';
import 'package:kathir_final/di/global_injection/app_locator.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 2}); // Home = index 2

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodieState>().loadCart();
    });
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always sync when initialIndex changes (e.g. from go_router)
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() => _currentIndex = widget.initialIndex.clamp(0, 4));
    }
  }

  // Keep pages alive to avoid rebuilding on tab switch
  final Map<int, Widget> _pageCache = {};

  Widget _buildPage(int index) {
    if (!_pageCache.containsKey(index)) {
      _pageCache[index] = _createPage(index);
    }
    return _pageCache[index]!;
  }

  Widget _createPage(int index) {
    switch (index) {
      case 0: return ChangeNotifierProvider(
          create: (_) => FavoritesViewModel()..loadFavorites(),
          child: const FavoritesScreenNew());
      case 1: return const CartScreen();
      case 2: return const HomeScreen();   // ← Home in middle, default
      case 3: return const MyOrdersScreenNew();
      case 4: return const UserProfileScreenNew();
      default: return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: AppLocator.I.get<HomeViewModel>(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ⭐⭐⭐ COMPLEX MULTI-LAYER BACKGROUND
            Positioned.fill(
              child: AppColors.buildComplexBackground(),
            ),
            
            // All pages — IndexedStack keeps them alive
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: List.generate(5, (i) => _buildPage(i)),
              ),
            ),
            
            // Floating nav bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HomeBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
