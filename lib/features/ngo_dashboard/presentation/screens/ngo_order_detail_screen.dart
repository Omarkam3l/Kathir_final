import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _supabase
        .channel('ngo_order_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (payload) {
            _loadOrderDetails();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_supabase.channel('ngo_order_${widget.orderId}'));
    super.dispose();
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
            pickup_code,
            qr_code,
            estimated_ready_time,
            restaurants!inner(
              profile_id,
              restaurant_name,
              address_text,
              phone
            )
          ''')
          .eq('id', widget.orderId)
          .single();

      // If order is ready for pickup and QR/OTP is missing, generate them
      if (orderResult['status'] == 'ready_for_pickup') {
        bool needsUpdate = false;
        
        if (orderResult['pickup_code'] == null) {
          orderResult['pickup_code'] = _generatePickupCode();
          needsUpdate = true;
        }
        
        if (orderResult['qr_code'] == null) {
          orderResult['qr_code'] = _generateQRCodeData(orderResult);
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          await _supabase
              .from('orders')
              .update({
                'pickup_code': orderResult['pickup_code'],
                'qr_code': orderResult['qr_code'],
              })
              .eq('id', widget.orderId);
        }
      }

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

  String _generatePickupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (index) => chars[(random + index) % chars.length]).join();
  }

  String _generateQRCodeData(Map<String, dynamic> order) {
    return '''
{
  "order_id": "${order['id']}",
  "pickup_code": "${order['pickup_code']}",
  "ngo_id": "${order['ngo_id'] ?? ''}",
  "restaurant_id": "${order['restaurant_id']}",
  "total": ${order['total_amount']},
  "created_at": "${order['created_at']}"
}
''';
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
                        // Show QR Code and OTP when ready for pickup
                        if (_order!['status'] == 'ready_for_pickup')
                          ...[
                            _buildPickupQRSection(isDark),
                            const SizedBox(height: 24),
                          ],
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

  Widget _buildPickupQRSection(bool isDark) {
    final pickupCode = _order!['pickup_code'] as String?;
    final qrData = _order!['qr_code'] as String?;
    final estimatedTime = _order!['estimated_ready_time'] != null
        ? DateTime.parse(_order!['estimated_ready_time'] as String)
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.1),
            AppColors.primaryGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Success Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 40,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Order Ready for Pickup!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Show this QR code or OTP at the restaurant',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          if (estimatedTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 18, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Ready by ${_formatTime(estimatedTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (qrData != null)
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  )
                else
                  Container(
                    width: 220,
                    height: 220,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                const SizedBox(height: 20),

                // Pickup Code (OTP)
                Text(
                  'Pickup Code (OTP)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    pickupCode ?? 'GENERATING...',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                      letterSpacing: 6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.blue[900]!.withValues(alpha: 0.3)
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Colors.blue[700]!.withValues(alpha: 0.5)
                    : Colors.blue[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Present this QR code or OTP to the restaurant staff to collect your order.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.blue[200] : Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
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
                            ? (isActive ? AppColors.primaryGreen : AppColors.primaryGreen.withValues(alpha: 0.7))
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: isCompleted ? Colors.white : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        size: 20,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: index < currentIndex
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
                    item['unit_price'] == 0 
                        ? 'Free' 
                        : 'EGP ${(item['unit_price'] * item['quantity']).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: item['unit_price'] == 0 ? AppColors.primaryGreen : Colors.orange,
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
              const Icon(
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
    
    final subtotal = _orderItems.fold<double>(
      0.0,
      (sum, item) => sum + ((item['unit_price'] ?? 0) * (item['quantity'] ?? 0)),
    );
    
    final totalAmount = _order!['total_amount'] ?? subtotal;

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
          _summaryRow(
            'Subtotal', 
            subtotal == 0 ? 'FREE' : 'EGP ${subtotal.toStringAsFixed(2)}', 
            isDark, 
            valueColor: subtotal == 0 ? AppColors.primaryGreen : null,
          ),
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
                totalAmount == 0 
                    ? 'Free (Donation)' 
                    : 'EGP ${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: totalAmount == 0 ? AppColors.primaryGreen : Colors.orange,
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
