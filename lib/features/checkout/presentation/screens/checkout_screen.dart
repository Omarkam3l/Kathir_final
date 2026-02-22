import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import 'choose_address_screen.dart';
import 'payment_method_screen.dart';
=======
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../orders/presentation/screens/order_summary_screen.dart';
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
<<<<<<< HEAD
  late final List<PaymentMethod> _methods;
  int _selected = 0;
  int _slot = 0;
  PurchaseMode _purchaseMode = PurchaseMode.buyer;
  
  // Mock address state - in a real app this would come from an AddressProvider
  final String _addressTitle = 'Work • 212 Kathir Heights';
  final String _addressSubtitle = 'Tech Park, Floor 11';

  @override
  void initState() {
    super.initState();
    _methods = demoPaymentMethods();
  }

  /// Checks if current user can choose buyer/donor mode
  bool _canChooseBuyerDonor(BuildContext context) {
    final user = s.Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final role = (user.userMetadata?['role'] as String?) ?? '';
    return role.toLowerCase() == UserRole.user.name.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<FoodieState>(
          builder: (context, foodie, _) {
            final total = foodie.total;
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                  child: Row(
                    children: [
                      _diamondButton(
                        context,
                        icon: Icons.arrow_back_ios_new,
                        onTap: () {
                          final router = GoRouter.of(context);
                          if (router.canPop()) {
                            router.pop();
                          } else {
                            router.go('/home');
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n.checkoutTitle,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                    child: Column(
                      children: [
                        // Buyer/Donor Selection (only for UserRole.user)
                        if (_canChooseBuyerDonor(context)) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.buyerRole),
                                selected: _purchaseMode == PurchaseMode.buyer,
                                onSelected: (_) => setState(
                                    () => _purchaseMode = PurchaseMode.buyer),
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: Text(l10n.donorRole),
                                selected: _purchaseMode == PurchaseMode.donor,
                                onSelected: (_) => setState(
                                    () => _purchaseMode = PurchaseMode.donor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                        _SectionCard(
                          title: l10n.deliveryAddress,
                          trailing: TextButton(
                            onPressed: () async {
                              await context.push(ChooseAddressScreen.routeName);
                              // In a real app, we'd handle the result here if it returns a selected address
                              // For now, we'll just simulate a change if needed or rely on provider updates
                            },
                            child: Text(l10n.changeAction),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _addressTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _addressSubtitle,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: l10n.deliverySlot,
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(3, (index) {
                              final slots = [
                                l10n.nowSlot,
                                '18:30 - 19:00',
                                l10n.scheduleSlot
                              ];
                              final isSelected = _slot == index;
                              return GestureDetector(
                                onTap: () => setState(() => _slot = index),
                                child: Container(
                                  width: 110,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).textTheme.bodyLarge?.color
                                        : Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slots[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).scaffoldBackgroundColor
                                            : Theme.of(context).textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: l10n.paymentMethod,
                          child: Column(
                            children: [
                              for (int i = 0; i < _methods.length; i++) ...[
                                RadioListTile<int>(
                                  value: i,
                                  groupValue: _selected,
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  onChanged: (value) =>
                                      setState(() => _selected = value ?? 0),
                                  title: Text(
                                    '${_methods[i].brand} • ${_methods[i].maskedNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                    child: Icon(_methods[i].icon,
                                        color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                                if (i != _methods.length - 1)
                                  const Divider(indent: 12, endIndent: 12),
                              ],
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(PaymentMethodScreen.routeName),
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.addNewCard),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: l10n.orderSummary,
                          child: Column(
                            children: [
                              _SummaryRow(label: l10n.subtotalItems(foodie.cartCount), value: foodie.subtotal),
                              _SummaryRow(label: l10n.deliveryLabel, value: foodie.deliveryFee),
                              _SummaryRow(label: l10n.platformFeeLabel, value: foodie.platformFee),
                              const Divider(height: 28),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child:
                                    Icon(Icons.discount, color: Theme.of(context).scaffoldBackgroundColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  l10n.freeDeliveryMessage(50),
                                  style: TextStyle(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(l10n.addCodeAction,
                                    style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(l10n.totalLabel, style: const TextStyle(color: Colors.grey)),
                          const Spacer(),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () {
                            // Handle order placement based on mode
                            final modeText = _purchaseMode == PurchaseMode.buyer
                                ? 'buying'
                                : 'donating';
                            
                            // Show placing order message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.placingOrderMessage(modeText)),
                                duration: const Duration(seconds: 1),
                              ),
                            );

                            // Simulate network delay then complete order
                            Future.delayed(const Duration(seconds: 2), () {
                              if (context.mounted) {
                                foodie.clearCart();
                                
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => AlertDialog(
                                    title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                                    content: Text(
                                      l10n.orderPlacedMessage,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          context.go('/home');
                                        },
                                        child: Text(l10n.doneAction),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            });
                          },
                          child: Text(
                            _purchaseMode == PurchaseMode.buyer
                                ? l10n.placeOrder
                                : l10n.completeDonation,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
=======
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
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
        ),
      ),
    );
  }
<<<<<<< HEAD

  Widget _diamondButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
          ),
        ),
      ),
    );
  }
}

enum PurchaseMode { buyer, donor }

class PaymentMethod {
  final String brand;
  final String maskedNumber;
  final IconData icon;
  const PaymentMethod({required this.brand, required this.maskedNumber, required this.icon});
}

List<PaymentMethod> demoPaymentMethods() => const [
      PaymentMethod(brand: 'Visa', maskedNumber: '•••• 4242', icon: Icons.credit_card),
      PaymentMethod(brand: 'Mastercard', maskedNumber: '•••• 5454', icon: Icons.credit_card),
      PaymentMethod(brand: 'Apple Pay', maskedNumber: 'Linked', icon: Icons.phone_iphone),
    ];

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          const Spacer(),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
=======
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
}
