import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../domain/entities/meal_offer.dart';
import '../../../meals/presentation/screens/all_meals_screen.dart';
import '../../../meals/presentation/screens/meal_detail.dart';
import '../widgets/home_header.dart';
import '../widgets/highlights_section.dart';
import '../widgets/meal_card_compact.dart';
import '../widgets/profile_drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
=======
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/authentication/presentation/blocs/auth_provider.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import 'package:kathir_final/features/meals/presentation/screens/all_meals_screen.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/location_bar_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chips_widget.dart';
import '../widgets/flash_deals_section.dart';
import '../widgets/top_rated_partners_section.dart';
import '../widgets/available_meals_grid_section.dart';
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f

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

    // Category (keyword-based until we have real categories)
    if (_category != 'All') {
      final k = _categoryKeywords(_category);
      list = list.where((m) {
        final t = '${m.title} ${m.restaurant.name}'.toLowerCase();
        return k.any((w) => t.contains(w));
      }).toList();
    }

    return list;
  }

  List<String> _categoryKeywords(String c) {
    switch (c) {
      case 'Vegetarian':
        return ['veg', 'vegetarian', 'vegan'];
      case 'Bakery':
        return ['bakery', 'bread', 'pastry', 'cake', 'sweet'];
      case 'Produce':
        return ['produce', 'fruit', 'vegetable', 'green', 'salad'];
      case 'Under 5km':
        return []; // no filter; show all
      default:
        return [];
    }
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
<<<<<<< HEAD
    return Scaffold(
      key: _scaffoldKey,
      drawer: null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeaderSection(),
            SliverToBoxAdapter(
              child: HomeHeader(onQueryChanged: (q) => setState(() => _query = q)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.paddingMedium)),
            const SliverToBoxAdapter(child: HighlightsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.paddingLarge)),
            _buildMealsSection(),
            _buildMealsList(),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatbotComingSoon)),
        ),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
      ),
      bottomNavigationBar: null,
    );
  }
=======
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final vm = context.watch<HomeViewModel>();
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => vm.loadAll(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: HomeHeaderWidget()),
              SliverToBoxAdapter(
                child: LocationBarWidget(
                  location: context.watch<AuthProvider>().user?.defaultLocation ??
                      'Downtown, San Francisco',
                ),
              ),
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  onQueryChanged: (q) => setState(() => _query = q),
                  onFilterTap: () {
                    // Optional: navigate to advanced search
                  },
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AllMealsScreen(
                          allOffers: vm.meals,
                        ),
                      ),
                    );
                  },
                ),
              ),
<<<<<<< HEAD
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsSection() {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLarge,
          AppDimensions.paddingSmall,
          AppDimensions.paddingLarge,
          AppDimensions.paddingSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.availableMeals,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllMealsScreen(
                      allOffers: context.read<HomeViewModel>().meals,
                    ),
                  ),
                );
              },
              child: Text(
                l10n.seeAll,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 520,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
          scrollDirection: Axis.horizontal,
          itemCount: _visibleOffers.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.paddingLarge),
          itemBuilder: (ctx, i) {
            final offer = _visibleOffers[i];
            return MealCardCompact(
              offer: offer,
              isSelected: false,
              onTap: () => _onCardTap(offer),
              index: i,
            );
          },
=======
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
        ),
      ),
    );
  }
}
