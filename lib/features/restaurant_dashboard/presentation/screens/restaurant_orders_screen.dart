import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../widgets/restaurant_bottom_nav.dart';
import '../widgets/active_order_card.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _restaurantId;
  List<Map<String, dynamic>> _orders = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔍 ========== RESTAURANT ORDERS OPTIMIZED LOAD ==========');
      
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ User ID is null');
        return;
      }

      _restaurantId = userId;
      debugPrint('✅ Restaurant ID: $_restaurantId');

      // Step 1: Get orders and show immediately
      debugPrint('📊 Step 1: Fetching orders...');
      var ordersQuery = _supabase
          .from('orders')
          .select('id, order_number, status, total_amount, created_at, user_id')
          .eq('restaurant_id', _restaurantId!);

      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'active') {
          ordersQuery = ordersQuery.inFilter('status', 
            ['pending', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery']);
        } else {
          ordersQuery = ordersQuery.eq('status', _selectedFilter);
        }
      }

      final ordersRes = await ordersQuery.order('created_at', ascending: false);
      final ordersList = List<Map<String, dynamic>>.from(ordersRes);
      
      debugPrint('✅ Step 1: Got ${ordersList.length} orders');

      // Show orders immediately (without details yet)
      if (mounted) {
        setState(() {
          _orders = ordersList;
          _isLoading = false; // Stop loading indicator, show orders
        });
      }

      if (ordersList.isEmpty) {
        return;
      }

      // Continue loading details in background
      final orderIds = ordersList.map((o) => o['id'] as String).toList();
      final userIds = ordersList
          .map((o) => o['user_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // Step 2: Get order items
      debugPrint('📊 Step 2: Fetching order items...');
      final orderItemsRes = await _supabase
          .from('order_items')
          .select('id, order_id, quantity, unit_price, meal_id')
          .inFilter('order_id', orderIds);

      final orderItemsList = List<Map<String, dynamic>>.from(orderItemsRes);
      debugPrint('✅ Step 2: Got ${orderItemsList.length} order items');

      // Step 3: Get meals
      final mealIds = orderItemsList
          .map((item) => item['meal_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      debugPrint('📊 Step 3: Fetching meals...');
      final mealsRes = await _supabase
          .from('meals')
          .select('id, title, image_url')
          .inFilter('id', mealIds);

      final mealsList = List<Map<String, dynamic>>.from(mealsRes);
      debugPrint('✅ Step 3: Got ${mealsList.length} meals');

      // Step 4: Get profiles
      debugPrint('📊 Step 4: Fetching profiles...');
      final profilesRes = await _supabase
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);

      final profilesList = List<Map<String, dynamic>>.from(profilesRes);
      debugPrint('✅ Step 4: Got ${profilesList.length} profiles');

      // Step 5: Combine data and update UI
      final mealsMap = <String, Map<String, dynamic>>{};
      for (final meal in mealsList) {
        mealsMap[meal['id']] = meal;
      }

      final profilesMap = <String, Map<String, dynamic>>{};
      for (final profile in profilesList) {
        profilesMap[profile['id']] = profile;
      }

      final orderItemsMap = <String, List<Map<String, dynamic>>>{};
      for (final item in orderItemsList) {
        final orderId = item['order_id'] as String;
        if (!orderItemsMap.containsKey(orderId)) {
          orderItemsMap[orderId] = [];
        }
        
        final mealId = item['meal_id'] as String?;
        if (mealId != null && mealsMap.containsKey(mealId)) {
          item['meals'] = mealsMap[mealId];
        }
        
        orderItemsMap[orderId]!.add(item);
      }

      final enrichedOrders = ordersList.map((order) {
        final orderId = order['id'] as String;
        final userId = order['user_id'] as String?;

        order['order_items'] = orderItemsMap[orderId] ?? [];

        if (userId != null && profilesMap.containsKey(userId)) {
          order['profiles'] = profilesMap[userId];
        }

        return order;
      }).toList();

      debugPrint('✅ Combined all data. Final orders: ${enrichedOrders.length}');
      debugPrint('🎉 ========== RESTAURANT ORDERS LOAD COMPLETE ==========');

      // Update with full details
      if (mounted) {
        setState(() {
          _orders = enrichedOrders;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
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
        child: Column(
          children: [
            _buildHeader(isDark, surface),
            _buildFilterChips(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildOrdersList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/restaurant-dashboard');
              break;
            case 1:
              // Already on orders
              break;
            case 2:
              context.go('/restaurant-dashboard/meals');
              break;
            case 3:
              context.go('/restaurant-dashboard/leaderboard');
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
    return Container(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.go('/restaurant/chats');
            },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', isDark),
            const SizedBox(width: 8),
            _buildFilterChip('Active', 'active', isDark),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending', isDark),
            const SizedBox(width: 8),
            _buildFilterChip('Preparing', 'preparing', isDark),
            const SizedBox(width: 8),
            _buildFilterChip('Ready', 'ready_for_pickup', isDark),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryGreen 
              : (isDark ? AppColors.surfaceDark : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryGreen 
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.black 
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ActiveOrderCard(
              order: _orders[index],
              onTap: () {
                context.push('/restaurant-dashboard/order-detail/${_orders[index]['id']}');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Orders will appear here when customers place them'
                : 'No $_selectedFilter orders at the moment',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
