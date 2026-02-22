import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
<<<<<<< HEAD
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
=======
import '../../../../core/utils/app_colors.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart'; // Make sure this path will be valid
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f

class CartScreen extends StatelessWidget {
  static const routeName = '/cart';
  const CartScreen({super.key});

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
      backgroundColor: bgColor,
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
                                            '${foodie.cartCount} Items in Cart from '),
                                    const TextSpan(
                                        text: 'Green Leaf Bistro',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
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
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
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
                onPressed: () => context.pop(),
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
            onPressed: () {},
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
<<<<<<< HEAD
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
=======
    final foodie = context.read<FoodieState>();
    final meal = item.meal;
    final discount =
        ((meal.originalPrice - meal.donationPrice) / meal.originalPrice * 100)
            .round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.05))
            : Border.all(color: Colors.transparent),
      ),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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
<<<<<<< HEAD
                  l10n.myCart,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.itemCount(itemCount)} • ${l10n.deliverToWork}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
=======
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
                        text: '\$${meal.donationPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: '\$${meal.originalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey),
                      ),
                    ],
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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
                    _qtyBtn(context, '+', () => foodie.increment(meal.id),
                        isAdd: true, accentColor: accentColor),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, String label, VoidCallback onTap,
      {bool isAdd = false, Color? accentColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isAdd
              ? accentColor
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.white),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isAdd
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
              color: isAdd ? Colors.white : Colors.grey[600],
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
<<<<<<< HEAD
        const _CartAppBar(itemCount: 0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.cartEmpty,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cartEmptyMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: Theme.of(context).elevatedButtonTheme.style,
                    onPressed: () => context.push('/meals'),
                    child: Text(
                      l10n.browseMeals,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
=======
        const SizedBox(height: 24),
        Text(
          'Offers & Discounts',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(Icons.local_offer, color: accentColor),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
              ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter promo code',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                      color: textColor, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Apply',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, color: accentColor)),
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
<<<<<<< HEAD
    final l10n = AppLocalizations.of(context)!;
    final foodie = context.read<FoodieState>();
    final meal = item.meal;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
=======
    final current = foodie.deliveryMethod;

    return Column(
      children: [
        _buildOption(
          context,
          value: DeliveryMethod.pickup,
          groupValue: current,
          title: 'Self Pickup',
          subtitle: 'Pick up from Green Leaf Bistro (0.8 mi)',
          tag: 'Free',
          tagColor: Colors.green,
          borderColor: current == DeliveryMethod.pickup
              ? accentColor
              : (isDark ? Colors.white10 : Colors.grey[200]!),
          bgColor: surfaceColor,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          value: DeliveryMethod.delivery,
          groupValue: current,
          title: 'Delivery',
          subtitle: 'Delivered to your saved address',
          tag: '+\$2.99',
          tagColor: Colors.grey,
          borderColor: current == DeliveryMethod.delivery
              ? accentColor
              : (isDark ? Colors.white10 : Colors.grey[200]!),
          bgColor: surfaceColor,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          value: DeliveryMethod.donate,
          groupValue: current,
          title: 'Donate to NGO',
          subtitle: 'Food will be sent to "Hope Shelter"',
          tag: 'Fee Waived',
          tagColor: accentColor,
          isDonate: true,
          borderColor: current == DeliveryMethod.donate
              ? accentColor
              : (isDark ? Colors.white10 : Colors.grey[200]!),
          bgColor: surfaceColor,
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
          gradient: isDonate
              ? LinearGradient(colors: [bgColor, borderColor.withOpacity(0.05)])
              : null,
        ),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
        child: Row(
          children: [
            Radio<DeliveryMethod>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => foodie.setDeliveryMethod(v!),
              activeColor: accentColor,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor)),
                          if (isDonate) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.volunteer_activism,
                                size: 16, color: accentColor),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              (isDonate ? tagColor : tagColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(tag,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDonate ? tagColor : tagColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
<<<<<<< HEAD
                  Text(l10n.restaurantLocation(meal.restaurant.name, meal.location),
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('\$${meal.donationPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => foodie.decrement(meal.id),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Text(l10n.pieces(item.qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: () => foodie.increment(meal.id),
                        icon: const Icon(Icons.add_circle_outline),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        onPressed: () => foodie.removeFromCart(meal.id),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
=======
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: Colors.grey)),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                ],
              ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          _summaryRow(context, l10n.subtotalLabel, subtotal),
          _summaryRow(context, l10n.deliveryLabel, deliveryFee),
          _summaryRow(context, l10n.platformFeeLabel, platformFee),
          const Divider(height: 24),
          _summaryRow(context, l10n.totalLabel, total, bold: true),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Analytics: Track checkout initiation
                debugPrint('Analytics: Checkout initiated');
                context.push('/checkout');
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.checkoutTitle),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
=======
          Text('Bill Details',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          _row('Item Total', '\$${foodie.subtotal.toStringAsFixed(2)}',
              textColor),
          const SizedBox(height: 8),
          _row(
              'Service Fee',
              foodie.platformFee == 0
                  ? 'Free'
                  : '\$${foodie.platformFee.toStringAsFixed(2)}',
              foodie.platformFee == 0 ? accentColor : textColor,
              isValueStyled: foodie.platformFee == 0),
          const SizedBox(height: 8),
          _row(
              'Delivery Fee',
              foodie.deliveryFee == 0
                  ? 'Free'
                  : '\$${foodie.deliveryFee.toStringAsFixed(2)}',
              foodie.deliveryFee == 0 ? accentColor : textColor,
              isValueStyled: foodie.deliveryFee == 0),
          const SizedBox(height: 8),
          _row('Taxes & Charges', '\$0.00', textColor), // Mocked for now
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
              Text('\$${foodie.total.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentColor)),
            ],
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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
            color: (isDark ? surfaceColor : Colors.white).withOpacity(0.95),
            border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey[100]!)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5)),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // Proceed to Checkout Screen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );
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
                    '\$${foodie.total.toStringAsFixed(2)}',
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
    return Center(
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
    );
  }
}
