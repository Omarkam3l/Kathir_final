import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../viewmodels/favorites_viewmodel.dart';

class FavoritesScreenNew extends StatefulWidget {
  const FavoritesScreenNew({super.key});

  @override
  State<FavoritesScreenNew> createState() => _FavoritesScreenNewState();
}

class _FavoritesScreenNewState extends State<FavoritesScreenNew> {
  int _selectedTab = 0; // 0 = Restaurants, 1 = Meal Categories

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesViewModel>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textMain = isDark ? Colors.white : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                  Expanded(
                    child: Text(
                      'Favorites',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement search
                    },
                    icon: const Icon(Icons.search, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ],
              ),
            ),

            // Segmented Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentButton(
                        icon: Icons.storefront,
                        label: 'Restaurants',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildSegmentButton(
                        icon: Icons.category,
                        label: 'Meal Categories',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildRestaurantsTab(cardBg, textMain, textSub, borderColor, isDark)
                  : _buildMealCategoriesTab(cardBg, textMain, textSub, borderColor, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF4B5563) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.primaryGreen
                  : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryGreen
                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsTab(
    Color cardBg,
    Color textMain,
    Color textSub,
    Color borderColor,
    bool isDark,
  ) {
    return Consumer<FavoritesViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: textSub),
                const SizedBox(height: 16),
                Text(
                  'Error loading favorites',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, color: textSub),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => viewModel.loadFavorites(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (viewModel.favoriteMeals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: textSub),
                const SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textSub,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start adding meals to your favorites!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSub),
                ),
              ],
            ),
          );
        }

        // Group meals by restaurant
        final mealsByRestaurant = <String, List<dynamic>>{};
        for (final meal in viewModel.favoriteMeals) {
          final restaurantName = meal.restaurant.name;
          if (!mealsByRestaurant.containsKey(restaurantName)) {
            mealsByRestaurant[restaurantName] = [];
          }
          mealsByRestaurant[restaurantName]!.add(meal);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Favorited Restaurants',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                Text(
                  'View Map',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Restaurant Cards
            ...mealsByRestaurant.entries.map((entry) {
              final restaurantName = entry.key;
              final meals = entry.value;
              final firstMeal = meals.first;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left side - Info
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Favorited badge
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FAVORITED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Restaurant name
                          Text(
                            restaurantName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Info
                          Text(
                            '${meals.length} meal${meals.length > 1 ? 's' : ''} available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: textSub,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // View Menu button
                          ElevatedButton.icon(
                            onPressed: () {
                              // Add all meals to cart
                              final foodieState = context.read<FoodieState>();
                              for (final meal in meals) {
                                foodieState.addToCart(meal);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${meals.length} meal${meals.length > 1 ? 's' : ''} added to cart',
                                  ),
                                  backgroundColor: AppColors.primaryGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_cart, size: 18),
                            label: Text(
                              'Add to cart',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right side - Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstMeal.imageUrl,
                        width: 128,
                        height: 128,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 128,
                          height: 128,
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          child: const Icon(
                            Icons.restaurant,
                            size: 48,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildMealCategoriesTab(
    Color cardBg,
    Color textMain,
    Color textSub,
    Color borderColor,
    bool isDark,
  ) {
    final categories = [
      {
        'icon': Icons.bakery_dining,
        'name': 'Bakery',
        'subtitle': 'Fresh bread & pastries',
        'enabled': true,
      },
      {
        'icon': Icons.egg_alt,
        'name': 'Proteins',
        'subtitle': 'Meat, eggs & dairy',
        'enabled': true,
      },
      {
        'icon': Icons.eco,
        'name': 'Vegetables',
        'subtitle': 'Farm fresh produce',
        'enabled': true,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Header
        Text(
          'Recurring Meal Categories',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Notifications enabled for these types',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: textSub,
          ),
        ),
        const SizedBox(height: 16),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == categories.length) {
              // Add New card
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937).withOpacity(0.5)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add New',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track more types',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final category = categories[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    category['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['subtitle'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
