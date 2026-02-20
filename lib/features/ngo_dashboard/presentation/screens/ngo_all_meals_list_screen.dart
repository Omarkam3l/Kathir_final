import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_home_viewmodel.dart';
import '../widgets/ngo_meal_card.dart';

/// NGO All Meals List Screen - Shows all meals in a list view
class NgoAllMealsListScreen extends StatelessWidget {
  final List<dynamic> meals;
  final String title;

  const NgoAllMealsListScreen({
    super.key,
    required this.meals,
    this.title = 'All Meals',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

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
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
                    'No meals available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return NgoMealCard(
                  meal: meal,
                  isDark: isDark,
                  onClaim: () {
                    final viewModel = context.read<NgoHomeViewModel>();
                    viewModel.claimMeal(meal, context);
                  },
                );
              },
            ),
    );
  }
}
