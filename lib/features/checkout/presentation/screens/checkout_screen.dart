import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../orders/presentation/screens/order_summary_screen.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'card'; // card, wallet, cod

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors
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
        title: Text('Payment',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: surfaceColor.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: Consumer<FoodieState>(builder: (context, foodie, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFooterRow(
                  'Subtotal',
                  '\$${foodie.subtotal.toStringAsFixed(2)}',
                  subTextColor,
                  textColor),
              const SizedBox(height: 8),
              _buildFooterRow(
                  'Service Fee',
                  '\$${foodie.platformFee.toStringAsFixed(2)}',
                  subTextColor,
                  textColor),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Amount',
                          style: TextStyle(fontSize: 12, color: subTextColor)),
                      Text('\$${foodie.total.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ],
                  ),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        // Capture data before clearing
                        final items = List<CartItem>.from(foodie.cartItems);
                        final total = foodie.total;
                        final subtotal = foodie.subtotal;
                        final deliveryFee = foodie.deliveryFee;

                        // Clear Cart
                        foodie.clearCart();

                        // Navigate using pushReplacement so user can't go back to checkout with empty cart
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => OrderSummaryScreen(
                              items: items,
                              total: total,
                              subtotal: subtotal,
                              deliveryFee: deliveryFee,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Pay Now',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
      body: Consumer<FoodieState>(
        builder: (context, foodie, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Summary',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text('Review your order before paying.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: subTextColor)),
                const SizedBox(height: 16),

                // Order Items
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...foodie.cartItems.map((item) => _buildOrderItem(item,
                          textColor, subTextColor, primaryColor, borderColor)),
                      const SizedBox(height: 16),
                      // Delivery Info
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                            border:
                                Border(top: BorderSide(color: borderColor))),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                                Icon(Icons.local_shipping,
                                    size: 16, color: subTextColor),
                                'Delivery Fee',
                                '\$${foodie.deliveryFee.toStringAsFixed(2)}',
                                textColor,
                                subTextColor),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                                Icon(Icons.location_on,
                                    size: 16, color: subTextColor),
                                'Delivery to',
                                '12 Hassan Sabry St.',
                                textColor,
                                subTextColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Method',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, size: 12, color: primaryColor),
                          SizedBox(width: 4),
                          Text('Secured',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPaymentOption(
                    'card',
                    'Credit / Debit Card',
                    'Visa, Mastercard (via Paymob)',
                    Icons.credit_card,
                    surfaceColor,
                    borderColor,
                    primaryColor,
                    textColor,
                    subTextColor),
                const SizedBox(height: 8),
                _buildPaymentOption(
                    'wallet',
                    'Mobile Wallet',
                    'Vodafone, Orange, Etisalat Cash',
                    Icons.account_balance_wallet,
                    surfaceColor,
                    borderColor,
                    primaryColor,
                    textColor,
                    subTextColor),
                const SizedBox(height: 8),
                _buildPaymentOption(
                    'cod',
                    'Cash on Delivery',
                    'Pay cash when order arrives',
                    Icons.payments,
                    surfaceColor,
                    borderColor,
                    primaryColor,
                    textColor,
                    subTextColor),

                // Discount
                const SizedBox(height: 24),
                Text('DISCOUNT',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subTextColor,
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor)),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Add promo code',
                            prefixIcon:
                                Icon(Icons.sell_outlined, color: subTextColor),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceColor,
                        foregroundColor: primaryColor,
                        elevation: 0,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, Color textColor, Color subTextColor,
      Color primaryColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                  image: NetworkImage(item.meal.imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(item.meal.title,
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('\$${item.lineTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                Text(item.meal.restaurant.name,
                    style: TextStyle(fontSize: 12, color: subTextColor)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Qty: ${item.qty}',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subTextColor)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Surplus Food',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subTextColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(Widget icon, String label, String value,
      Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, color: subTextColor)),
          ],
        ),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildFooterRow(
      String label, String value, Color subTextColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor)),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildPaymentOption(
      String value,
      String title,
      String subtitle,
      IconData icon,
      Color surfaceColor,
      Color borderColor,
      Color primaryColor,
      Color textColor,
      Color subTextColor) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? primaryColor : borderColor,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? primaryColor : subTextColor, width: 2),
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, color: textColor)),
                      Icon(icon, color: subTextColor),
                    ],
                  ),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
