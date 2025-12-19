import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RestaurantStory {
  final String name;
  final String location;
  final double rating;
  final String heroImage;
  final List<String> badges;
  const RestaurantStory({
    required this.name,
    required this.location,
    required this.rating,
    required this.heroImage,
    this.badges = const [],
  });
}

class MenuItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final double price;
  final double rating;
  const MenuItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    this.rating = 4.5,
  });
}

class DemoData {
  static List<RestaurantStory> featuredRestaurants(AppLocalizations l10n) => [
        RestaurantStory(
          name: l10n.demoRestaurantName,
          location: l10n.demoRestaurantLocation,
          rating: 4.7,
          heroImage:
              'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=1200&q=80',
          badges: [l10n.demoBadgeVegan, l10n.demoBadgeOrganic, l10n.demoBadgeFastDelivery],
        ),
      ];

  static List<MenuItem> cartItems(AppLocalizations l10n) => [
        MenuItem(
          title: l10n.demoMenuTitle1,
          subtitle: l10n.demoMenuSubtitle1,
          imageUrl:
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
          price: 12,
          rating: 4.8,
        ),
        MenuItem(
          title: l10n.demoMenuTitle2,
          subtitle: l10n.demoMenuSubtitle2,
          imageUrl:
              'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=800&q=80',
          price: 10,
          rating: 4.5,
        ),
      ];
}
