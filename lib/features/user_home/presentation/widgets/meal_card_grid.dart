import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/profile/presentation/providers/foodie_state.dart';
import 'package:go_router/go_router.dart';

/// Compact meal card for 2-column grid: image, "X left", title, restaurant, location, prices, add.
class MealCardGrid extends StatelessWidget {
  final MealOffer offer;
  final VoidCallback? onTap;

  const MealCardGrid({
    super.key,
    required this.offer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.surfaceDark : AppColors.white;
    final textMain = isDark ? AppColors.white : AppColors.darkText;
    const muted = AppColors.grey;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    final pickupStr = _pickupString(offer.expiry);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push('/meal/${offer.id}', extra: offer),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image + "X left" badge
              SizedBox(
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        offer.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.restaurant,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    if (offer.quantity > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: offer.quantity <= 2
                                ? AppColors.error
                                : AppColors.warning,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${offer.quantity} left',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: offer.quantity <= 2
                                  ? AppColors.white
                                  : AppColors.darkText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title.isEmpty ? 'Delicious Meal' : offer.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.restaurant.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${offer.location} • $pickupStr',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$${offer.originalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: muted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  '\$${offer.donationPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _AddButton(offer: offer),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pickupString(DateTime expiry) {
    final h = expiry.hour;
    final m = expiry.minute;
    return 'Pick up by ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _AddButton extends StatelessWidget {
  final MealOffer offer;

  const _AddButton({required this.offer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.searchBackground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<FoodieState>().addToCart(offer);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${offer.title} added to cart'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}
