import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../meals/presentation/screens/meal_detail.dart';

class FavouritesScreen extends StatelessWidget {
  static const routeName = '/favourites';
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<FoodieState>(
          builder: (context, foodie, _) {
            final favs = foodie.favourites;
            return Column(
              children: [
                const _FavouriteHeader(),
                Expanded(
                  child: favs.isEmpty
                      ? const _FavouritesEmptyState()
                      
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                          itemCount: favs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final m = favs[i];
                            return _FavouriteItemTile(meal: m);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FavouriteHeader extends StatelessWidget {
  const _FavouriteHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Row(
        children: [
          _diamondButton(
            context,
            icon: Icons.arrow_back_ios_new,
            onTap: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/home');
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.myFavourites,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            child: Icon(Icons.filter_list, color: Theme.of(context).iconTheme.color),
          ),
        ],
      ),
    );
  }

  Widget _diamondButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
          ),
        ),
      ),
    );
  }
}

class _FavouritesEmptyState extends StatelessWidget {
  const _FavouritesEmptyState();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 52, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(
              l10n.noFavouritesYet,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.favouritesEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteItemTile extends StatelessWidget {
  final MealOffer meal;
  const _FavouriteItemTile({required this.meal});
  @override
  Widget build(BuildContext context) {
    final foodie = context.read<FoodieState>();
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProductDetailPage(product: meal),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  meal.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: Theme.of(context).inputDecorationTheme.fillColor ??
                        Theme.of(context).cardColor,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meal.title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => foodie.removeFavourite(meal.id),
                          child: const Icon(Icons.favorite,
                              color: Colors.redAccent),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.restaurantLocation(meal.restaurant.name, meal.location),
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('\$${meal.donationPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(meal.restaurant.rating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 160,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          foodie.addToCart(meal);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.addedToCartNamed(meal.title)),
                                duration: const Duration(seconds: 1)),
                          );
                          context.push('/cart');
                        },
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: Text(l10n.addToCart),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
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
