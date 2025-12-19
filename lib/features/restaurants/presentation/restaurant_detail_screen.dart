import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/figma_models.dart';
import 'foodie_product_detail_screen.dart';

class RestaurantDetailScreen extends StatelessWidget {
  static const routeName = '/restaurant-detail';
  const RestaurantDetailScreen({super.key, this.story});

  final RestaurantStory? story;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = story ?? DemoData.featuredRestaurants(l10n).first;
    final menu = DemoData.cartItems(l10n);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    _diamondButton(
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
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.darkText),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: Hero(
                        tag: data.name,
                        child: Image.network(
                          data.heroImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.lightBackground,
                            child: const Icon(Icons.restaurant,
                                size: 48, color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data.location} • ${data.rating.toStringAsFixed(1)} ★',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: data.badges
                          .map(
                            (badge) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoStat(
                              label: AppLocalizations.of(context)!.deliveryLabel,
                              value: AppLocalizations.of(context)!.deliveryTimeValue),
                          _InfoStat(
                              label: AppLocalizations.of(context)!.distanceLabel,
                              value: AppLocalizations.of(context)!.distanceValue),
                          _InfoStat(
                              label: AppLocalizations.of(context)!.openLabel,
                              value: AppLocalizations.of(context)!.openTimeValue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.signatureMenuTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.tune, color: AppColors.darkText),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  final item = menu[index % menu.length];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FoodieProductDetailScreen(item: item),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                item.imageUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 90,
                                  height: 90,
                                  color: AppColors.lightBackground,
                                  child: const Icon(Icons.fastfood,
                                      color: AppColors.primaryAccent),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '\$${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: menu.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _diamondButton({required IconData icon, required VoidCallback onTap}) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
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
            child: Icon(icon, color: AppColors.darkText),
          ),
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
