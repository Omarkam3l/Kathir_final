import 'package:flutter/material.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../domain/entities/daily_offer.dart';

/// Card widget for displaying daily offer badges
class OfferBadgeCard extends StatelessWidget {
  final DailyOffer offer;

  const OfferBadgeCard({
    super.key,
    required this.offer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Icon(
                Icons.lunch_dining,
                color: Theme.of(context).colorScheme.primary,
                size: AppDimensions.iconXLarge,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(offer.discount * 100).round()}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 18, color: Theme.of(context).iconTheme.color),
            ],
          ),
        ],
      ),
    );
  }
}
