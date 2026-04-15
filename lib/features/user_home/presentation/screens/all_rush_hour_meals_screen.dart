import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../domain/entities/meal_offer.dart';
import '../../domain/entities/meal.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/rush_hour_meal_card.dart';

/// All Rush Hour Meals Screen - Shows all meals with rush hour discounts
class AllRushHourMealsScreen extends StatelessWidget {
  const AllRushHourMealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use persistent singleton ViewModel from DI
    return ChangeNotifierProvider.value(
      value: AppLocator.I.get<HomeViewModel>(),
      child: const _AllRushHourMealsContent(),
    );
  }
}

class _AllRushHourMealsContent extends StatefulWidget {
  const _AllRushHourMealsContent();

  @override
  State<_AllRushHourMealsContent> createState() => _AllRushHourMealsContentState();
}

class _AllRushHourMealsContentState extends State<_AllRushHourMealsContent> {
  String _sortBy = 'discount'; // discount, price, time
  List<MealOffer> _rushHourMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRushHourMeals();
  }

  Future<void> _loadRushHourMeals() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      
      // Get restaurants with ACTIVE rush hour
      final rushHourResponse = await Supabase.instance.client
          .from('rush_hours')
          .select('restaurant_id, discount_percentage, start_time, end_time')
          .eq('is_active', true);
      
      if (rushHourResponse.isEmpty) {
        if (mounted) {
          setState(() {
            _rushHourMeals = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      // Filter by time range and create map of restaurant_id -> discount
      final Map<String, int> activeRestaurantDiscounts = {};
      
      for (var rh in rushHourResponse) {
        try {
          final startTime = DateTime.parse(rh['start_time'] as String);
          final endTime = DateTime.parse(rh['end_time'] as String);
          
          if (now.isAfter(startTime) && now.isBefore(endTime)) {
            final restaurantId = rh['restaurant_id'] as String;
            final discount = rh['discount_percentage'] as int;
            activeRestaurantDiscounts[restaurantId] = discount;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (activeRestaurantDiscounts.isEmpty) {
        if (mounted) {
          setState(() {
            _rushHourMeals = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      debugPrint('🔥 Active Rush Hour Restaurants: $activeRestaurantDiscounts');
      
      // Get all meals and filter by active rush hour restaurants
      final vm = context.read<HomeViewModel>();
      await vm.loadIfNeeded();
      
      // Debug: Print all restaurant IDs from meals
      final mealRestaurantIds = vm.meals.map((m) => m.restaurant.id).toSet();
      debugPrint('📋 All Meal Restaurant IDs: $mealRestaurantIds');
      
      var meals = vm.meals.where((meal) {
        return activeRestaurantDiscounts.containsKey(meal.restaurant.id);
      }).map((meal) {
        // Apply rush hour discount to the meal
        final discount = activeRestaurantDiscounts[meal.restaurant.id]!;
        final discountedPrice = meal.originalPrice * (1 - discount / 100);
        
        debugPrint('✅ ${meal.title}: ${meal.originalPrice} EGP -> $discountedPrice EGP ($discount% off)');
        
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
      }).toList();
      
      debugPrint('🎯 Total Rush Hour Meals: ${meals.length}');
      
      // Apply sorting
      _applySorting(meals);
      
      if (mounted) {
        setState(() {
          _rushHourMeals = meals;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      debugPrint('❌ Error loading rush hour meals: $e');
      if (mounted) {
        setState(() {
          _rushHourMeals = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applySorting(List<MealOffer> meals) {
    switch (_sortBy) {
      case 'price':
        meals.sort((a, b) => a.donationPrice.compareTo(b.donationPrice));
        break;
      case 'time':
        meals.sort((a, b) => a.expiry.compareTo(b.expiry));
        break;
      case 'discount':
      default:
        meals.sort((a, b) {
          final dA = a.originalPrice > 0
              ? (a.originalPrice - a.donationPrice) / a.originalPrice
              : 0.0;
          final dB = b.originalPrice > 0
              ? (b.originalPrice - b.donationPrice) / b.originalPrice
              : 0.0;
          return dB.compareTo(dA);
        });
        break;
    }
  }

  void _onSortChanged(String newSort) {
    setState(() {
      _sortBy = newSort;
      _applySorting(_rushHourMeals);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2D241B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF1B140D),
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rush Hour Deals',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1B140D),
                  ),
                ),
                Text(
                  '${_rushHourMeals.length} meals available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.sort,
              color: isDark ? Colors.white : const Color(0xFF1B140D),
            ),
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'discount',
                child: Row(
                  children: [
                    Icon(
                      Icons.percent,
                      size: 18,
                      color: _sortBy == 'discount'
                          ? AppColors.primaryGreen
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Highest Discount',
                      style: TextStyle(
                        color: _sortBy == 'discount'
                            ? AppColors.primaryGreen
                            : null,
                        fontWeight: _sortBy == 'discount'
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 18,
                      color: _sortBy == 'price'
                          ? AppColors.primaryGreen
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lowest Price',
                      style: TextStyle(
                        color:
                            _sortBy == 'price' ? AppColors.primaryGreen : null,
                        fontWeight: _sortBy == 'price'
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'time',
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 18,
                      color: _sortBy == 'time'
                          ? AppColors.primaryGreen
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ending Soon',
                      style: TextStyle(
                        color:
                            _sortBy == 'time' ? AppColors.primaryGreen : null,
                        fontWeight: _sortBy == 'time'
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rushHourMeals.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadRushHourMeals,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _rushHourMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _rushHourMeals[index];
                      return RushHourMealCard(
                        offer: meal,
                        showRushHourBadge: true,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_outlined,
              size: 64,
              color: AppColors.primaryGreen.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Rush Hour Deals',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1B140D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for amazing deals!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
