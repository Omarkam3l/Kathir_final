import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../../core/shared/widgets/diamond_clipper.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../domain/entities/meal_offer.dart';
import '../../../meals/presentation/screens/all_meals_screen.dart';
import '../../../meals/presentation/screens/meal_detail.dart';
import '../widgets/home_header.dart';
import '../widgets/highlights_section.dart';
import '../widgets/meal_card_compact.dart';
import '../widgets/profile_drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Main home dashboard screen displaying meal offers and highlights
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';

  @override
  void initState() {
    super.initState();
  }

  /// Filters and sorts offers based on search query
  List<MealOffer> get _visibleOffers {
    final q = _query.trim().toLowerCase();
    final all = context.watch<HomeViewModel>().meals;
    final list = all.where((m) {
      if (q.isEmpty) return true;
      return m.title.toLowerCase().contains(q) ||
          m.restaurant.name.toLowerCase().contains(q) ||
          m.location.toLowerCase().contains(q);
    }).toList();

    // Sort by urgency, then discount, then rating
    list.sort((a, b) {
      final urgencyA = a.minutesLeft;
      final urgencyB = b.minutesLeft;
      if (urgencyA != urgencyB) return urgencyA.compareTo(urgencyB);

      final discountA = (a.originalPrice - a.donationPrice) / a.originalPrice;
      final discountB = (b.originalPrice - b.donationPrice) / b.originalPrice;
      if (discountA != discountB) return discountB.compareTo(discountA);

      return b.restaurant.rating.compareTo(a.restaurant.rating);
    });

    return list;
  }

  void _onCardTap(MealOffer offer) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailPage(product: offer),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
        transitionDuration: const Duration(
          milliseconds: AppDimensions.animationDurationPageTransition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeaderSection(),
            SliverToBoxAdapter(
              child: HomeHeader(onQueryChanged: (q) => setState(() => _query = q)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.paddingMedium)),
            const SliverToBoxAdapter(child: HighlightsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.paddingLarge)),
            _buildMealsSection(),
            _buildMealsList(),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatbotComingSoon)),
        ),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildHeaderSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingXLarge,
          AppDimensions.paddingLarge,
          AppDimensions.paddingXLarge,
          AppDimensions.paddingSmall,
        ),
        child: Row(
          children: [
            ClipPath(
              clipper: DiamondClipper(),
              child: Image.asset(
                'lib/resources/assets/images/kathir_edit.png',
                width: AppDimensions.profileImageLarge,
                height: AppDimensions.profileImageLarge,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => Container(
                  width: AppDimensions.profileImageLarge,
                  height: AppDimensions.profileImageLarge,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                onTap: () => showProfileDrawer(context),
                child: Transform.rotate(
                  angle: 45 * pi / 180,
                  child: Container(
                    width: AppDimensions.profileImageMedium,
                    height: AppDimensions.profileImageMedium,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Transform.rotate(
                      angle: -45 * pi / 180,
                      child: ClipPath(
                        clipper: DiamondClipper(),
                        child: Container(
                          width: AppDimensions.profileImageMedium,
                          height: AppDimensions.profileImageMedium,
                          color: Theme.of(context).cardColor,
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: AppDimensions.iconXLarge,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildMealsSection() {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLarge,
          AppDimensions.paddingSmall,
          AppDimensions.paddingLarge,
          AppDimensions.paddingSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.availableMeals,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllMealsScreen(
                      allOffers: context.read<HomeViewModel>().meals,
                    ),
                  ),
                );
              },
              child: Text(
                l10n.seeAll,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 520,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
          scrollDirection: Axis.horizontal,
          itemCount: _visibleOffers.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.paddingLarge),
          itemBuilder: (ctx, i) {
            final offer = _visibleOffers[i];
            return MealCardCompact(
              offer: offer,
              isSelected: false,
              onTap: () => _onCardTap(offer),
              index: i,
            );
          },
        ),
      ),
    );
  }
}
