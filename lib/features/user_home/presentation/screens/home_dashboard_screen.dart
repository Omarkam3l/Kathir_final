import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal.dart';
import 'package:kathir_final/features/user_home/presentation/viewmodels/home_viewmodel.dart';
import 'package:kathir_final/features/profile/presentation/providers/foodie_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chips_widget.dart';
import '../widgets/flash_deals_section.dart';
import '../widgets/rush_hour_section.dart';
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
  List<MealOffer> _rushHourMeals = [];
  bool _isLoadingRushHour = true;

  @override
  void initState() {
    super.initState();
    // Force refresh to clear cache and load all meals
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<HomeViewModel>();
      vm.loadAll(forceRefresh: true).then((_) {
        _loadRushHourMeals();
      });
    });
  }

  Future<void> _loadRushHourMeals() async {
    setState(() => _isLoadingRushHour = true);
    final meals = await _getRushHourMeals();
    if (mounted) {
      setState(() {
        _rushHourMeals = meals;
        _isLoadingRushHour = false;
      });
    }
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

  // Get meals from restaurants with active rush hour ONLY
  Future<List<MealOffer>> _getRushHourMeals() async {
    try {
      final now = DateTime.now();
      debugPrint('⏰ Current Time: $now');
      
      // Get restaurants with ACTIVE rush hour
      final rushHourResponse = await Supabase.instance.client
          .from('rush_hours')
          .select('restaurant_id, discount_percentage, start_time, end_time')
          .eq('is_active', true);
      
      debugPrint('📊 Rush Hours Response: ${rushHourResponse.length} records');
      
      if (rushHourResponse.isEmpty) {
        debugPrint('❌ No active rush hours found');
        return [];
      }
      
      // Filter by time range and create map of restaurant_id -> discount
      final Map<String, int> activeRestaurantDiscounts = {};
      
      for (var rh in rushHourResponse) {
        try {
          final startTime = DateTime.parse(rh['start_time'] as String);
          final endTime = DateTime.parse(rh['end_time'] as String);
          final restaurantId = rh['restaurant_id'] as String;
          final discount = rh['discount_percentage'] as int;
          
          debugPrint('🕐 Restaurant $restaurantId: Start=$startTime, End=$endTime, Discount=$discount%');
          debugPrint('   Now is after start? ${now.isAfter(startTime)}');
          debugPrint('   Now is before end? ${now.isBefore(endTime)}');
          
          if (now.isAfter(startTime) && now.isBefore(endTime)) {
            activeRestaurantDiscounts[restaurantId] = discount;
            debugPrint('   ✅ ACTIVE NOW!');
          } else {
            debugPrint('   ❌ NOT ACTIVE (time mismatch)');
          }
        } catch (e) {
          debugPrint('   ⚠️ Error parsing time: $e');
          continue;
        }
      }
      
      if (activeRestaurantDiscounts.isEmpty) {
        debugPrint('❌ No restaurants with active rush hour in current time');
        return [];
      }
      
      debugPrint('🔥 Active Rush Hour Restaurants: $activeRestaurantDiscounts');
      
      // Get all meals and filter by active rush hour restaurants
      if (!mounted) return [];
      final vm = context.read<HomeViewModel>();
      final allMeals = vm.meals;
      
      debugPrint('📦 Total meals in ViewModel: ${allMeals.length}');
      
      // Debug: Print all restaurant IDs from meals
      final mealRestaurantIds = allMeals.map((m) => m.restaurant.id).toSet();
      debugPrint('📋 All Meal Restaurant IDs: $mealRestaurantIds');
      
      final rushHourMeals = allMeals.where((meal) {
        final hasRushHour = activeRestaurantDiscounts.containsKey(meal.restaurant.id);
        if (hasRushHour) {
          debugPrint('   ✅ Meal "${meal.title}" from restaurant ${meal.restaurant.id} - HAS RUSH HOUR');
        }
        return hasRushHour;
      }).map((meal) {
        // Apply rush hour discount to the meal
        final discount = activeRestaurantDiscounts[meal.restaurant.id]!;
        final discountedPrice = meal.originalPrice * (1 - discount / 100);
        
        debugPrint('💰 ${meal.title}: ${meal.originalPrice} EGP -> $discountedPrice EGP ($discount% off)');
        
        // Create new meal with discounted price
        return Meal(
          id: meal.id,
          title: meal.title,
          location: meal.location,
          imageUrl: meal.imageUrl,
          originalPrice: meal.originalPrice,
          donationPrice: discountedPrice,
          quantity: meal.quantity,
          expiry: meal.expiry,
          restaurant: meal.restaurant,
          description: meal.description,
          ingredients: meal.ingredients,
          allergens: meal.allergens,
          co2Savings: meal.co2Savings,
          pickupTime: meal.pickupTime,
          category: meal.category,
          unit: meal.unit,
          fulfillmentMethod: meal.fulfillmentMethod,
          status: meal.status,
          isDonationAvailable: meal.isDonationAvailable,
          pickupDeadline: meal.pickupDeadline,
        );
      }).toList().cast<MealOffer>();
      
      debugPrint('🎯 Total Rush Hour Meals Found: ${rushHourMeals.length}');
      
      // Sort by discount
      rushHourMeals.sort((a, b) {
        final dA = a.originalPrice > 0
            ? (a.originalPrice - a.donationPrice) / a.originalPrice
            : 0.0;
        final dB = b.originalPrice > 0
            ? (b.originalPrice - b.donationPrice) / b.originalPrice
            : 0.0;
        return dB.compareTo(dA);
      });
      
      debugPrint('📤 Returning ${rushHourMeals.take(10).length} meals (max 10)');
      
      return rushHourMeals.take(10).toList();
      
    } catch (e) {
      debugPrint('❌ Error getting rush hour meals: $e');
      return [];
    }
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
              ),              // Rush Hour Section - Always show with placeholder if empty
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: RushHourSection(
                  rushHourMeals: _rushHourMeals,
                  isLoading: _isLoadingRushHour,
                  onSeeAll: () {
                    context.push('/rush-hour-meals');
                  },
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
