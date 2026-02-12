import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../viewmodels/ngo_home_viewmodel.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';
import '../widgets/ngo_meal_card.dart';
import '../widgets/ngo_urgent_card.dart';
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
                  if (viewModel.expiringMeals.isNotEmpty)
                    _buildExpiringSoonSection(isDark, viewModel),
                  _buildNearbySurplusHeader(isDark),
                  viewModel.isLoading
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      : viewModel.filteredMeals.isEmpty
                          ? _buildEmptyState()
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => NgoMealCard(
                                    meal: viewModel.filteredMeals[index],
                                    isDark: isDark,
                                    onClaim: () => viewModel.claimMeal(
                                      viewModel.filteredMeals[index],
                                      context,
                                    ),
                                  ),
                                  childCount: viewModel.filteredMeals.length,
                                ),
                              ),
                            ),
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
              children: [
                Column(
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
                        Text(
                          viewModel.currentLocation,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const Icon(Icons.expand_more, size: 20),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildNotificationButton(isDark, viewModel),
                    const SizedBox(width: 12),
                    _buildMapButton(isDark),
                  ],
                ),
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
    final cart = context.watch<NgoCartViewModel>();
    
    return Row(
      children: [
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
        const SizedBox(width: 12),
        // Cart button with badge
        GestureDetector(
          onTap: () => context.go('/ngo/cart'),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 20),
              ),
              if (cart.cartCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cart.cartCount}',
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
        ),
      ],
    );
  }

  Widget _buildMapButton(bool isDark) {
    return GestureDetector(
      onTap: () => context.go('/ngo/map'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: const Icon(Icons.map, color: AppColors.primaryGreen, size: 20),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, NgoHomeViewModel viewModel) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2E22) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.search, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: viewModel.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search rice, bread, or nearby donors...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                ),
                child: const Icon(Icons.tune, color: AppColors.primaryGreen),
              ),
            ],
          ),
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

  Widget _buildExpiringSoonSection(bool isDark, NgoHomeViewModel viewModel) {
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
                    const Icon(Icons.timer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Expiring Soon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Show all expiring meals
                    viewModel.setFilter('expiring');
                  },
                  child: const Text(
                    'See All',
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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: viewModel.expiringMeals.take(5).length,
              itemBuilder: (context, index) => NgoUrgentCard(
                meal: viewModel.expiringMeals[index],
                isDark: isDark,
                onClaim: () => viewModel.claimMeal(
                  viewModel.expiringMeals[index],
                  context,
                ),
                onViewDetails: () {
                  context.push('/ngo/meal/${viewModel.expiringMeals[index].id}', 
                    extra: viewModel.expiringMeals[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySurplusHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nearby Surplus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Icon(Icons.sort, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No surplus meals available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
