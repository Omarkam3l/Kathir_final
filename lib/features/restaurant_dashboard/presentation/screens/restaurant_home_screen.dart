import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../widgets/restaurant_bottom_nav.dart';
import '../widgets/kpi_card.dart';
import '../widgets/recent_meal_card.dart';
import '../widgets/active_order_card.dart';

class RestaurantHomeScreen extends StatefulWidget {
  const RestaurantHomeScreen({super.key});

  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // Restaurant info
  String? _restaurantId;
  String? _restaurantName;
  
  // KPIs
  int _activeMeals = 0;
  int _totalOrders = 0;
  double _todayRevenue = 0.0;
  int _pendingOrders = 0;
  
  // Recent meals (last 4)
  List<Map<String, dynamic>> _recentMeals = [];
  
  // Active orders (not completed or cancelled)
  List<Map<String, dynamic>> _activeOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get restaurant info
      final restaurantRes = await _supabase
          .from('restaurants')
          .select('profile_id, restaurant_name')
          .eq('profile_id', userId)
          .maybeSingle();

      if (restaurantRes != null) {
        _restaurantId = restaurantRes['profile_id'];
        _restaurantName = restaurantRes['restaurant_name'];
      }

      // Get all meals for KPIs
      final allMeals = await _supabase
          .from('meals')
          .select()
          .eq('restaurant_id', _restaurantId ?? userId);

      _activeMeals = (allMeals as List).where((m) => 
        DateTime.parse(m['expiry_date']).isAfter(DateTime.now())
      ).length;

      // Get recent meals (last 4)
      final recentMealsRes = await _supabase
          .from('meals')
          .select()
          .eq('restaurant_id', _restaurantId ?? userId)
          .order('created_at', ascending: false)
          .limit(4);

      _recentMeals = List<Map<String, dynamic>>.from(recentMealsRes);

      // Get active orders (not completed or cancelled)
      final activeOrdersRes = await _supabase
          .from('orders')
          .select('''
            *,
            meals:meal_id (
              title,
              meal_name,
              image_url
            ),
            profiles:user_id (
              full_name
            )
          ''')
          .eq('restaurant_id', _restaurantId ?? userId)
          .not('status', 'in', '(completed,cancelled)')
          .order('created_at', ascending: false);

      _activeOrders = List<Map<String, dynamic>>.from(activeOrdersRes);

      // Calculate KPIs
      final allOrdersRes = await _supabase
          .from('orders')
          .select('total_amount, created_at, status')
          .eq('restaurant_id', _restaurantId ?? userId);

      final allOrders = allOrdersRes as List;
      _totalOrders = allOrders.length;
      _pendingOrders = _activeOrders.where((o) => o['status'] == 'pending').length;

      // Calculate today's revenue
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      _todayRevenue = allOrders
          .where((o) => 
            DateTime.parse(o['created_at']).isAfter(todayStart) &&
            o['status'] == 'completed'
          )
          .fold(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    _buildHeader(isDark, surface),
                    _buildKPIsSection(surface, isDark),
                    _buildRecentMealsSection(isDark, surface),
                    _buildActiveOrdersSection(isDark, surface),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.go('/restaurant-dashboard/orders');
              break;
            case 2:
              context.go('/restaurant-dashboard/meals');
              break;
            case 3:
              // TODO: Implement chats
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chats coming soon')),
              );
              break;
            case 4:
              context.go('/restaurant-dashboard/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color surface) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.restaurant, color: AppColors.primaryGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    _restaurantName ?? 'Restaurant',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIsSection(Color surface, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: KPICard(
                    title: 'Active Meals',
                    value: '$_activeMeals',
                    icon: Icons.restaurant_menu,
                    color: AppColors.primaryGreen,
                    surface: surface,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KPICard(
                    title: 'Total Orders',
                    value: '$_totalOrders',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    surface: surface,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: KPICard(
                    title: 'Today Revenue',
                    value: '\$${_todayRevenue.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: Colors.orange,
                    surface: surface,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KPICard(
                    title: 'Pending',
                    value: '$_pendingOrders',
                    icon: Icons.pending_actions,
                    color: Colors.amber,
                    surface: surface,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMealsSection(bool isDark, Color surface) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Meals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/restaurant-dashboard/meals'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _recentMeals.isEmpty
                ? _buildEmptyMeals(isDark)
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentMeals.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _recentMeals.length - 1 ? 12 : 0,
                          ),
                          child: RecentMealCard(
                            meal: _recentMeals[index],
                            onTap: () async {
                              final result = await context.push(
                                '/restaurant-dashboard/meal/${_recentMeals[index]['id']}',
                              );
                              if (result == true) _loadData();
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrdersSection(bool isDark, Color surface) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_activeOrders.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go('/restaurant-dashboard/orders'),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _activeOrders.isEmpty
                ? _buildEmptyOrders(isDark)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activeOrders.length > 5 ? 5 : _activeOrders.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ActiveOrderCard(
                          order: _activeOrders[index],
                          onTap: () {
                            // TODO: Navigate to order details
                            debugPrint('Order tapped: ${_activeOrders[index]['id']}');
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMeals(bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No meals yet',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.go('/restaurant-dashboard/meals'),
              child: const Text('Add your first meal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrders(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No active orders',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Orders will appear here when customers place them',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
