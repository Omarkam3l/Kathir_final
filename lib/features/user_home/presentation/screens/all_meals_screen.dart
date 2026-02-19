import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../domain/entities/meal_offer.dart';

class AllMealsScreen extends StatefulWidget {
  final List<MealOffer> meals;

  const AllMealsScreen({super.key, required this.meals});

  @override
  State<AllMealsScreen> createState() => _AllMealsScreenState();
}

class _AllMealsScreenState extends State<AllMealsScreen> {
  String selectedCategory = 'All Items';
  final List<String> categories = [
    'All Items',
    'Bakery',
    'Fast Food',
    'Fruits & Veg',
    'Vegan',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A2111) : const Color(0xFFF7F8F6);
    final surfaceColor = isDark ? const Color(0xFF262F1D) : Colors.white;
    final textMain = isDark ? const Color(0xFFEEF3E7) : const Color(0xFF151B0E);
    final textSub = isDark ? const Color(0xFFAEBFA0) : const Color(0xFF5C6F47);
    final borderColor = isDark ? const Color(0xFF3A452D) : const Color(0xFFDDE7D0);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.8),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Icon(Icons.arrow_back, color: textMain),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Available Meals',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/cart'),
                  icon: Stack(
                    children: [
                      Icon(Icons.shopping_cart_outlined, color: textMain),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: surfaceColor, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for meals, restaurants...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textSub.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(Icons.search, color: textSub),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune, color: AppColors.primaryGreen, size: 20),
                        onPressed: () {
                          // TODO: Show filter options
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : borderColor,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected ? Colors.white : textSub,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Surplus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Sort by: Distance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Meals List
                ...widget.meals.map((meal) => _buildMealCard(
                      meal,
                      isDark,
                      surfaceColor,
                      textMain,
                      textSub,
                      borderColor,
                    )),
                const SizedBox(height: 16),

                // Show More Button
                OutlinedButton(
                  onPressed: () {
                    // TODO: Load more meals
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SHOW MORE RESULTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textSub,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    MealOffer meal,
    bool isDark,
    Color surfaceColor,
    Color textMain,
    Color textSub,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: () => context.push('/meal/${meal.id}', extra: meal),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    meal.imageUrl,
                    width: double.infinity,
                    height: 176,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 176,
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.restaurant,
                        size: 48,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                // Rating Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meal.restaurant.rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Quantity Badge
                if (meal.quantity <= 5)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: meal.quantity <= 3
                            ? Colors.red
                            : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: (meal.quantity <= 3
                                    ? Colors.red
                                    : AppColors.primaryGreen)
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        meal.quantity <= 3
                            ? 'Only ${meal.quantity} left'
                            : 'New',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Restaurant
                Text(
                  meal.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.storefront, size: 16, color: textSub),
                    const SizedBox(width: 4),
                    Text(
                      meal.restaurant.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSub,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: textSub.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      'Cairo, Egypt',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (meal.category.isNotEmpty)
                      _buildTag(meal.category, isDark, borderColor, textSub),
                    _buildTag(
                      'Pickup: ${meal.expiry.hour}:${meal.expiry.minute.toString().padLeft(2, '0')} ${meal.expiry.hour >= 12 ? 'PM' : 'AM'}',
                      isDark,
                      borderColor,
                      textSub,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price and Add Button
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EGP ${meal.originalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSub,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.red[400],
                            ),
                          ),
                          Text(
                            'EGP ${meal.donationPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            context.read<FoodieState>().addToCart(meal);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${meal.title} added to cart'),
                                backgroundColor: AppColors.primaryGreen,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
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
    );
  }

  Widget _buildTag(String label, bool isDark, Color borderColor, Color textSub) {
    final bgColor = isDark ? const Color(0xFF1A2111) : const Color(0xFFF7F8F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textSub,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
