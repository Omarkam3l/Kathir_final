import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/features/user_home/domain/entities/meal_offer.dart';
import 'package:go_router/go_router.dart';

/// Flash Deals carousel: horizontal cards with image, badge, title, subtitle.
class FlashDealsSection extends StatelessWidget {
  final List<MealOffer> deals;

  const FlashDealsSection({super.key, required this.deals});

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Flash Deals 🔥',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.white
                  : AppColors.darkText,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final m = deals[i];
              return _FlashDealCard(
                offer: m,
                onTap: () => context.push('/meal/${m.id}', extra: m),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FlashDealCard extends StatelessWidget {
  final MealOffer offer;
  final VoidCallback onTap;

  const _FlashDealCard({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final discount = offer.originalPrice > 0
        ? ((offer.originalPrice - offer.donationPrice) / offer.originalPrice)
        : 0.0;
    final badgeLabel = offer.donationPrice == 0
        ? 'FREE ITEM'
        : '${(discount * 100).round()}% OFF';
    final subtitle = offer.minutesLeft <= 60
        ? 'Ends in ${offer.minutesLeft}min'
        : offer.restaurant.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  offer.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.2),
                      AppColors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: offer.donationPrice == 0
                            ? AppColors.white
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: offer.donationPrice == 0
                              ? AppColors.darkText
                              : AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          offer.minutesLeft <= 60
                              ? Icons.schedule
                              : Icons.store,
                          size: 14,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}
