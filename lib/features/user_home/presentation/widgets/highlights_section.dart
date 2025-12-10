import 'package:flutter/material.dart';
import '../../../../core/utils/app_dimensions.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import 'offer_badge_card.dart';
import 'top_restaurant_card.dart';

/// Section widget displaying highlights: offers, donate/buy, and top restaurants
class HighlightsSection extends StatelessWidget {
  const HighlightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingLarge,
            4,
            AppDimensions.paddingLarge,
            AppDimensions.paddingSmall,
          ),
          child: Text(
            'Offer of the Day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final vm = context.watch<HomeViewModel>();
              final list = vm.offers;
              final offer = list.isEmpty ? null : list[index % list.length];
              if (offer == null) {
                return const SizedBox.shrink();
              }
              return OfferBadgeCard(offer: offer);
            },
            separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.paddingMedium),
            itemCount: 8,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingLarge),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingLarge,
            0,
            AppDimensions.paddingLarge,
            AppDimensions.paddingSmall,
          ),
          child: Text(
            'Top Rated Restaurants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final vm = context.watch<HomeViewModel>();
              final list = vm.restaurants;
              final restaurant = list.isEmpty ? null : list[index % list.length];
              if (restaurant == null) {
                return const SizedBox.shrink();
              }
              return TopRestaurantCard(restaurant: restaurant);
            },
            separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.paddingMedium),
            itemCount: 10,
          ),
        ),
      ],
    );
  }
}
