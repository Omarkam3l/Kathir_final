import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';

class NgoOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const NgoOrderDetailScreen({super.key, required this.orderId});

  @override
  State<NgoOrderDetailScreen> createState() => _NgoOrderDetailScreenState();
}

class _NgoOrderDetailScreenState extends State<NgoOrderDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);

    try {
      // Load order
      final orderResult = await _supabase
          .from('orders')
          .select('''
            id,
            order_code,
            status,
            delivery_type,
            total_amount,
            subtotal,
            delivery_address,
            created_at,
            restaurants!inner(
              profile_id,
              restaurant_name,
              address_text,
              phone
            )
          ''')
          .eq('id', widget.orderId)
          .single();

      // Load order items
      final itemsResult = await _supabase
          .from('order_items')
          .select('''
            id,
            meal_id,
            meal_title,
            quantity,
            unit_price,
            meals(
              image_url,
              category
            )
          ''')
          .eq('order_id', widget.orderId);

      setState(() {
        _order = orderResult;
        _orderItems = (itemsResult as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });

      debugPrint('✅ Loaded order details: ${_order?['order_code']}');
    } catch (e) {
      debugPrint('❌ Error loading order details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Order Details',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildErrorState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadOrderDetails,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderHeader(isDark),
                        const SizedBox(height: 24),
                        _buildStatusTimeline(isDark),
                        const SizedBox(height: 24),
                        _buildOrderItems(isDark),
                        const SizedBox(height: 24),
                        _buildRestaurantInfo(isDark),
                        const SizedBox(height: 24),
                        _buildDeliveryInfo(isDark),
                        const SizedBox(height: 24),
                        _buildOrderSummary(isDark),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOrderHeader(bool isDark) {
    final orderCode = _order!['order_code']?.toString() ?? 
                      _order!['id'].toString().substring(0, 8);
    final status = _order!['status'] as String;
    final createdAt = DateTime.parse(_order!['created_at']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderCode',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(status, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(bool isDark) {
    final status = _order!['status'] as String;
    final steps = [
      {'key': 'pending', 'label': 'Order Placed', 'icon': Icons.receipt_long},
      {'key': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle},
      {'key': 'preparing', 'label': 'Preparing', 'icon': Icons.restaurant_menu},
      {'key': 'ready_for_pickup', 'label': 'Ready', 'icon': Icons.shopping_bag},
      {'key': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
    ];

    final currentIndex = steps.indexWhere((s) => s['key'] == status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index <= currentIndex;
            final isActive = index == currentIndex;

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primaryGreen
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: isCompleted ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted
                            ? AppColors.primaryGreen
                            : (isDark ? Colors.grey[800] : Colors.grey[300]),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.grey,
                        ),
                      ),
                      if (index < steps.length - 1) const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItems(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_orderItems.length, (index) {
            final item = _orderItems[index];
            final meal = item['meals'] as Map<String, dynamic>?;
            final imageUrl = meal?['image_url'] ?? '';

            return Padding(
              padding: EdgeInsets.only(bottom: index < _orderItems.length - 1 ? 16 : 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.restaurant, size: 30),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant, size: 30),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['meal_title'] ?? 'Unknown Meal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantity: ${item['quantity']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo(bool isDark) {
    final restaurant = _order!['restaurants'] as Map<String, dynamic>;
    final restaurantName = restaurant['restaurant_name'] ?? 'Unknown Restaurant';
    final address = restaurant['address_text'] ?? 'No address provided';
    final phone = restaurant['phone'] ?? 'No phone';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.restaurant,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  restaurantName,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Text(
                phone,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(bool isDark) {
    final deliveryAddress = _order!['delivery_address'] ?? 'No address provided';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  deliveryAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark) {
    final totalItems = _orderItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Total Items', '$totalItems meals', isDark),
          const SizedBox(height: 8),
          _summaryRow('Subtotal', 'Free', isDark, valueColor: AppColors.primaryGreen),
          const SizedBox(height: 8),
          _summaryRow('Delivery Fee', 'Free', isDark, valueColor: AppColors.primaryGreen),
          const SizedBox(height: 8),
          _summaryRow('Service Fee', 'Waived', isDark, valueColor: AppColors.primaryGreen),
          Divider(
            height: 24,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'Free (Donation)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bgColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        displayText = 'Pending';
        break;
      case 'confirmed':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        displayText = 'Confirmed';
        break;
      case 'preparing':
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        displayText = 'Preparing';
        break;
      case 'ready_for_pickup':
        bgColor = AppColors.primaryGreen.withValues(alpha: 0.1);
        textColor = AppColors.primaryGreen;
        displayText = 'Ready for Pickup';
        break;
      case 'completed':
      case 'delivered':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        displayText = 'Completed';
        break;
      case 'cancelled':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        displayText = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Order not found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
