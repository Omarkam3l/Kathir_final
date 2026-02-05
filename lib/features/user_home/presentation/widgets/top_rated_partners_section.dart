import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/user_home/domain/entities/restaurant.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top Rated Partners: horizontal circles with avatar, name, star rating.
class TopRatedPartnersSection extends StatelessWidget {
  final List<Restaurant> restaurants;

  const TopRatedPartnersSection({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.surfaceDark : AppColors.white;
    final textMain = isDark ? AppColors.white : AppColors.darkText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Top Rated Partners',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textMain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final r = restaurants[i];
              final isFirst = i == 0;
              return _PartnerChip(
                restaurant: r,
                isFeatured: isFirst,
                cardColor: card,
                textColor: textMain,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PartnerChip extends StatelessWidget {
  final Restaurant restaurant;
  final bool isFeatured;
  final Color cardColor;
  final Color textColor;

  const _PartnerChip({
    required this.restaurant,
    required this.isFeatured,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRestaurantMeals(context),
      child: SizedBox(
        width: 72,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
              border: Border.all(
                color: isFeatured ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: restaurant.logoUrl != null && restaurant.logoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      restaurant.logoUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          restaurant.name.isNotEmpty
                              ? restaurant.name[0].toUpperCase()
                              : 'R',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      restaurant.name.isNotEmpty
                          ? restaurant.name[0].toUpperCase()
                          : 'R',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            restaurant.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 10, color: AppColors.rating),
                const SizedBox(width: 2),
                Text(
                  restaurant.rating.toStringAsFixed(1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textColor,
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

  void _showRestaurantMeals(BuildContext context) async {
    final supabase = Supabase.instance.client;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF102216) : Colors.white;
          
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${restaurant.rating.toStringAsFixed(1)} • Available meals',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Meals list
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: supabase
                        .from('meals')
                        .select('''
                          *,
                          restaurants:restaurant_id (
                            restaurant_name,
                            rating,
                            profile_id
                          )
                        ''')
                        .eq('restaurant_id', restaurant.id)
                        .eq('status', 'active')
                        .gt('quantity_available', 0)
                        .gt('expiry_date', DateTime.now().toIso8601String())
                        .limit(20),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGreen),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading meals',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final meals = snapshot.data ?? [];
                      
                      if (meals.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No meals available',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          return _buildMealCard(context, meal, isDark);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, dynamic meal, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    
    return GestureDetector(
      onTap: () {
        // Close the bottom sheet first
        Navigator.pop(context);
        
        // Convert meal data to MealOffer entity
        final restaurantData = meal['restaurants'] as Map<String, dynamic>?;
        final mealOffer = MealOffer(
          id: meal['id'],
          title: meal['title'] ?? 'Meal',
          location: meal['location'] ?? 'Cairo, Egypt',
          imageUrl: meal['image_url'] ?? '',
          originalPrice: (meal['original_price'] as num?)?.toDouble() ?? 0.0,
          donationPrice: (meal['discounted_price'] as num?)?.toDouble() ?? 0.0,
          quantity: meal['quantity_available'] ?? 0,
          expiry: DateTime.parse(meal['expiry_date']),
          restaurant: Restaurant(
            id: restaurantData?['profile_id'] ?? meal['restaurant_id'],
            name: restaurantData?['restaurant_name'] ?? restaurant.name,
            rating: (restaurantData?['rating'] as num?)?.toDouble() ?? restaurant.rating,
          ),
        );
        
        // Navigate to meal detail with the MealOffer entity
        context.push('/meal/${meal['id']}', extra: mealOffer);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2D4A3A) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: meal['image_url'] != null && meal['image_url'].isNotEmpty
                    ? Image.network(
                        meal['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(Icons.restaurant, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['title'] ?? 'Meal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meal['quantity_available']} portions left',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'EGP ${(meal['discounted_price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (meal['original_price'] != null && 
                          (meal['original_price'] as num) > (meal['discounted_price'] as num))
                        Text(
                          'EGP ${(meal['original_price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}
