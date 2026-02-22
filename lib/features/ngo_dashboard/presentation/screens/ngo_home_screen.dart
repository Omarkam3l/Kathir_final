import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../viewmodels/ngo_home_viewmodel.dart';
import '../widgets/ngo_stat_card.dart';
import '../widgets/ngo_bottom_nav.dart';

/// NGO Home Screen - Dynamic meal listings with real-time data
class NgoHomeScreen extends StatefulWidget {
  const NgoHomeScreen({super.key});

  @override
  State<NgoHomeScreen> createState() => _NgoHomeScreenState();
}

class _NgoHomeScreenState extends State<NgoHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 NGO Home Screen - initState called');
    
    // Use addPostFrameCallback to ensure Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('🔄 Post-frame callback - loading data...');
        final viewModel = context.read<NgoHomeViewModel>();
        debugPrint('📊 ViewModel state - isLoading: ${viewModel.isLoading}, meals: ${viewModel.meals.length}');
        viewModel.loadIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer<NgoHomeViewModel>(
          builder: (context, viewModel, _) {
            // Add explicit error display
            if (viewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${viewModel.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.loadData(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.loadData(forceRefresh: true),
              child: CustomScrollView(
                slivers: [
                  _buildHeader(isDark, viewModel),
                  _buildSearchBar(isDark, viewModel),
                  _buildStatsBar(isDark, viewModel),
                  _buildFilterChips(isDark, viewModel),
                  
                  // Top Rated Restaurants Section
                  _buildTopRatedRestaurantsSection(isDark, viewModel),
                  
                  // Free Meals Section (Donated meals only)
                  _buildFreeMealsSection(isDark, viewModel),
                  
                  // Top Meals Section (Sorted by price)
                  _buildTopMealsSection(isDark, viewModel),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const NgoBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeader(bool isDark, NgoHomeViewModel viewModel) {
    final user = context.watch<AuthProvider>().user;
    final orgName = user?.fullName ?? 'NGO';
    final greeting = _getGreeting();

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            'CURRENT LOCATION',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              viewModel.currentLocation,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.expand_more, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildNotificationButton(isDark, viewModel),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                children: [
                  TextSpan(text: '$greeting, '),
                  TextSpan(
                    text: orgName,
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(bool isDark, NgoHomeViewModel viewModel) {
    return Row(
      children: [
        // Chat button
        GestureDetector(
          onTap: () => context.go('/ngo/chats'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2E22) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        // Notification button
        GestureDetector(
          onTap: () => context.go('/ngo-notifications'),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: const Icon(Icons.notifications_outlined, size: 20),
              ),
              if (viewModel.hasNotifications)
                Positioned(
                  top: 8,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark, NgoHomeViewModel viewModel) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.search,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: viewModel.setSearchQuery,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for meals...',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => context.go('/ngo/map'),
                icon: const Icon(
                  Icons.map,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Map View',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(bool isDark, NgoHomeViewModel viewModel) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            NgoStatCard(
              label: 'Meals Claimed',
              value: '${viewModel.mealsClaimed}',
              icon: Icons.restaurant,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            NgoStatCard(
              label: 'Carbon Saved',
              value: '${viewModel.carbonSaved.toInt()}kg',
              icon: Icons.eco,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            NgoStatCard(
              label: 'Active Orders',
              value: '${viewModel.activeOrders}',
              icon: Icons.local_shipping,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, NgoHomeViewModel viewModel) {
    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('all', 'All Listings', null, isDark, viewModel),
            _buildFilterChip('vegetarian', 'Vegetarian', Icons.grass, isDark, viewModel),
            _buildFilterChip('nearby', 'Within 5km', Icons.near_me, isDark, viewModel),
            _buildFilterChip('large', 'Large Qty', Icons.inventory_2, isDark, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    IconData? icon,
    bool isDark,
    NgoHomeViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => viewModel.setFilter(value),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        selectedColor: isDark ? Colors.white : Colors.black,
        checkmarkColor: isDark ? Colors.black : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? (isDark ? Colors.black : Colors.white) : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
        backgroundColor: isDark ? const Color(0xFF1A2E22) : Colors.white,
        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
    );
  }

  // Widget _buildExpiringSoonSection(bool isDark, NgoHomeViewModel viewModel) {
  //   return SliverToBoxAdapter(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Row(
  //                 children: [
  //                   const Icon(Icons.timer, color: Colors.orange, size: 20),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Expiring Soon',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: isDark ? Colors.white : Colors.black,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               GestureDetector(
  //                 onTap: () {
  //                   // Show all expiring meals
  //                   viewModel.setFilter('expiring');
  //                 },
  //                 child: const Text(
  //                   'See All',
  //                   style: TextStyle(
  //                     color: AppColors.primaryGreen,
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 13,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(
  //           height: 200,
  //           child: ListView.builder(
  //             scrollDirection: Axis.horizontal,
  //             padding: const EdgeInsets.symmetric(horizontal: 16),
  //             itemCount: viewModel.expiringMeals.take(5).length,
  //             itemBuilder: (context, index) => NgoUrgentCard(
  //               meal: viewModel.expiringMeals[index],
  //               isDark: isDark,
  //               onClaim: () => viewModel.claimMeal(
  //                 viewModel.expiringMeals[index],
  //                 context,
  //               ),
  //               onViewDetails: () {
  //                 context.push('/ngo/meal/${viewModel.expiringMeals[index].id}', 
  //                   extra: viewModel.expiringMeals[index]);
  //               },
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildNearbySurplusHeader(bool isDark) {
  //   return SliverToBoxAdapter(
  //     child: Padding(
  //       padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             'Nearby Surplus',
  //             style: TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? Colors.white : Colors.black,
  //             ),
  //           ),
  //           const Icon(Icons.sort, color: Colors.grey),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildEmptyState() {
  //   return SliverToBoxAdapter(
  //     child: Padding(
  //       padding: const EdgeInsets.all(32),
  //       child: Center(
  //         child: Column(
  //           children: [
  //             Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
  //             const SizedBox(height: 16),
  //             Text(
  //               'No surplus meals available',
  //               style: TextStyle(color: Colors.grey[600]),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ========== NEW SECTIONS ==========

  Widget _buildTopRatedRestaurantsSection(bool isDark, NgoHomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Get unique restaurants from meals and sort by rating
    final restaurantMap = <String, Map<String, dynamic>>{};
    for (final meal in viewModel.meals) {
      final restaurantId = meal.restaurant.id;
      if (!restaurantMap.containsKey(restaurantId)) {
        restaurantMap[restaurantId] = {
          'id': meal.restaurant.id,
          'name': meal.restaurant.name,
          'rating': meal.restaurant.rating,
          'logo_url': meal.restaurant.logoUrl,
          'verified': meal.restaurant.verified,
        };
      }
    }

    final restaurants = restaurantMap.values.toList()
      ..sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));

    if (restaurants.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Top Rated Restaurants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: restaurants.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                final restaurant = restaurants[i];
                return _buildRestaurantChip(restaurant, isDark, i == 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantChip(Map<String, dynamic> restaurant, bool isDark, bool isFeatured) {
    final logoUrl = restaurant['logo_url'] as String?;
    
    return GestureDetector(
      onTap: () => _showRestaurantMeals(context, restaurant),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                border: Border.all(
                  color: isFeatured ? AppColors.primaryGreen : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        logoUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                          child: Text(
                            restaurant['name'].toString().isNotEmpty
                                ? restaurant['name'].toString()[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                      child: Text(
                        restaurant['name'].toString().isNotEmpty
                            ? restaurant['name'].toString()[0].toUpperCase()
                            : 'R',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              restaurant['name'].toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 10, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    (restaurant['rating'] as double).toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeMealsSection(bool isDark, NgoHomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Filter meals where donationPrice == 0 (actually donated by restaurant)
    final freeMeals = viewModel.meals.where((m) => m.donationPrice == 0).toList();

    if (freeMeals.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volunteer_activism, color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Free Meals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/ngo/meals/free', extra: freeMeals),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: freeMeals.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildMealSliderCard(freeMeals[i], isDark, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMealsSection(bool isDark, NgoHomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Sort meals by price (lowest first, excluding free meals)
    final paidMeals = viewModel.meals.where((m) => m.donationPrice > 0).toList()
      ..sort((a, b) => a.donationPrice.compareTo(b.donationPrice));

    if (paidMeals.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer, color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Top Meals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/ngo/meals/all', extra: paidMeals),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: paidMeals.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildMealSliderCard(paidMeals[i], isDark, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSliderCard(dynamic meal, bool isDark, NgoHomeViewModel viewModel) {
    final discount = meal.originalPrice > 0
        ? ((meal.originalPrice - meal.donationPrice) / meal.originalPrice)
        : 0.0;
    final badgeLabel = meal.donationPrice == 0
        ? 'FREE'
        : '${(discount * 100).round()}% OFF';

    return GestureDetector(
      onTap: () => context.push('/ngo/meal/${meal.id}', extra: meal),
      child: Container(
        width: 280,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                meal.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.restaurant,
                    size: 48,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: meal.donationPrice == 0
                          ? Colors.green
                          : AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meal.restaurant.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        meal.donationPrice == 0
                            ? 'FREE'
                            : 'EGP ${meal.donationPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => viewModel.claimMeal(meal, context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestaurantMeals(BuildContext context, Map<String, dynamic> restaurant) {
    final viewModel = context.read<NgoHomeViewModel>();
    final restaurantMeals = viewModel.meals
        .where((m) => m.restaurant.id == restaurant['id'])
        .toList();

    context.push('/ngo/restaurant/${restaurant['id']}', extra: {
      'restaurant': restaurant,
      'meals': restaurantMeals,
    });
  }
}
