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
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image + "X left" badge - exactly 128px height
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 128,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
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
                      if (offer.quantity > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
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
              ),
              // Content - exactly 12px padding
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - 14px font
                    Text(
                      offer.title.isEmpty ? 'Delicious Meal' : offer.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Restaurant - 12px font
                    Text(
                      offer.restaurant.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: muted,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Location - 10px font
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: muted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Cairo, Egypt • $pickupStr',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: muted,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Price row with button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Original price - 12px font
                              Text(
                                'EGP ${offer.originalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9CA3AF),
                                  decoration: TextDecoration.lineThrough,
                                  height: 1.2,
                                ),
                              ),
                              // Discounted price - 18px font
                              Text(
                                'EGP ${offer.donationPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _AddButton(offer: offer),
                      ],
                    ),
                  ],
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
    final bg = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

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
          child: const Center(
            child: Icon(Icons.add, size: 20, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
