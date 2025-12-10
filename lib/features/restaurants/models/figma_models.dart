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
  const MenuItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
  });
}

class DemoData {
  static List<RestaurantStory> featuredRestaurants() => const [
        RestaurantStory(
          name: 'Green Garden',
          location: 'Downtown',
          rating: 4.7,
          heroImage:
              'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=1200&q=80',
          badges: ['Vegan', 'Organic', 'Fast delivery'],
        ),
      ];

  static List<MenuItem> cartItems() => const [
        MenuItem(
          title: 'Veggie Bowl',
          subtitle: 'Quinoa, avocado, greens',
          imageUrl:
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
          price: 12,
        ),
        MenuItem(
          title: 'Pasta Box',
          subtitle: 'Tomato, basil, parmesan',
          imageUrl:
              'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=800&q=80',
          price: 10,
        ),
      ];
}
