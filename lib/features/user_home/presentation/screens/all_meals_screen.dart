import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../domain/entities/meal_offer.dart';
import '../widgets/meal_card_grid.dart';

class AllMealsScreen extends StatefulWidget {
  final List<MealOffer> meals;

  const AllMealsScreen({super.key, required this.meals});

  @override
  State<AllMealsScreen> createState() => _AllMealsScreenState();
}

class _AllMealsScreenState extends State<AllMealsScreen> {
  String selectedCategory = 'All Items';
  String searchQuery = '';
  
  // Database categories
  final List<String> categories = [
    'All Items',
    'Meals',
    'Bakery',
    'Meat & Poultry',
    'Seafood',
    'Vegetables',
    'Desserts',
    'Groceries',
  ];

  List<MealOffer> get _filteredMeals {
    var meals = widget.meals;
    
    // Filter by category
    if (selectedCategory != 'All Items') {
      meals = meals.where((meal) {
        final mealCategory = meal.category.toLowerCase();
        final selectedCat = selectedCategory.toLowerCase();
        return mealCategory == selectedCat || 
               mealCategory.contains(selectedCat) ||
               selectedCat.contains(mealCategory);
      }).toList();
    }
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      meals = meals.where((meal) {
        return meal.title.toLowerCase().contains(query) ||
               meal.restaurant.name.toLowerCase().contains(query) ||
               meal.category.toLowerCase().contains(query);
      }).toList();
    }
    
    return meals;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A2111) : const Color(0xFFF7F8F6);
    final surfaceColor = isDark ? const Color(0xFF262F1D) : Colors.white;
    final textMain = isDark ? const Color(0xFFEEF3E7) : const Color(0xFF151B0E);
    final borderColor = isDark ? const Color(0xFF3A452D) : const Color(0xFFDDE7D0);
    final foodie = context.watch<FoodieState>();

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
                // Cart icon with badge
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    children: [
                      Center(
                        child: IconButton(
                          onPressed: () => context.go('/cart'),
                          icon: Icon(Icons.shopping_cart_outlined, color: textMain),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (foodie.cartCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${foodie.cartCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
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
            child: CustomScrollView(
              slivers: [
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
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
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for meals, restaurants...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark 
                                ? Colors.grey[500]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search, 
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear, 
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textMain,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),

                // Category Chips
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  color: isSelected ? Colors.white : textMain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Header Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
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
                        Text(
                          '${_filteredMeals.length} items',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Meals Grid - 2 columns
                _filteredMeals.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No meals found',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search or filters',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return MealCardGrid(offer: _filteredMeals[index]);
                            },
                            childCount: _filteredMeals.length,
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
}
