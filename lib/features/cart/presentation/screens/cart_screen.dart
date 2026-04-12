import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../user_home/domain/entities/restaurant.dart';
import '../../../../core/utils/app_colors.dart';

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

  // Group cart items by restaurant
  Map<String, List<CartItem>> _groupByRestaurant(List<CartItem> items) {
    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      final restaurantId = item.meal.restaurant.id;
      grouped.putIfAbsent(restaurantId, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const accentColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Consumer<FoodieState>(
          builder: (context, foodie, _) {
            if (foodie.cartItems.isEmpty) {
              return _CartEmptyState(isDark: isDark);
            }

            // Group items by restaurant
            final groupedItems = _groupByRestaurant(foodie.cartItems);

            return Stack(
              children: [
                Column(
                  children: [
                    // Top App Bar
                    _buildAppBar(context, foodie, textColor, accentColor, isDark),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cart Items Grouped by Restaurant
                            ...groupedItems.entries.map((entry) {
                              final restaurant = entry.value.first.meal.restaurant;
                              final items = entry.value;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Restaurant Header
                                  _RestaurantHeader(
                                    restaurant: restaurant,
                                    itemCount: items.length,
                                    isDark: isDark,
                                    textColor: textColor,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Items for this restaurant
                                  ...items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CartItemCard(
                                      item: item,
                                      isDark: isDark,
                                      textColor: textColor,
                                      accentColor: accentColor,
                                    ),
                                  )),
                                  
                                  const SizedBox(height: 16),
                                ],
                              );
                            }),

                            // Distribution Method
                            const SizedBox(height: 8),
                            Text(
                              'Distribution Method',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DistributionMethodSelector(
                              foodie: foodie,
                              isDark: isDark,
                              accentColor: accentColor,
                              textColor: textColor,
                            ),

                            // Bill Summary
                            const SizedBox(height: 24),
                            _BillDetailsCard(
                              foodie: foodie,
                              isDark: isDark,
                              textColor: textColor,
                              accentColor: accentColor,
                            ),
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
                    accentColor: accentColor,
                    textColor: textColor,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => context.go('/home'),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Cart',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${foodie.cartCount} ${foodie.cartCount == 1 ? 'item' : 'items'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              final foodie = context.read<FoodieState>();
              foodie.clearCart();
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(
              'Clear',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Restaurant Header Widget
class _RestaurantHeader extends StatelessWidget {
  final Restaurant restaurant;
  final int itemCount;
  final bool isDark;
  final Color textColor;

  const _RestaurantHeader({
    required this.restaurant,
    required this.itemCount,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = restaurant.latitude != null && restaurant.longitude != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.08),
            AppColors.primaryGreen.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasLocation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restaurant.addressText ?? 'Restaurant Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Cart Item Card Widget
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isDark;
  final Color textColor;
  final Color accentColor;

  const _CartItemCard({
    required this.item,
    required this.isDark,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final foodie = context.watch<FoodieState>();
    final meal = item.meal;
    
    final canAddMore = item.qty < meal.quantity;
    final isAtMax = item.qty >= meal.quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
              width: 90,
              height: 90,
              child: Image.network(
                meal.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[100],
                  child: Icon(Icons.restaurant, color: Colors.grey[400], size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'EGP ${meal.donationPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EGP ${meal.originalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyBtn(context, Icons.remove, () => foodie.decrement(meal.id)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.qty}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor,
                              ),
                            ),
                          ),
                          _qtyBtn(
                            context,
                            Icons.add,
                            canAddMore ? () => foodie.increment(meal.id) : () {},
                            isAdd: true,
                            accentColor: accentColor,
                            isDisabled: isAtMax,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]),
                      onPressed: () => foodie.removeFromCart(meal.id),
                    ),
                  ],
                ),
                if (isAtMax)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Maximum quantity reached',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
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

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onTap,
      {bool isAdd = false, Color? accentColor, bool isDisabled = false}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[300]
              : (isAdd ? accentColor : Colors.white),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDisabled
              ? Colors.grey[500]
              : (isAdd ? Colors.white : Colors.grey[700]),
        ),
      ),
    );
  }
}

// Distribution Method Selector
class _DistributionMethodSelector extends StatelessWidget {
  final FoodieState foodie;
  final bool isDark;
  final Color accentColor;
  final Color textColor;

  const _DistributionMethodSelector({
    required this.foodie,
    required this.isDark,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      if (isDonate) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.volunteer_activism, size: 16, color: accentColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tagColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bill Details Card
class _BillDetailsCard extends StatelessWidget {
  final FoodieState foodie;
  final bool isDark;
  final Color textColor;
  final Color accentColor;

  const _BillDetailsCard({
    required this.foodie,
    required this.isDark,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _row('Item Total', 'EGP ${foodie.subtotal.toStringAsFixed(2)}', textColor),
          const SizedBox(height: 8),
          _row(
            'Service Fee',
            foodie.platformFee == 0
                ? 'Free'
                : 'EGP ${foodie.platformFee.toStringAsFixed(2)}',
            foodie.platformFee == 0 ? accentColor : textColor,
            isValueStyled: foodie.platformFee == 0,
          ),
          const SizedBox(height: 8),
          _row(
            'Delivery Fee',
            foodie.deliveryFee == 0
                ? 'Free'
                : 'EGP ${foodie.deliveryFee.toStringAsFixed(2)}',
            foodie.deliveryFee == 0 ? accentColor : textColor,
            isValueStyled: foodie.deliveryFee == 0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To Pay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'EGP ${foodie.total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool isValueStyled = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Sticky Checkout Bar
class _StickyCheckoutBar extends StatelessWidget {
  final FoodieState foodie;
  final bool isDark;
  final Color textColor;
  final Color accentColor;

  const _StickyCheckoutBar({
    required this.foodie,
    required this.isDark,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'EGP ${foodie.total.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    context.go('/checkout');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Checkout',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Empty Cart State
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
            const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
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
