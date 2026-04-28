import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/core/utils/responsive_utils.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:kathir_final/features/profile/presentation/providers/foodie_state.dart';
import 'package:go_router/go_router.dart';

/// Glass meal card for 2-column grid
class MealCardGrid extends StatelessWidget {
  final MealOffer offer;
  final VoidCallback? onTap;

  const MealCardGrid({super.key, required this.offer, this.onTap});

  String _relativeTime(DateTime expiry) {
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}mo';
  }

  String _pickupTime(DateTime? t) {
    if (t == null) return '';
    final h = t.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:${t.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF0F1B3D);
    const muted = Color(0xFF6B7A99);
    final location = offer.restaurant.addressText ?? offer.location;
    final pickup = _pickupTime(offer.pickupTime);
    final timeLeft = _relativeTime(offer.expiry);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push('/meal/${offer.id}', extra: offer),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassCardBg, // ← استخدام اللون من AppColors
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.glassCardBorder, // ← استخدام اللون من AppColors
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B7BF6).withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image ──────────────────────────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                              child: const Icon(Icons.restaurant, size: 40, color: AppColors.primary),
                            ),
                          ),
                          // Qty badge
                          if (offer.quantity > 0)
                            Positioned(
                              top: 8, left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: offer.quantity <= 2 ? AppColors.error : AppColors.warning,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${offer.quantity} left',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: offer.quantity <= 2 ? Colors.white : AppColors.darkText,
                                  ),
                                ),
                              ),
                            ),
                          // Timer badge
                          Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 12, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(timeLeft, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: ResponsiveUtils.padding(context, all: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title.isEmpty ? 'Delicious Meal' : offer.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: ResponsiveUtils.fontSize(context, 13),
                              fontWeight: FontWeight.w700,
                              color: textMain, height: 1.15,
                            ),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                          Text(
                            offer.restaurant.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: ResponsiveUtils.fontSize(context, 10),
                              color: muted, height: 1.15,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                size: ResponsiveUtils.iconSize(context, 11),
                                color: AppColors.primary),
                              SizedBox(width: ResponsiveUtils.spacing(context, 2)),
                              Flexible(
                                child: Text(location,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: ResponsiveUtils.fontSize(context, 8.5),
                                    fontWeight: FontWeight.w500, color: muted, height: 1.15,
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (pickup.isNotEmpty) ...[
                            SizedBox(height: ResponsiveUtils.spacing(context, 3)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time,
                                    size: ResponsiveUtils.iconSize(context, 10),
                                    color: AppColors.primary),
                                  SizedBox(width: ResponsiveUtils.spacing(context, 2)),
                                  Text('Pickup: $pickup',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: ResponsiveUtils.fontSize(context, 8),
                                      fontWeight: FontWeight.w600, color: AppColors.primary, height: 1.15,
                                    )),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          // ── Price row ──────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (offer.originalPrice > offer.donationPrice)
                                      Text(
                                        'EGP ${offer.originalPrice.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: ResponsiveUtils.fontSize(context, 10),
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B7A99).withValues(alpha: 0.5),
                                          decoration: TextDecoration.lineThrough,
                                          height: 1.15,
                                        ),
                                      ),
                                    Text(
                                      'EGP ${offer.donationPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: ResponsiveUtils.fontSize(context, 15),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary, height: 1.15,
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
    final size = ResponsiveUtils.iconSize(context, 30);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<FoodieState>().addToCart(offer);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${offer.title} added to cart'),
            duration: const Duration(seconds: 1),
          ));
        },
        borderRadius: ResponsiveUtils.borderRadius(context, 8),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: ResponsiveUtils.borderRadius(context, 8),
          ),
          child: Center(
            child: Icon(Icons.add,
              size: ResponsiveUtils.iconSize(context, 18),
              color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
