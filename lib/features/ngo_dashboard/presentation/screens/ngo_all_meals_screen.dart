import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_home_viewmodel.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';
import '../widgets/ngo_bottom_nav.dart';
import '../../../user_home/domain/entities/meal.dart';

class NgoAllMealsScreen extends StatefulWidget {
  const NgoAllMealsScreen({super.key});

  @override
  State<NgoAllMealsScreen> createState() => _NgoAllMealsScreenState();
}

class _NgoAllMealsScreenState extends State<NgoAllMealsScreen> {
  String selectedCategory = 'All Items';
  final List<String> categories = [
    'All Items',
    'Bakery',
    'Fast Food',
    'Fruits & Veg',
    'Vegan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NgoHomeViewModel>().loadIfNeeded();
      }
    });
  }

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
      body: SafeArea(
        child: Consumer<NgoHomeViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                // Header
                _buildHeader(surfaceColor, borderColor, textMain),

                // Main Content
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadData(forceRefresh: true),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Search Bar
                              _buildSearchBar(surfaceColor, borderColor, textMain, textSub),
                              const SizedBox(height: 16),

                              // Category Chips
                              _buildCategoryChips(surfaceColor, borderColor, textSub),
                              const SizedBox(height: 24),

                              // Header Row
                              _buildHeaderRow(textMain),
                              const SizedBox(height: 20),

                              // Meals List
                              if (viewModel.filteredMeals.isEmpty)
                                _buildEmptyState(textSub)
                              else
                                ...viewModel.filteredMeals.map((meal) => _buildMealCard(
                                      meal,
                                      isDark,
                                      surfaceColor,
                                      textMain,
                                      textSub,
                                      borderColor,
                                    )),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const NgoBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader(Color surfaceColor, Color borderColor, Color textMain) {
    final cart = context.watch<NgoCartViewModel>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Balance the cart icon
          Text(
            'Available Meals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textMain,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/ngo/cart'),
            child: Stack(
              children: [
                Icon(Icons.shopping_cart_outlined, color: textMain, size: 24),
                if (cart.cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.cartCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSearchBar(Color surfaceColor, Color borderColor, Color textMain, Color textSub) {
    final viewModel = context.read<NgoHomeViewModel>();
    
    return Container(
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
        onChanged: viewModel.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search for meals, restaurants...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: textSub.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(Icons.search, color: textSub),
          suffixIcon: const Icon(Icons.tune, color: AppColors.primaryGreen, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: textMain,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(Color surfaceColor, Color borderColor, Color textSub) {
    return SizedBox(
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
                color: isSelected ? AppColors.primaryGreen : surfaceColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : borderColor,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : textSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow(Color textMain) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Nearby Surplus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
        Row(
          children: [
            Text(
              'Sort by: Distance',
              style: TextStyle(
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
    );
  }

  Widget _buildEmptyState(Color textSub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.no_food, size: 64, color: textSub.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No meals available',
              style: TextStyle(color: textSub),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(
    Meal meal,
    bool isDark,
    Color surfaceColor,
    Color textMain,
    Color textSub,
    Color borderColor,
  ) {
    final cart = context.watch<NgoCartViewModel>();
    
    return GestureDetector(
      onTap: () => context.push('/ngo/meal/${meal.id}', extra: meal),
      child: Container(
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: meal.imageUrl.isNotEmpty
                      ? Image.network(
                          meal.imageUrl,
                          width: double.infinity,
                          height: 176,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
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
                          style: TextStyle(
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
                        color: meal.quantity <= 3 ? Colors.red : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: (meal.quantity <= 3 ? Colors.red : AppColors.primaryGreen)
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        meal.quantity <= 3 ? 'Only ${meal.quantity} left' : 'New',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
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
                    style: TextStyle(
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
                      Expanded(
                        child: Text(
                          meal.restaurant.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                            if (meal.originalPrice > meal.donationPrice)
                              Text(
                                'EGP ${meal.originalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSub,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.red[400],
                                ),
                              ),
                            Text(
                              meal.donationPrice > 0
                                  ? 'EGP ${meal.donationPrice.toStringAsFixed(2)}'
                                  : 'FREE',
                              style: const TextStyle(
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
                            onPressed: () async {
                              await cart.addToCart(meal);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ ${meal.title} added to cart'),
                                    backgroundColor: AppColors.primaryGreen,
                                    duration: const Duration(seconds: 1),
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      textColor: Colors.white,
                                      onPressed: () => context.push('/ngo/cart'),
                                    ),
                                  ),
                                );
                              }
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
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 176,
      color: AppColors.primaryGreen.withValues(alpha: 0.1),
      child: const Icon(
        Icons.restaurant,
        size: 48,
        color: AppColors.primaryGreen,
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textSub,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
