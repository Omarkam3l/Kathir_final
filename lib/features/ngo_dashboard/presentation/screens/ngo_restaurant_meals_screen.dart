import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';
import '../widgets/ngo_meal_card.dart';

/// NGO Restaurant Meals Screen - Shows all meals from a specific restaurant
class NgoRestaurantMealsScreen extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final List<dynamic> meals;

  const NgoRestaurantMealsScreen({
    super.key,
    required this.restaurant,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    // Separate meals into sections
    final freeMeals = meals.where((m) => m.donationPrice == 0).toList();
    final paidMeals = meals.where((m) => m.donationPrice > 0).toList()
      ..sort((a, b) => a.donationPrice.compareTo(b.donationPrice));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant['name'].toString(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  (restaurant['rating'] as double).toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: meals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No meals available from this restaurant',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Free Meals Section
                if (freeMeals.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.volunteer_activism, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Free Meals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...freeMeals.map((meal) => NgoMealCard(
                        meal: meal,
                        isDark: isDark,
                        onClaim: () {
                          final cart = context.read<NgoCartViewModel>();
                          cart.addToCart(meal);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${meal.title} added to cart'),
                              backgroundColor: AppColors.primaryGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      )),
                  const SizedBox(height: 24),
                ],

                // Paid Meals Section
                if (paidMeals.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_offer, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Available Meals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...paidMeals.map((meal) => NgoMealCard(
                        meal: meal,
                        isDark: isDark,
                        onClaim: () {
                          final cart = context.read<NgoCartViewModel>();
                          cart.addToCart(meal);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${meal.title} added to cart'),
                              backgroundColor: AppColors.primaryGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      )),
                ],
              ],
            ),
    );
  }
}
