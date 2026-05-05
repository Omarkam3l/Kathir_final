import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/di/global_injection/app_locator.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/recent_search_viewmodel.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chips_widget.dart';
import '../widgets/feature_cards_section.dart';
import '../widgets/available_meals_grid_section.dart';

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
  bool _showRecentSearches = false;
  final TextEditingController _searchController = TextEditingController();

  late final RecentSearchViewModel _recentVM;

  @override
  void initState() {
    super.initState();
    _recentVM = AppLocator.I.get<RecentSearchViewModel>();
    _recentVM.addListener(_onRecentVMChanged);
  }

  void _onRecentVMChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _recentVM.removeListener(_onRecentVMChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusGained() {
    if (_query.isEmpty) {
      _recentVM.load();
      setState(() => _showRecentSearches = true);
    }
  }

  void _onFocusLost() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showRecentSearches = false);
    });
  }

  void _onQueryChanged(String q) {
    setState(() {
      _query = q;
      _showRecentSearches = q.isEmpty;
    });
  }

  void _onQuerySubmitted(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    setState(() => _showRecentSearches = false);
    _recentVM.save(trimmed);
  }

  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    setState(() {
      _query = query;
      _showRecentSearches = false;
    });
    _recentVM.save(query);
  }

  List<MealOffer> get _filteredMeals {
    final vm = context.watch<HomeViewModel>();
    var list = List<MealOffer>.from(vm.meals);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) =>
          m.title.toLowerCase().contains(q) ||
          m.restaurant.name.toLowerCase().contains(q) ||
          m.location.toLowerCase().contains(q)).toList();
    }
    if (_category != 'All') {
      list = list.where((m) => m.category == _category).toList();
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
              SliverToBoxAdapter(
                child: LocationBarWidget(
                  location:
                      context.watch<AuthProvider>().user?.defaultLocation ??
                          'Cairo, Egypt',
                ),
              ),

              // Search bar with integrated dropdown overlay
              // SliverToBoxAdapter(
              //   child: LocationBarWidget(
              //     location: context.watch<AuthProvider>().user?.defaultLocation ??
              //         'Cairo, Egypt',
              //   ),
              // ),
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  controller: _searchController,
                  onQueryChanged: _onQueryChanged,
                  onQuerySubmitted: _onQuerySubmitted,
                  onFocusGained: _onFocusGained,
                  onFocusLost: _onFocusLost,
                  onFilterTap: () => context.push('/restaurant-search'),
                  showRecentSearches: _showRecentSearches,
                  recentSearches: _recentVM.searches,
                  recentSearchesLoading: _recentVM.isLoading,
                  onRecentSearchTap: _onRecentSearchTap,
                  onRecentSearchDelete: (id) => _recentVM.delete(id),
                  onClearAll: () => _recentVM.clearAll(),
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
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}


