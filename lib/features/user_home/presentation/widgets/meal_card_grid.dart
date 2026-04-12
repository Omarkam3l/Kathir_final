import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/core/utils/responsive_utils.dart';
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

  String _getRelativeTime(DateTime expiry) {
    final now = DateTime.now();
    final difference = expiry.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    }
  }

  String _formatPickupTime(DateTime? pickupTime) {
    if (pickupTime == null) return '';
    final h = pickupTime.hour;
    final m = pickupTime.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.surfaceDark : AppColors.white;
    final textMain = isDark ? AppColors.white : AppColors.darkText;
    const muted = AppColors.grey;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    final restaurantLocation = offer.restaurant.addressText ?? offer.location;
    final pickupTimeStr = _formatPickupTime(offer.pickupTime);
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
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image + "X left" badge - responsive height
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        offer.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
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
                      // Expiry timer badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
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
              ),
              // Content - responsive padding
              Expanded(
                child: Padding(
                  padding: ResponsiveUtils.padding(context, all: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title - responsive font, max 2 lines
                      Text(
                        offer.title.isEmpty ? 'Delicious Meal' : offer.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          fontWeight: FontWeight.w700,
                          color: textMain,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                      // Restaurant - responsive font
                      Text(
                        offer.restaurant.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveUtils.fontSize(context, 10),
                          color: muted,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      // Location - responsive font
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: ResponsiveUtils.iconSize(context, 11),
                            color: AppColors.primary,
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 2)),
                          Flexible(
                            child: Text(
                              restaurantLocation,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: ResponsiveUtils.fontSize(context, 8.5),
                                fontWeight: FontWeight.w500,
                                color: muted,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Pickup time if available
                      if (pickupTimeStr.isNotEmpty) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 3)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: ResponsiveUtils.iconSize(context, 10),
                                color: AppColors.primary,
                              ),
                              SizedBox(width: ResponsiveUtils.spacing(context, 2)),
                              Text(
                                'Pickup: $pickupTimeStr',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: ResponsiveUtils.fontSize(context, 8),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Price row with button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Original price - responsive font, only show if different
                                if (offer.originalPrice > offer.donationPrice)
                                  Text(
                                    'EGP ${offer.originalPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: ResponsiveUtils.fontSize(context, 10),
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF9CA3AF),
                                      decoration: TextDecoration.lineThrough,
                                      height: 1.15,
                                    ),
                                  ),
                                // Discounted price - responsive font
                                Text(
                                  'EGP ${offer.donationPrice.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: ResponsiveUtils.fontSize(context, 15),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
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
}

class _AddButton extends StatelessWidget {
  final MealOffer offer;

  const _AddButton({required this.offer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final buttonSize = ResponsiveUtils.iconSize(context, 30);

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
        borderRadius: ResponsiveUtils.borderRadius(context, 8),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: ResponsiveUtils.borderRadius(context, 8),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              size: ResponsiveUtils.iconSize(context, 18),
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
