import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../checkout/data/services/order_service.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String orderId;
  const OrderSummaryScreen({required this.orderId, super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _orderService = OrderService();
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderService.getOrder(widget.orderId);
      debugPrint('📦 Order loaded:');
      debugPrint('   Order ID: ${order['id']}');
      debugPrint('   Delivery Type: ${order['delivery_type']}');
      debugPrint('   Delivery Address: ${order['delivery_address']}');
      debugPrint('   NGO ID: ${order['ngo_id']}');
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading order: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text('Order Summary', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: bgColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Order not found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unable to load order details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: textSub,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final orderItems = _order!['order_items'] as List;
    final restaurant = _order!['restaurants'];
    final createdAt = DateTime.parse(_order!['created_at']);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Order Summary', style: GoogleFonts.plusJakartaSans()),
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.padding(context, all: 16),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: ResponsiveUtils.iconSize(context, 60),
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Success Message
            Text(
              'Order Placed Successfully!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: ResponsiveUtils.fontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'Your order has been confirmed',
              style: GoogleFonts.plusJakartaSans(
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: textSub,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            // Order Details Card
            Container(
              padding: ResponsiveUtils.padding(context, all: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: ResponsiveUtils.borderRadius(context, 16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Number - Fixed overflow with proper constraints
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Number',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: textSub,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          _order!['order_number'] ?? 'N/A',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),

                  // Order Date - Fixed overflow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Date',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: textSub,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),

                  // Restaurant
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restaurant',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: textSub,
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      Flexible(
                        child: Text(
                          restaurant?['restaurant_name'] ?? 'Restaurant',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),

                  // Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: textSub,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.spacing(context, 10),
                          vertical: ResponsiveUtils.spacing(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: ResponsiveUtils.borderRadius(context, 12),
                        ),
                        child: Text(
                          (_order!['status'] as String).toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Delivery Information
            if (_order!['delivery_type'] != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Delivery Information',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: ResponsiveUtils.fontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Container(
                padding: ResponsiveUtils.padding(context, all: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: ResponsiveUtils.borderRadius(context, 16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery Type
                    Row(
                      children: [
                        Icon(
                          _order!['delivery_type'] == 'delivery'
                              ? Icons.local_shipping
                              : _order!['delivery_type'] == 'pickup'
                                  ? Icons.store
                                  : Icons.volunteer_activism,
                          size: ResponsiveUtils.iconSize(context, 20),
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                        Flexible(
                          child: Text(
                            _order!['delivery_type'] == 'delivery'
                                ? 'Home Delivery'
                                : _order!['delivery_type'] == 'pickup'
                                    ? 'Self Pickup'
                                    : 'Donation to NGO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Delivery Address - check for both null and empty string
                    if (_order!['delivery_address'] != null && 
                        (_order!['delivery_address'] as String).trim().isNotEmpty &&
                        _order!['delivery_address'] != 'Self Pickup' &&
                        _order!['delivery_address'] != 'Donated to NGO') ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: ResponsiveUtils.iconSize(context, 18),
                            color: textSub,
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                          Expanded(
                            child: Text(
                              _order!['delivery_address'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: ResponsiveUtils.fontSize(context, 13),
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            ],

            // Order Items
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Order Items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: ResponsiveUtils.fontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            ...orderItems.map((item) {
              final meal = item['meals'];
              return Container(
                margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
                padding: ResponsiveUtils.padding(context, all: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: ResponsiveUtils.borderRadius(context, 12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    // Meal Image
                    ClipRRect(
                      borderRadius: ResponsiveUtils.borderRadius(context, 8),
                      child: meal?['image_url'] != null
                          ? Image.network(
                              meal['image_url'],
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey[300],
                                child: Icon(Icons.restaurant, size: ResponsiveUtils.iconSize(context, 24)),
                              ),
                            )
                          : Container(
                              width: 55,
                              height: 55,
                              color: Colors.grey[300],
                              child: Icon(Icons.restaurant, size: ResponsiveUtils.iconSize(context, 24)),
                            ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),

                    // Meal Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['meal_title'] ?? 'Meal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: ResponsiveUtils.fontSize(context, 13),
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            'Qty: ${item['quantity']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: textSub,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Text(
                      'EGP ${((item['unit_price'] ?? 0.0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Total
            Container(
              padding: ResponsiveUtils.padding(context, all: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: ResponsiveUtils.borderRadius(context, 16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  _buildRow('Subtotal', _order!['subtotal'], textSub, textColor),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  _buildRow('Service Fee', _order!['service_fee'], textSub, textColor),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  _buildRow('Delivery Fee', _order!['delivery_fee'], textSub, textColor),
                  Divider(height: ResponsiveUtils.spacing(context, 24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 17),
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'EGP ${(_order!['total_amount'] ?? 0.0).toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 19),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/my-orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: ResponsiveUtils.borderRadius(context, 12),
                  ),
                ),
                child: Text(
                  'View My Orders',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: ResponsiveUtils.borderRadius(context, 12),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value, Color labelColor, Color valueColor) {
    final numValue = (value is num) ? value : 0.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: labelColor,
          ),
        ),
        Text(
          'EGP ${numValue.toStringAsFixed(2)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
