import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/services/rating_service.dart';
import '../widgets/rating_dialog.dart';

class MyOrdersScreenNew extends StatefulWidget {
  static const routeName = '/my-orders';
  const MyOrdersScreenNew({super.key});

  @override
  State<MyOrdersScreenNew> createState() => _MyOrdersScreenNewState();
}

class _MyOrdersScreenNewState extends State<MyOrdersScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  final _ratingService = RatingService();
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _pastOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .channel('user_orders_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Reload orders when any change happens
            _loadOrders();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _tabController.dispose();
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _supabase.removeChannel(_supabase.channel('user_orders_$userId'));
    }
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load active orders (pending, confirmed, preparing, ready_for_pickup, out_for_delivery)
      final activeResponse = await _supabase
          .from('orders')
          .select('''
            *,
            restaurants!restaurant_id(profile_id, restaurant_name, address_text),
            order_items(
              id,
              quantity,
              unit_price,
              meals!meal_id(id, title, image_url)
            )
          ''')
          .eq('user_id', userId)
          .inFilter('status', [
            'pending',
            'confirmed',
            'preparing',
            'ready_for_pickup',
            'out_for_delivery'
          ])
          .order('created_at', ascending: false);

      // Load past orders (delivered, completed, cancelled)
      final pastResponse = await _supabase
          .from('orders')
          .select('''
            *,
            restaurants!restaurant_id(profile_id, restaurant_name, address_text),
            order_items(
              id,
              quantity,
              unit_price,
              meals!meal_id(id, title, image_url)
            )
          ''')
          .eq('user_id', userId)
          .inFilter('status', ['delivered', 'completed', 'cancelled'])
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _activeOrders = List<Map<String, dynamic>>.from(activeResponse);
        _pastOrders = List<Map<String, dynamic>>.from(pastResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveOrders(),
                        _buildPastOrders(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          const Expanded(
            child: Text(
              'My Orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrders() {
    if (_activeOrders.isEmpty) {
      return _buildEmptyState('No active orders');
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ACTIVE ORDERS (${_activeOrders.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ..._activeOrders.map((order) => _buildActiveOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildPastOrders() {
    if (_pastOrders.isEmpty) {
      return _buildEmptyState('No past orders');
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'PAST ORDERS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ..._pastOrders.map((order) => _buildPastOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final restaurant = order['restaurants'] as Map<String, dynamic>?;
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    final status = order['status'] as String;
    final pickupCode = order['pickup_code'] as String?;
    final orderId = order['id'] as String;
        
    // Get first meal image
    String? mealImage;
    if (orderItems.isNotEmpty) {
      final firstItem = orderItems[0] as Map<String, dynamic>;
      final meal = firstItem['meals'] as Map<String, dynamic>?;
      mealImage = meal?['image_url'] as String?;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Meal Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: mealImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          mealImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                        ),
                      )
                    : const Icon(Icons.fastfood, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant?['restaurant_name'] ?? 'Restaurant',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${pickupCode ?? orderId.substring(0, 6).toUpperCase()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getOrderItemsSummary(orderItems),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'EGP ${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              _buildActionButton(order),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrderCard(Map<String, dynamic> order) {
    final restaurant = order['restaurants'] as Map<String, dynamic>?;
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    final status = order['status'] as String;
    final createdAt = DateTime.parse(order['created_at'] as String);
    final pickupCode = order['pickup_code'] as String?;
    final orderId = order['id'] as String;
        
    // Get first meal image
    String? mealImage;
    if (orderItems.isNotEmpty) {
      final firstItem = orderItems[0] as Map<String, dynamic>;
      final meal = firstItem['meals'] as Map<String, dynamic>?;
      mealImage = meal?['image_url'] as String?;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Meal Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: mealImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          mealImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                        ),
                      )
                    : const Icon(Icons.fastfood, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant?['restaurant_name'] ?? 'Restaurant',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getOrderItemsSummary(orderItems),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          status == 'completed' || status == 'delivered'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: status == 'completed' || status == 'delivered'
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status == 'completed' || status == 'delivered'
                              ? 'Delivered'
                              : 'Cancelled',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: status == 'completed' || status == 'delivered'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EGP ${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  if (status == 'completed' || status == 'delivered') ...[
                    OutlinedButton(
                      onPressed: () => _showRatingDialog(context, order),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Rate',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement reorder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reorder',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
      case 'confirmed':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        label = 'Confirmed';
        break;
      case 'preparing':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        label = 'Preparing';
        break;
      case 'ready_for_pickup':
        bgColor = AppColors.primary.withValues(alpha: 0.2);
        textColor = AppColors.primary;
        label = 'Ready for Pickup';
        break;
      case 'out_for_delivery':
        bgColor = Colors.purple[100]!;
        textColor = Colors.purple[700]!;
        label = 'Out for Delivery';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final orderId = order['id'] as String;
    
    if (status == 'ready_for_pickup') {
      return ElevatedButton.icon(
        onPressed: () {
          context.push('/order-qr/$orderId');
        },
        icon: const Icon(Icons.qr_code, size: 18),
        label: Text(
          'View Pickup QR',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () {
          context.push('/order-tracking/$orderId');
        },
        icon: const Icon(Icons.location_on, size: 18),
        label: Text(
          'Track Order',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderItemsSummary(List<dynamic> orderItems) {
    if (orderItems.isEmpty) return 'No items';

    final items = orderItems.map((item) {
      final quantity = item['quantity'] ?? 1;
      final meal = item['meals'] as Map<String, dynamic>?;
      final title = meal?['title'] ?? 'Item';
      return '${quantity}x $title';
    }).toList();

    return items.join(', ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Future<void> _showRatingDialog(
      BuildContext context, Map<String, dynamic> order) async {
    final restaurant = order['restaurants'] as Map<String, dynamic>?;
    final restaurantName = restaurant?['restaurant_name'] ?? 'Restaurant';
    final orderId = order['id'] as String;

    // Check if already rated
    final existingRating = await _ratingService.getOrderRating(orderId);

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        orderId: orderId,
        restaurantName: restaurantName,
        existingRating: existingRating?['rating'] as int?,
        existingReview: existingRating?['review_text'] as String?,
        onSubmit: (rating, review) async {
          await _ratingService.submitRating(
            orderId: orderId,
            rating: rating,
            reviewText: review,
          );
        },
      ),
    );

    // Reload orders if rating was submitted
    if (result == true) {
      _loadOrders();
    }
  }
}
