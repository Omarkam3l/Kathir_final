import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductDetailPage extends StatefulWidget {
  final MealOffer product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.product;
    final price = a.donationPrice * qty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top actions and large product image
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _diamondIconButton(
                    icon: Icons.arrow_back,
                    onTap: () {
                      final router = GoRouter.of(context);
                      if (router.canPop()) {
                        router.pop();
                      } else {
                        router.go('/home');
                      }
                    },
                  ),
                  const Spacer(),
                  Consumer<FoodieState>(
                    builder: (context, foodie, _) {
                      final fav = foodie.isFavourite(a.id);
                      return _diamondIconButton(
                        icon: fav ? Icons.favorite : Icons.favorite_border,
                        onTap: () {
                          foodie.toggleFavourite(a);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  fav ? l10n.removedFromFavourites : l10n.addedToFavourites),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        iconColor: fav ? Colors.redAccent : Theme.of(context).iconTheme.color,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // product image
                    AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Hero(
                          tag: 'meal_${a.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(180),
                            child: Image.network(
                              a.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Theme.of(context).cardColor,
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 48, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // qty stepper like screenshot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _diamondSmallButton(
                          icon: Icons.remove,
                          onTap:
                              qty > 1 ? () => setState(() => qty -= 1) : null,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '$qty',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(width: 14),
                        _diamondSmallButton(
                          icon: Icons.add,
                          onTap: () => setState(() => qty += 1),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // info card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.fastFood,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.title,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.star,
                                      size: 18, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.restaurant.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.mealDescription,
                                style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.deliveryTime,
                                            style: TextStyle(
                                                color: Theme.of(context).textTheme.bodySmall?.color)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time,
                                                size: 18,
                                                color: Theme.of(context).colorScheme.primary),
                                            const SizedBox(width: 6),
                                            Text(l10n.minutesShort(max(5, a.minutesLeft))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Price column
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(l10n.totalPrice,
                                          style: TextStyle(
                                              color: Theme.of(context).textTheme.bodySmall?.color)),
                                      const SizedBox(height: 6),
                                      Text(
                                        '\$${price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _floatingCartButton(onTap: () {
        final foodie = context.read<FoodieState>();
        foodie.addToCart(a, qty: qty);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedToCartWithQty(qty, a.title))),
        );
        context.push('/cart');
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: const SizedBox(height: 16),
    );
  }

  Widget _diamondIconButton(
      {required IconData icon, required VoidCallback onTap, Color? iconColor}) {
    return Transform.rotate(
      angle: 45 * pi / 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Transform.rotate(
            angle: -45 * pi / 180,
            child: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
          ),
        ),
      ),
    );
  }

  Widget _diamondSmallButton(
      {required IconData icon,
      required VoidCallback? onTap,
      required Color color}) {
    return Transform.rotate(
      angle: 45 * pi / 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: onTap == null ? color.withOpacity(0.4) : color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Transform.rotate(
            angle: -45 * pi / 180,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _floatingCartButton({required VoidCallback onTap}) {
    return Transform.rotate(
      angle: 45 * pi / 180,
      child: FloatingActionButton(
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Transform.rotate(
          angle: -45 * pi / 180,
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
      ),
    );
  }
}
