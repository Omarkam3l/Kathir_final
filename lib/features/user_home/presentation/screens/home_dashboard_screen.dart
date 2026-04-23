import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/di/global_injection/app_locator.dart';
import 'package:kathir_final/features/authentication/presentation/blocs/auth_provider.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/recent_search_viewmodel.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/location_bar_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chips_widget.dart';
import '../widgets/flash_deals_section.dart';
import '../widgets/top_rated_partners_section.dart';
import '../widgets/available_meals_grid_section.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String _query = '';
  String _category = 'All';
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
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
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                  child: FlashDealsSection(deals: _flashDeals)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child:
                    TopRatedPartnersSection(restaurants: vm.restaurants),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: AvailableMealsGridSection(
                  meals: _filteredMeals,
                  onSeeAll: () =>
                      context.go('/meals/all', extra: vm.meals),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}


