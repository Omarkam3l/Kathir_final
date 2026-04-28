import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

class FeatureCardsSection extends StatefulWidget {
  const FeatureCardsSection({
    super.key,
  });

  @override
  State<FeatureCardsSection> createState() => _FeatureCardsSectionState();
}

class _FeatureCardsSectionState extends State<FeatureCardsSection> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(
        title: 'Rush Hour',
        subtitle: 'Limited Time Deals',
        icon: Icons.bolt_rounded,
        image: 'lib/resources/assets/images/Rush_Hour.jpg',
        route: '/rush-hour-meals',
      ),
      _CardData(
        title: 'Flash Deals',
        subtitle: 'Best Offers',
        icon: Icons.local_fire_department_rounded,
        image: 'lib/resources/assets/images/Flach_Deshes.jpg',
        route: '/meals/all',
      ),
      _CardData(
        title: 'Restaurants',
        subtitle: 'Explore Partners',
        icon: Icons.storefront_rounded,
        image: 'lib/resources/assets/images/Restaurants.jpg',
        route: '/restaurants/all',
      ),
      _CardData(
        title: 'Top NGOs',
        subtitle: 'Support Organizations',
        icon: Icons.volunteer_activism_rounded,
        image: 'lib/resources/assets/images/NGOs.jpg',
        route: '/ngos/all',
      ),
    ];

    return Column(
      children: [
        // ── Slider ───────────────────────────────────────────────
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final card = cards[i];
              return AnimatedScale(
                scale: _currentPage == i ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _FeatureCard(
                    data: card,
                    onTap: () => GoRouter.of(context).push(card.route),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Dots ─────────────────────────────────────────────────
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String image;
  final String route;

  const _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    required this.route,
  });
}

class _FeatureCard extends StatelessWidget {
  final _CardData data;
  final VoidCallback? onTap;
  const _FeatureCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ─────────────────────────────────
            Image.asset(
              data.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),

            // ── Dark gradient overlay ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),

            // ── Glass blur layer ──────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                    ),
                    child: Row(
                      children: [
                        // Icon box
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Icon(data.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                data.subtitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
