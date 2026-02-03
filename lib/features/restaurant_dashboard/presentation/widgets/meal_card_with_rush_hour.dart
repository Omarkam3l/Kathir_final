import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/meal_with_effective_discount.dart';

/// Meal card that displays effective pricing with rush hour indicator
class MealCardWithRushHour extends StatelessWidget {
  final MealWithEffectiveDiscount meal;
  final VoidCallback? onTap;

  const MealCardWithRushHour({
    required this.meal,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D241B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: meal.rushHourActiveNow
                ? AppColors.primaryGreen.withOpacity(0.3)
                : (isDark
                    ? const Color(0xFF4A3F33)
                    : const Color(0xFFE7E5E4)),
            width: meal.rushHourActiveNow ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: meal.imageUrl != null
                  ? Image.network(
                      meal.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    meal.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B140D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Category & Quantity
                  Row(
                    children: [
                      if (meal.category != null) ...[
                        Text(
                          meal.category!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${meal.quantityAvailable} left',
                        style: TextStyle(
                          fontSize: 12,
                          color: meal.quantityAvailable < 5
                              ? Colors.orange
                              : (isDark ? Colors.white54 : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Pricing
                  Row(
                    children: [
                      // Effective Price
                      Text(
                        currencyFormat.format(meal.effectivePrice),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: meal.rushHourActiveNow
                              ? AppColors.primaryGreen
                              : (isDark ? Colors.white : const Color(0xFF1B140D)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Original Price (strikethrough)
                      if (meal.effectivePrice < meal.originalPrice)
                        Text(
                          currencyFormat.format(meal.originalPrice),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Discount Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: meal.rushHourActiveNow
                              ? AppColors.primaryGreen
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${meal.effectiveDiscountPercentage}% OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Rush Hour Badge
                  if (meal.rushHourActiveNow) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rush Hour Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(
        Icons.restaurant,
        color: Colors.grey[600],
        size: 32,
      ),
    );
  }
}
