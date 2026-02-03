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
  String _selectedFilter = 'all'; // all, pending, processing, completed

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

      _restaurantId = userId;

      // Get orders based on filter
      var query = _supabase
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
          .eq('restaurant_id', _restaurantId!);

      // Apply filter
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'active') {
          query = query.not('status', 'in', '(completed,cancelled)');
        } else {
          query = query.eq('status', _selectedFilter);
        }
      }

      final ordersRes = await query.order('created_at', ascending: false);

      _orders = List<Map<String, dynamic>>.from(ordersRes);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading orders: $e');
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
            _buildFilterChip('Processing', 'processing', isDark),
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
                // TODO: Navigate to order details
                debugPrint('Order tapped: ${_orders[index]['id']}');
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
