import 'package:flutter/material.dart';
import '../../../../core/utils/app_dimensions.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import 'offer_badge_card.dart';
import '../../domain/entities/daily_offer.dart';
import 'top_restaurant_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Section widget displaying highlights: offers, donate/buy, and top restaurants
class HighlightsSection extends StatelessWidget {
  const HighlightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.offerOfTheDay,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: Builder(
            builder: (context) {
              final vm = context.watch<HomeViewModel>();
              final offers = vm.offers;
              if (offers.isEmpty) return const SizedBox.shrink();

              // Chunk offers into pages of 4
              final pages = <List<DailyOffer>>[];
              for (var i = 0; i < offers.length; i += 4) {
                pages.add(offers.sublist(i, i + 4 > offers.length ? offers.length : i + 4));
              }

              final controller = PageController(viewportFraction: 0.95);
              return PageView.builder(
                controller: controller,
                itemCount: pages.length,
                itemBuilder: (context, pageIndex) {
                  final pageOffers = pages[pageIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        for (var i = 0; i < pageOffers.length; i++) ...[
                          OfferBadgeCard(offer: pageOffers[i]),
                          if (i != pageOffers.length - 1)
                            const SizedBox(width: AppDimensions.paddingMedium),
                        ]
                      ],
                    ),
                  );
                },
              );
            },
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
            l10n.topRatedRestaurants,
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
