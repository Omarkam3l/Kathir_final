import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chips_widget.dart';
import '../widgets/feature_cards_section.dart';
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

  @override
  void initState() {
    super.initState();
    // Force refresh to clear cache and load all meals
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<HomeViewModel>();
      vm.loadAll(forceRefresh: true);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: const Color(0xFF0F2044),
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
              
              // Feature Cards Section - Optimized without counts
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverToBoxAdapter(
                child: FeatureCardsSection(),
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
              const SliverToBoxAdapter(child: SizedBox(height: 120)), // ← زودنا من 100 لـ 120
            ],
          ),
        ),
      ),
    );
  }
}
