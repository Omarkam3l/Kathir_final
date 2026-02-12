import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../user_home/domain/entities/meal.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_chat_list_viewmodel.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';
import 'package:intl/intl.dart';

class NgoMealDetailScreen extends StatefulWidget {
  final Meal meal;
  const NgoMealDetailScreen({super.key, required this.meal});

  @override
  State<NgoMealDetailScreen> createState() => _NgoMealDetailScreenState();
}

class _NgoMealDetailScreenState extends State<NgoMealDetailScreen> {
  int qty = 1;
  bool isClaiming = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.primaryGreen;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image with App Bar
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'ngo_meal_${meal.id}',
                        child: Image.network(
                          meal.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.restaurant, color: Colors.white54, size: 64),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                meal.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  meal.donationPrice > 0 
                                      ? 'EGP ${meal.donationPrice.toStringAsFixed(2)}'
                                      : 'Free',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                if (meal.originalPrice > meal.donationPrice)
                                  Text(
                                    'EGP ${meal.originalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: subTextColor,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: subTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Restaurant Row
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: surfaceColor,
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                                ),
                                child: Icon(Icons.store, size: 20, color: subTextColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          meal.restaurant.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        if (meal.restaurant.verified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                                        ],
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${meal.restaurant.rating} (${meal.restaurant.reviewsCount} reviews)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  // Get or create conversation with restaurant
                                  final chatListViewModel = NgoChatListViewModel();
                                  final conversationId = await chatListViewModel.getOrCreateConversation(
                                    meal.restaurant.id,
                                  );
                                  
                                  if (conversationId != null && context.mounted) {
                                    context.push(
                                      '/ngo/chat/$conversationId',
                                      extra: {
                                        'conversationId': conversationId,
                                        'restaurantName': meal.restaurant.name,
                                      },
                                    );
                                  }
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: Text(
                                  'Chat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                                  foregroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Badges: Pickup & Impact
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.access_time,
                                iconColor: Colors.orange,
                                title: 'PICKUP BY',
                                value: meal.pickupDeadline != null
                                    ? DateFormat('EEE, h:mm a').format(meal.pickupDeadline!)
                                    : DateFormat('EEE, h:mm a').format(meal.expiry),
                                bgColor: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.shade50,
                                borderColor: isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade100,
                                textColor: textColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.eco,
                                iconColor: Colors.green,
                                title: 'IMPACT',
                                value: 'Saves ${meal.co2Savings > 0 ? meal.co2Savings : "0.5"}kg CO2',
                                bgColor: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
                                borderColor: isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade100,
                                textColor: textColor,
                              ),
                            ),
                          ],
                        ),

                        // Quantity Alert
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Available: ${meal.quantity} ${meal.unit}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.red[300] : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Description
                        const SizedBox(height: 24),
                        Text(
                          'Description',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meal.description.isNotEmpty
                              ? meal.description
                              : 'Freshly prepared meal saved from surplus. Perfect for donation to those in need.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.6,
                            color: subTextColor,
                          ),
                        ),

                        // Ingredients & Allergens
                        if (meal.ingredients.isNotEmpty || meal.allergens.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ingredients & Allergens',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Icon(Icons.info_outline, color: subTextColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...meal.ingredients.map((e) => _buildTag(e, false, isDark, subTextColor)),
                              ...meal.allergens.map((e) => _buildTag(e, true, isDark, subTextColor)),
                            ],
                          ),
                        ],

                        // Pickup Location
                        const SizedBox(height: 24),
                        Text(
                          'Pickup Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: subTextColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                meal.location,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: subTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 100), // Spacing for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? surfaceColor : Colors.white).withValues(alpha: 0.9),
                    border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DONATION',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subTextColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            meal.donationPrice > 0 
                                ? 'EGP ${meal.donationPrice.toStringAsFixed(2)}'
                                : 'Free',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isClaiming ? null : () async {
                              setState(() => isClaiming = true);
                              
                              // Add to cart
                              final cart = context.read<NgoCartViewModel>();
                              await cart.addToCart(meal);
                              
                              setState(() => isClaiming = false);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ ${meal.title} added to cart'),
                                    backgroundColor: AppColors.primaryGreen,
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      textColor: Colors.white,
                                      onPressed: () => context.push('/ngo/cart'),
                                    ),
                                  ),
                                );
                                context.pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isClaiming)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                else
                                  const Icon(Icons.add_shopping_cart, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isClaiming ? 'Adding...' : 'Add to Cart',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, bool isAllergen, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAllergen
            ? (isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade100)
            : (isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAllergen
              ? (isDark ? Colors.orange.withValues(alpha: 0.3) : Colors.orange.shade200)
              : (isDark ? Colors.white10 : Colors.grey.shade300),
        ),
      ),
      child: Text(
        isAllergen ? 'Contains: $text' : text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isAllergen
              ? (isDark ? Colors.orange[200] : Colors.orange[800])
              : textColor,
        ),
      ),
    );
  }
}
