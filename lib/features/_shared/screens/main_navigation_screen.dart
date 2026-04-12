import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/features/user_home/presentation/screens/home_screen.dart';
import 'package:kathir_final/features/user_home/presentation/screens/favorites_screen_new.dart';
import 'package:kathir_final/features/user_home/presentation/screens/all_meals_screen.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import 'package:kathir_final/features/cart/presentation/screens/cart_screen.dart';
import 'package:kathir_final/features/orders/presentation/screens/my_orders_screen_new.dart';
import 'package:kathir_final/features/profile/presentation/screens/user_profile_screen_new.dart';
import 'package:kathir_final/features/_shared/widgets/home_bottom_nav_bar.dart';
import 'package:kathir_final/features/profile/presentation/providers/foodie_state.dart';
import 'package:kathir_final/di/global_injection/app_locator.dart';

/// Main shell: Home, Favorites, Cart, Orders, Profile, Meals.
/// Matches the Kathir user_home_page bottom nav design.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 5);
    
    // Load cart from database when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodieState>().loadCart();
    });
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex.clamp(0, 5);
      });
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return ChangeNotifierProvider(
          create: (_) => FavoritesViewModel()..loadFavorites(),
          child: const FavoritesScreenNew(),
        );
      case 2:
        return const CartScreen();
      case 3:
        return const MyOrdersScreenNew();
      case 4:
        return const UserProfileScreenNew();
      case 5:
        // Meals screen - load meals from HomeViewModel
        return Consumer<HomeViewModel>(
          builder: (context, viewModel, _) {
            // Ensure meals are loaded
            if (viewModel.meals.isEmpty && viewModel.status != HomeStatus.loading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                viewModel.loadIfNeeded();
              });
            }
            return AllMealsScreen(meals: viewModel.meals);
          },
        );
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: AppLocator.I.get<HomeViewModel>(),
      child: Scaffold(
        body: _buildPage(_currentIndex),
        bottomNavigationBar: HomeBottomNavBar(
          currentIndex: _currentIndex,
          // Don't pass onTap - let the nav bar use context.go() for proper URL updates
        ),
      ),
    );
  }
}
