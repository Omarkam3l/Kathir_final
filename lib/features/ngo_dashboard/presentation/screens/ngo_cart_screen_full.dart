import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';

/// NGO Cart Screen - Full Implementation
/// Displays claimed meals pending pickup with checkout functionality
class NgoCartScreenFull extends StatefulWidget {
  const NgoCartScreenFull({super.key});

  @override
  State<NgoCartScreenFull> createState() => _NgoCartScreenFullState();
}

class _NgoCartScreenFullState extends State<NgoCartScreenFull> {
  @override
  void initState() {
    super.initState();
    // Load cart on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NgoCartViewModel>().loadCart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Consumer<NgoCartViewModel>(
          builder: (context, cart, _) {
            // Show loading state
            if (cart.isLoading && cart.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (cart.isEmpty) {
              return _buildEmptyCart(context, isDark);
            }

            return Stack(
              children: [
                Column(
                  children: [
                    _buildAppBar(context, cart, isDark),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => cart.loadCart(),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCartMeta(cart, isDark),
                              const SizedBox(height: 16),
                              _buildCartItems(cart, isDark),
                              const SizedBox(height: 24),
                              _buildBillSummary(cart, isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildCheckoutButton(context, cart, isDark),
              ],
            );
          },
        ),
      ),
      // No bottom navigation on cart screen
    );
  }

  Widget _buildAppBar(BuildContext context, NgoCartViewModel cart, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  // If cart is not empty, go back to previous page
                  // If cart is empty, this won't be called (empty state has its own back button)
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/ngo/home');
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                'My Cart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _showClearCartDialog(context, cart),
            child: const Text(
              'Clear All',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartMeta(NgoCartViewModel cart, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, 
            size: 16, 
            color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '${cart.cartCount} Items in your Cart',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(NgoCartViewModel cart, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cart.cartItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = cart.cartItems[index];
        return _buildCartItemCard(context, item, cart, isDark);
      },
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem item,
    NgoCartViewModel cart,
    bool isDark,
  ) {
    final meal = item.meal;
    final canAddMore = item.quantity < meal.quantity;
    final isAtMax = item.quantity >= meal.quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: meal.imageUrl.isNotEmpty
                  ? Image.network(
                      meal.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 40),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Meal details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal.restaurant.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      _getExpiryText(meal.expiry),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Free (Donation)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                onPressed: () async {
                  await cart.removeFromCart(meal.id);
                },
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
                    _qtyBtn(context, '-', () async => await cart.decrement(meal.id), isDark),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    _qtyBtn(
                      context,
                      '+',
                      canAddMore ? () async => await cart.increment(meal.id) : () {},
                      isDark,
                      isAdd: true,
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

  Widget _qtyBtn(
    BuildContext context,
    String label,
    VoidCallback onTap,
    bool isDark, {
    bool isAdd = false,
    bool isDisabled = false,
  }) {
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
                  ? AppColors.primaryGreen
                  : (isDark ? Colors.white10 : Colors.white)),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isAdd && !isDisabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  )
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

  Widget _buildBillSummary(NgoCartViewModel cart, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
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
            'Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow(
            'Total Items',
            '${cart.cartCount} meals',
            isDark,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Subtotal',
            'Free',
            isDark,
            valueColor: AppColors.primaryGreen,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Service Fee',
            'Waived',
            isDark,
            valueColor: AppColors.primaryGreen,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Delivery Fee',
            'Free',
            isDark,
            valueColor: AppColors.primaryGreen,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CO₂ Savings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.eco, size: 20, color: AppColors.primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    '${cart.co2Savings.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
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

  Widget _buildCheckoutButton(
    BuildContext context,
    NgoCartViewModel cart,
    bool isDark,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2E22).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                ),
              ),
            ),
            child: ElevatedButton(
              onPressed: () => context.push('/ngo/checkout', extra: cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primaryGreen.withValues(alpha: 0.25),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cart.cartCount} items',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => context.go('/ngo/home'),
              ),
              const SizedBox(width: 8),
              Text(
                'My Cart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 120,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 24),
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse available meals and add them\nto your cart to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go('/ngo/meals'),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Browse Meals'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getExpiryText(DateTime expiry) {
    final now = DateTime.now();
    final difference = expiry.difference(now);

    if (difference.inHours < 1) {
      return 'Expires in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'Expires in ${difference.inHours} hours';
    } else {
      return 'Expires in ${difference.inDays} days';
    }
  }

  void _showClearCartDialog(BuildContext context, NgoCartViewModel cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await cart.clearCart();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart cleared')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
