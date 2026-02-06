import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';

class RestaurantOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const RestaurantOrderDetailScreen({super.key, required this.orderId});

  @override
  State<RestaurantOrderDetailScreen> createState() => _RestaurantOrderDetailScreenState();
}

class _RestaurantOrderDetailScreenState extends State<RestaurantOrderDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _supabase
        .channel('restaurant_order_${widget.orderId}')
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
            _loadOrderData();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_supabase.channel('restaurant_order_${widget.orderId}'));
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            profiles!user_id(full_name, phone_number),
            order_items(
              id,
              quantity,
              unit_price,
              meals!meal_id(id, title, image_url)
            )
          ''')
          .eq('id', widget.orderId)
          .single();

      setState(() {
        _orderData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', widget.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrderData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_orderData == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Order not found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _orderData!['status'] as String;
    final customer = _orderData!['profiles'] as Map<String, dynamic>?;
    final orderItems = _orderData!['order_items'] as List<dynamic>? ?? [];
    final deliveryMethod = _orderData!['delivery_type'] as String?;
    final pickupCode = _orderData!['pickup_code'] as String?;
    final specialInstructions = _orderData!['special_instructions'] as String?;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(status, isDark),
                    const SizedBox(height: 16),
                    _buildCustomerInfo(customer, isDark),
                    const SizedBox(height: 16),
                    _buildOrderItems(orderItems, isDark),
                    const SizedBox(height: 16),
                    _buildOrderSummary(isDark),
                    if (specialInstructions != null && specialInstructions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSpecialInstructions(specialInstructions, isDark),
                    ],
                    if (pickupCode != null && deliveryMethod == 'pickup') ...[
                      const SizedBox(height: 16),
                      _buildPickupCode(pickupCode, isDark),
                    ],
                    const SizedBox(height: 24),
                    _buildActionButtons(status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const Expanded(
            child: Text(
              'Order Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(status).withOpacity(0.1),
            _getStatusColor(status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 30,
              color: _getStatusColor(status),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusLabel(status),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic>? customer, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                customer?['full_name'] ?? 'Customer',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            ],
          ),
          if (customer?['phone_number'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  customer!['phone_number'],
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItems(List<dynamic> orderItems, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...orderItems.map((item) {
            final meal = item['meals'] as Map<String, dynamic>?;
            final quantity = item['quantity'] ?? 1;
            final price = item['unit_price'] ?? 0.0;
            final imageUrl = meal?['image_url'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (imageUrl != null)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal?['title'] ?? 'Item',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Quantity: $quantity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'EGP ${price.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark) {
    final subtotal = _orderData!['subtotal'] ?? 0.0;
    final deliveryFee = _orderData!['delivery_fee'] ?? 0.0;
    final platformFee = _orderData!['platform_fee'] ?? 0.0;
    final total = _orderData!['total_amount'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', subtotal, isDark),
          _buildSummaryRow('Delivery Fee', deliveryFee, isDark),
          _buildSummaryRow('Platform Fee', platformFee, isDark),
          Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'EGP ${total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
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

  Widget _buildSummaryRow(String label, double amount, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'EGP ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(String instructions, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Instructions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instructions,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCode(String pickupCode, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Pickup Code',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pickupCode,
            style: GoogleFonts.robotoMono(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer will show this code for pickup',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String currentStatus) {
    final buttons = _getAvailableActions(currentStatus);
    
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons.map((button) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            onPressed: _isUpdating ? null : () => _updateOrderStatus(button['status']),
            style: ElevatedButton.styleFrom(
              backgroundColor: button['color'],
              foregroundColor: button['textColor'],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isUpdating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(button['icon'], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        button['label'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return [
          {
            'status': 'confirmed',
            'label': 'Accept Order',
            'icon': Icons.check_circle,
            'color': AppColors.primaryGreen,
            'textColor': Colors.black,
          },
          {
            'status': 'cancelled',
            'label': 'Reject Order',
            'icon': Icons.cancel,
            'color': Colors.red,
            'textColor': Colors.white,
          },
        ];
      case 'confirmed':
        return [
          {
            'status': 'preparing',
            'label': 'Start Preparing',
            'icon': Icons.restaurant,
            'color': Colors.blue,
            'textColor': Colors.white,
          },
        ];
      case 'preparing':
        final deliveryMethod = _orderData!['delivery_type'] as String?;
        if (deliveryMethod == 'pickup') {
          return [
            {
              'status': 'ready_for_pickup',
              'label': 'Mark as Ready for Pickup',
              'icon': Icons.shopping_bag,
              'color': AppColors.primaryGreen,
              'textColor': Colors.black,
            },
          ];
        } else {
          return [
            {
              'status': 'out_for_delivery',
              'label': 'Send Out for Delivery',
              'icon': Icons.delivery_dining,
              'color': Colors.purple,
              'textColor': Colors.white,
            },
          ];
        }
      case 'ready_for_pickup':
        return [
          {
            'status': 'completed',
            'label': 'Mark as Picked Up',
            'icon': Icons.done_all,
            'color': Colors.green,
            'textColor': Colors.white,
          },
        ];
      case 'out_for_delivery':
        return [
          {
            'status': 'delivered',
            'label': 'Mark as Delivered',
            'icon': Icons.done_all,
            'color': Colors.green,
            'textColor': Colors.white,
          },
        ];
      default:
        return [];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return Colors.amber;
      case 'preparing':
        return Colors.blue;
      case 'ready_for_pickup':
        return AppColors.primaryGreen;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return Icons.pending_actions;
      case 'preparing':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.shopping_bag;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
