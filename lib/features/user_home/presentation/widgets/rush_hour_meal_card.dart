import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/meal_offer.dart';
import '../../../profile/presentation/providers/foodie_state.dart';

/// Rush Hour Meal Card - Clean and organized design
class RushHourMealCard extends StatelessWidget {
  final MealOffer offer;
  final VoidCallback? onTap;
  final bool showRushHourBadge;

  const RushHourMealCard({
    super.key,
    required this.offer,
    this.onTap,
    this.showRushHourBadge = true,
  });

  String _getRelativeTime(DateTime expiry) {
    final now = DateTime.now();
    final difference = expiry.difference(now);

    if (difference.isNegative) return 'Expired';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF2D241B) : Colors.white;
    final textMain = isDark ? Colors.white : const Color(0xFF1B140D);
    final relativeTime = _getRelativeTime(offer.expiry);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push('/meal/${offer.id}', extra: offer),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              _buildImageSection(relativeTime),
              // Content Section
              _buildContentSection(context, textMain, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(String relativeTime) {
    // Calculate discount percentage
    final discountPercent = offer.originalPrice > 0
        ? ((offer.originalPrice - offer.donationPrice) / offer.originalPrice * 100).round()
        : 0;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              offer.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.restaurant,
                  size: 40,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            // Discount Badge (Top Left) - Red badge with discount percentage
            if (showRushHourBadge && discountPercent > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$discountPercent%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            // Quantity Badge (Top Right)
            if (offer.quantity > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: offer.quantity <= 2 ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${offer.quantity} left',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Timer Badge (Bottom Right)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      relativeTime,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, Color textMain, bool isDark) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Meal Title
            Flexible(
              child: Text(
                offer.title.isEmpty ? 'Delicious Meal' : offer.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            
            // Restaurant Name
            Text(
              offer.restaurant.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            
            // Price Section with Add Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Price Row - Discounted + Original in same line
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Current Price (After Discount)
                      Flexible(
                        child: Text(
                          'EGP ${offer.donationPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Original Price (strikethrough) - next to discounted price
                      if (offer.originalPrice > offer.donationPrice) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              'EGP ${offer.originalPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white38 : Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                
                // Add Button (+ icon only)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<FoodieState>().addToCart(offer);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${offer.title} added to cart'),
                            backgroundColor: AppColors.primaryGreen,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
