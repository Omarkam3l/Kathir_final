import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import 'package:kathir_final/features/profile/presentation/providers/foodie_state.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chips_widget.dart';
import '../widgets/flash_deals_section.dart';
import '../widgets/top_rated_partners_section.dart';
import '../widgets/available_meals_grid_section.dart';

/// Home dashboard matching the Kathir user_home_page design.
/// Composed of small widgets; uses AppColors and clean architecture.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String _query = '';
  String _category = 'All';

  List<MealOffer> get _filteredMeals {
    final vm = context.watch<HomeViewModel>();
    var list = List<MealOffer>.from(vm.meals);

    // Search
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) {
        return m.title.toLowerCase().contains(q) ||
            m.restaurant.name.toLowerCase().contains(q) ||
            m.location.toLowerCase().contains(q);
      }).toList();
    }

    // Category - filter by actual meal category from database
    if (_category != 'All') {
      list = list.where((m) {
        // Assuming MealOffer has a category field
        // If not, we'll need to add it to the entity
        return m.category == _category;
      }).toList();
    }

    return list;
  }

  List<MealOffer> get _flashDeals {
    final vm = context.watch<HomeViewModel>();
    final list = List<MealOffer>.from(vm.meals);
    list.sort((a, b) {
      final dA = a.originalPrice > 0
          ? (a.originalPrice - a.donationPrice) / a.originalPrice
          : 0.0;
      final dB = b.originalPrice > 0
          ? (b.originalPrice - b.donationPrice) / b.originalPrice
          : 0.0;
      return dB.compareTo(dA);
    });
    return list.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final vm = context.watch<HomeViewModel>();
    final foodie = context.watch<FoodieState>();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => vm.loadAll(forceRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: HomeHeaderWidget()),
              // SliverToBoxAdapter(
              //   child: LocationBarWidget(
              //     location: context.watch<AuthProvider>().user?.defaultLocation ??
              //         'Cairo, Egypt',
              //   ),
              // ),
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  onQueryChanged: (q) => setState(() => _query = q),
                  onFilterTap: () => context.push('/restaurant-search'),
                ),
              ),
              SliverToBoxAdapter(
                child: CategoryChipsWidget(
                  selectedCategory: _category,
                  onCategoryChanged: (c) => setState(() => _category = c),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: FlashDealsSection(deals: _flashDeals),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: TopRatedPartnersSection(restaurants: vm.restaurants),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: AvailableMealsGridSection(
                  meals: _filteredMeals,
                  onSeeAll: () {
                    context.go('/meals/all');
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: foodie.cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/cart'),
              backgroundColor: AppColors.primary,
              elevation: 6,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${foodie.cartCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              label: Text(
                'EGP ${foodie.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }
}
