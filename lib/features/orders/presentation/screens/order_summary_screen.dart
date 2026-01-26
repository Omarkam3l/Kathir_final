import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../profile/presentation/providers/foodie_state.dart';

class OrderSummaryScreen extends StatelessWidget {
  static const routeName = '/order-summary';

  final List<CartItem> items;
  final double total;
  final double subtotal;
  final double deliveryFee;
  final String orderId;

  const OrderSummaryScreen({
    super.key,
    required this.items,
    required this.total,
    required this.subtotal,
    required this.deliveryFee,
    this.orderId = '#KATH-8921', // Mock ID for now
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    const primaryColor = AppColors.primary;
    final borderColor = isDark ? Colors.white10 : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Order Summary',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: surfaceColor.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.go('/home'), // Go home on back
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Need Help?'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 20),
                        SizedBox(width: 8),
                        Text('Track Live Map'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/home'),
              child:
                  Text('Back to Home', style: TextStyle(color: subTextColor)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCRQV7qW-7PljqTSvHwDmsQ9DXr-gsc5sjzwxfw4gP0ezVRztuxkH7QYvVManLBGQMw0pWYieYPEmbwFLjjRfixXKXJsfKv22dRZWtA0ZbxZwTw6tjaN1TE2VHq35-ma0ytlB_Y82aSbUQ7lJ7TkdjNua3179jvNHEbaLH_wWjC6X6a22f_xH_UFzYjTCl1yfUPh91-voNHMmZc4Uo4ZQ0UDVq_d08GObxXtElUONgArv8rAglYGFcdxc0LrH92f8_XzQjdoz0KlA0'), // Use placeholder from HTML or asset
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('CONFIRMED',
                                  style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Order Placed Successfully!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const Text('Thank you for your donation.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Impact Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: textColor, fontSize: 14),
                          children: [
                            const TextSpan(
                                text: 'Your contribution saved approx. '),
                            TextSpan(
                                text: '1.2kg',
                                style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' of food from waste.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Tracker
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tracking Order',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 16),
                  _buildTrackerStep(
                      'Order Accepted',
                      'Restaurant has confirmed your order.',
                      true,
                      true,
                      primaryColor,
                      textColor,
                      subTextColor),
                  _buildTrackerStep(
                      'Food Being Packed',
                      'Preparing for handover.',
                      true,
                      true,
                      primaryColor,
                      textColor,
                      subTextColor,
                      isActive: true),
                  _buildTrackerStep('Driver on the way', '', false, true,
                      primaryColor, textColor, subTextColor),
                  _buildTrackerStep('Delivered / Donated', '', false, false,
                      primaryColor, textColor, subTextColor,
                      isLast: true),
                ],
              ),
            ),

            Divider(color: borderColor, thickness: 8),

            // Order Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Details',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        // Items
                        ...items.map((item) => Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(color: borderColor))),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text('${item.qty}x',
                                            style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12)),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.meal.title,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor)),
                                          Text(item.meal.restaurant.name,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: subTextColor)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text('\$${item.lineTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor)),
                                ],
                              ),
                            )),

                        // Meta Data
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50],
                          child: Column(
                            children: [
                              _buildMetaRow(
                                  'Order ID', orderId, textColor, subTextColor),
                              const SizedBox(height: 8),
                              _buildMetaRow('Date', 'Oct 24, 2023, 10:30 AM',
                                  textColor, subTextColor), // Mock Date
                              const SizedBox(height: 8),
                              _buildMetaRow('Payment', 'Paid via Card',
                                  textColor, subTextColor),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(color: borderColor),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Amount',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor)),
                                  Text('\$${total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 16)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildTrackerStep(String title, String subtitle, bool isCompleted,
      bool showLine, Color primaryColor, Color textColor, Color subTextColor,
      {bool isActive = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? primaryColor
                      : (isActive ? Colors.white : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isCompleted || isActive
                          ? primaryColor
                          : Colors.grey[300]!,
                      width: 2),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : (isActive
                        ? Center(
                            child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle)))
                        : null),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color: isCompleted ? primaryColor : Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted || isActive
                              ? textColor
                              : subTextColor)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
      String label, String value, Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: subTextColor)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w500, color: textColor, fontSize: 13)),
      ],
    );
  }
}
