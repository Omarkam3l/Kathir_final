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
      final vm = context.read<FavoritesViewModel>();
      vm.loadFavorites();
      vm.loadCategoryPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
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
            _buildAppBar(context, textMain),

            // Segmented Buttons
            _buildSegmentedButtons(isDark, textSub),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: _selectedTab == 0
                    ? _buildRestaurantsTab(context, isDark, cardBg, textMain, textSub, borderColor)
                    : _buildMealCategoriesTab(context, isDark, cardBg, textMain, textSub, borderColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color textMain) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.go('/home');
            },
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
    );
  }

  Widget _buildSegmentedButtons(bool isDark, Color textSub) {
    final segmentBg = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final selectedBg = isDark ? const Color(0xFF4B5563) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: segmentBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedTab == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront,
                        size: 18,
                        color: _selectedTab == 0 ? AppColors.primary : textSub,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Restaurants',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 0 ? AppColors.primary : textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedTab == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category,
                        size: 18,
                        color: _selectedTab == 1 ? AppColors.primary : textSub,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Meal Categories',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 1 ? AppColors.primary : textSub,
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
    );
  }

  Widget _buildRestaurantsTab(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color borderColor,
  ) {
    final vm = context.watch<FavoritesViewModel>();
    final favoriteRestaurants = vm.favoriteRestaurants;
    final favoriteMeals = vm.favoriteMeals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Favorite Meals Section
        if (favoriteMeals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Favorite Meals',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
          ),
          ...favoriteMeals.map((meal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildMealCard(
                context,
                meal,
                cardBg,
                textMain,
                textSub,
                borderColor,
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Favorited Restaurants Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
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
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to map view
                },
                child: Text(
                  'View Map',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Restaurant Cards
        if (favoriteRestaurants.isEmpty && favoriteMeals.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.favorite_border, size: 64, color: textSub),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (favoriteRestaurants.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No favorite restaurants yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: textSub,
                ),
              ),
            ),
          )
        else
          ...favoriteRestaurants.map((restaurant) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildRestaurantCard(
                context,
                restaurant,
                cardBg,
                textMain,
                textSub,
                borderColor,
              ),
            );
          }),

        const SizedBox(height: 100), // Space for bottom nav
      ],
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    dynamic restaurant,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color borderColor,
  ) {
    final foodie = context.read<FoodieState>();
    final vm = context.read<FavoritesViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
          // Left side - Info and Button
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Favorited Badge with unfavorite button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'FAVORITED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: textSub,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await vm.unfavoriteRestaurant(restaurant.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${restaurant.name} removed from favorites'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Restaurant Name
                Text(
                  restaurant.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 4),

                // Distance and Status
                Text(
                  '${restaurant.rating.toStringAsFixed(1)} ⭐ • Open now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: textSub,
                  ),
                ),
                const SizedBox(height: 16),

                // View Menu Button
                ElevatedButton.icon(
                  onPressed: () async {
                    // Get all meals from this restaurant and add to cart
                    final meals = await vm.getMealsForRestaurant(restaurant.id);
                    for (final meal in meals) {
                      foodie.addToCart(meal);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${meals.length} meals added to cart'),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('Add All Menu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Container(
              width: 128,
              height: 128,
              color: AppColors.primary.withValues(alpha: 0.1),
              child: restaurant.logoUrl != null && restaurant.logoUrl!.isNotEmpty
                  ? Image.network(
                      restaurant.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    dynamic meal,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color borderColor,
  ) {
    final foodie = context.read<FoodieState>();
    final vm = context.read<FavoritesViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
          // Left side - Info and Button
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Favorited Badge with unfavorite button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'FAVORITED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: textSub,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await vm.toggleFavorite(meal.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${meal.title} removed from favorites'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Meal Name
                Text(
                  meal.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Restaurant Name and Price
                Text(
                  '${meal.restaurant.name} • EGP ${meal.donationPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: textSub,
                  ),
                ),
                const SizedBox(height: 16),

                // Add to Cart Button
                ElevatedButton.icon(
                  onPressed: () {
                    foodie.addToCart(meal);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${meal.title} added to cart'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Container(
              width: 128,
              height: 128,
              color: AppColors.primary.withValues(alpha: 0.1),
              child: meal.imageUrl.isNotEmpty
                  ? Image.network(
                      meal.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCategoriesTab(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color borderColor,
  ) {
    final vm = context.watch<FavoritesViewModel>();
    final allCategories = vm.availableCategories;
    
    // Only show subscribed categories
    final subscribedCategoryCards = allCategories
        .where((cat) => vm.isCategorySubscribed(cat['name'] as String))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meal Category Notifications',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get notified when new meals are added',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: textSub,
                ),
              ),
            ],
          ),
        ),

        // Category Grid (only subscribed + Add New button)
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: subscribedCategoryCards.length + 1, // +1 for Add New
            itemBuilder: (context, index) {
              if (index < subscribedCategoryCards.length) {
                final category = subscribedCategoryCards[index];
                return _buildCategoryCard(
                  category['icon'] as IconData,
                  category['name'] as String,
                  category['desc'] as String,
                  true, // Always true since we only show subscribed
                  cardBg,
                  textMain,
                  textSub,
                  borderColor,
                  () async {
                    // Unsubscribe
                    await vm.toggleCategorySubscription(category['name'] as String);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unsubscribed from ${category['name']} notifications'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              } else {
                // Add New button
                return _buildAddNewCard(context, isDark, textSub, borderColor, vm);
              }
            },
          ),
        ),

        const SizedBox(height: 100), // Space for bottom nav
      ],
    );
  }

  Widget _buildCategoryCard(
    IconData icon,
    String name,
    String description,
    bool isEnabled,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color borderColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? AppColors.primary : borderColor,
            width: isEnabled ? 2 : 1,
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
            // Icon and Check
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isEnabled 
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? AppColors.primary : Colors.grey,
                    size: 24,
                  ),
                ),
                if (isEnabled)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
              ],
            ),
            const Spacer(),

            // Name and Description
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCard(
    BuildContext context,
    bool isDark,
    Color textSub,
    Color borderColor,
    FavoritesViewModel vm,
  ) {
    final addBg = isDark ? const Color(0xFF374151).withValues(alpha: 0.5) : const Color(0xFFF9FAFB);
    final dashedBorder = isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);

    return GestureDetector(
      onTap: () => _showAddCategoryDialog(context, vm),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: addBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dashedBorder,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: textSub,
                size: 24,
              ),
            ),
            const Spacer(),

            // Text
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
                color: textSub.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, FavoritesViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories = vm.availableCategories;
    
    // Filter out already subscribed categories
    final availableCategories = allCategories
        .where((cat) => !vm.isCategorySubscribed(cat['name'] as String))
        .toList();

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already subscribed to all categories'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Add Category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select categories to get notifications',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Category list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCategories.length,
                    itemBuilder: (context, index) {
                      final category = availableCategories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            await vm.toggleCategorySubscription(category['name'] as String);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Subscribed to ${category['name']} notifications'),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    category['icon'] as IconData,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category['name'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.darkText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        category['desc'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
