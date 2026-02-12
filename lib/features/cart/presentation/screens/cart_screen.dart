import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart'; // Make sure this path will be valid

class CartScreen extends StatefulWidget {
  static const routeName = '/cart';
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart from database when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodieState>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors (Standard App Colors)
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const accentColor = AppColors.primary; // RED

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Consumer<FoodieState>(
          builder: (context, foodie, _) {
            if (foodie.cartItems.isEmpty) {
              return _CartEmptyState(isDark: isDark);
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // Top App Bar
                    _buildAppBar(
                        context, foodie, textColor, accentColor, isDark),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Meta Text
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text:
                                            '${foodie.cartCount} Items in your Cart'),
                                  ],
                                ),
                                style: GoogleFonts.plusJakartaSans(
                                  color:
                                      isDark ? accentColor : Colors.grey[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            // Cart Items
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: foodie.cartItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) => _CartItemCard(
                                item: foodie.cartItems[i],
                                isDark: isDark,
                                surfaceColor: surfaceColor,
                                textColor: textColor,
                                accentColor: accentColor,
                              ),
                            ),

                            // Coupon Section
                            _CouponsSection(
                                isDark: isDark,
                                surfaceColor: surfaceColor,
                                textColor: textColor,
                                accentColor: accentColor),

                            // Distribution Method
                            const SizedBox(height: 24),
                            Text(
                              'Distribution Method',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DistributionMethodSelector(
                                foodie: foodie,
                                isDark: isDark,
                                surfaceColor: surfaceColor,
                                accentColor: accentColor,
                                textColor: textColor),

                            // Bill Summary
                            const SizedBox(height: 24),
                            _BillDetailsCard(
                                foodie: foodie,
                                isDark: isDark,
                                surfaceColor: surfaceColor,
                                textColor: textColor,
                                accentColor: accentColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Sticky Checkout Button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _StickyCheckoutBar(
                      foodie: foodie,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      accentColor: accentColor,
                      textColor: textColor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, FoodieState foodie, Color textColor,
      Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withOpacity(0.95),
        border: Border(
            bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(width: 8),
              Text(
                'My Cart',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              final foodie = context.read<FoodieState>();
              foodie.clearCart();
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... _CartItemCard
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;

  const _CartItemCard({
    required this.item,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final foodie = context.watch<FoodieState>();
    final meal = item.meal;
    
    // Calculate discount safely - handle free meals (0 price)
    final discount = meal.originalPrice > 0
        ? ((meal.originalPrice - meal.donationPrice) / meal.originalPrice * 100).round()
        : 100; // Free meal = 100% off
    
    // Check if we can add more
    final canAddMore = item.qty < meal.quantity;
    final isAtMax = item.qty >= meal.quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                meal.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: accentColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        meal.restaurant.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'EGP ${meal.donationPrice.isNaN || meal.donationPrice.isInfinite ? "0.00" : meal.donationPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: 'EGP ${meal.originalPrice.isNaN || meal.originalPrice.isInfinite ? "0.00" : meal.originalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.grey),
                onPressed: () => foodie.removeFromCart(meal.id),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _qtyBtn(context, '-', () => foodie.decrement(meal.id)),
                    SizedBox(
                      width: 24,
                      child: Text('${item.qty}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor)),
                    ),
                    _qtyBtn(
                      context, 
                      '+', 
                      canAddMore ? () => foodie.increment(meal.id) : () {},
                      isAdd: true, 
                      accentColor: accentColor,
                      isDisabled: isAtMax,
                    ),
                  ],
                ),
              ),
              if (isAtMax)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Max qty',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, String label, VoidCallback onTap,
      {bool isAdd = false, Color? accentColor, bool isDisabled = false}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[300]
              : (isAdd
                  ? accentColor
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : Colors.white)),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isAdd && !isDisabled
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 2)
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDisabled
                  ? Colors.grey[500]
                  : (isAdd ? Colors.white : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }
}

// ... _CouponsSection
class _CouponsSection extends StatelessWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;

  const _CouponsSection(
      {required this.isDark,
      required this.surfaceColor,
      required this.textColor,
      required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Offers & Discounts',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.local_offer, color: accentColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                      color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Apply',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, 
                        color: accentColor,
                        fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DistributionMethodSelector extends StatelessWidget {
  final FoodieState foodie;
  final bool isDark;
  final Color surfaceColor;
  final Color accentColor;
  final Color textColor;

  const _DistributionMethodSelector({
    required this.foodie,
    required this.isDark,
    required this.surfaceColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final current = foodie.deliveryMethod;

    return Column(
      children: [
        _buildOption(
          context,
          value: DeliveryMethod.pickup,
          groupValue: current,
          title: 'Self Pickup',
          subtitle: 'Pick up from restaurant',
          tag: 'Free',
          tagColor: AppColors.primaryGreen,
          borderColor: current == DeliveryMethod.pickup
              ? accentColor
              : Colors.grey[200]!,
          bgColor: Colors.white,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          value: DeliveryMethod.delivery,
          groupValue: current,
          title: 'Delivery',
          subtitle: 'Delivered to your saved address',
          tag: 'EGP +2.99',
          tagColor: Colors.grey[600]!,
          borderColor: current == DeliveryMethod.delivery
              ? accentColor
              : Colors.grey[200]!,
          bgColor: Colors.white,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          value: DeliveryMethod.donate,
          groupValue: current,
          title: 'Donate to NGO',
          subtitle: 'Food will be sent to deserved people',
          tag: 'Fee Waived',
          tagColor: AppColors.primaryGreen,
          isDonate: true,
          borderColor: current == DeliveryMethod.donate
              ? accentColor
              : Colors.grey[200]!,
          bgColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required DeliveryMethod value,
    required DeliveryMethod groupValue,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required Color borderColor,
    required Color bgColor,
    bool isDonate = false,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => foodie.setDeliveryMethod(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor)),
                      if (isDonate) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.volunteer_activism,
                            size: 16, color: accentColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(tag,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tagColor)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillDetailsCard extends StatelessWidget {
  final FoodieState foodie;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;

  const _BillDetailsCard({
    required this.foodie,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text('Bill Details',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          _row('Item Total', 'EGP ${foodie.subtotal.toStringAsFixed(2)}',
              textColor),
          const SizedBox(height: 8),
          _row(
              'Service Fee',
              foodie.platformFee == 0
                  ? 'Free'
                  : 'EGP ${foodie.platformFee.toStringAsFixed(2)}',
              foodie.platformFee == 0 ? accentColor : textColor,
              isValueStyled: foodie.platformFee == 0),
          const SizedBox(height: 8),
          _row(
              'Delivery Fee',
              foodie.deliveryFee == 0
                  ? 'Free'
                  : 'EGP ${foodie.deliveryFee.toStringAsFixed(2)}',
              foodie.deliveryFee == 0 ? accentColor : textColor,
              isValueStyled: foodie.deliveryFee == 0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('To Pay',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              Text('EGP ${foodie.total.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color,
      {bool isValueStyled = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _StickyCheckoutBar extends StatelessWidget {
  final FoodieState foodie;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;

  const _StickyCheckoutBar({
    required this.foodie,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey[100]!)),
          ),
          child: ElevatedButton(
            onPressed: () {
              // Proceed to Checkout Screen
              context.go('/checkout');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: accentColor.withOpacity(0.25),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Checkout',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ' EGP ${foodie.total.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartEmptyState extends StatelessWidget {
  final bool isDark;
  const _CartEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Your cart is empty',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Browse Meals'),
            ),
          ],
        ),
      ),
    );
  }
}

