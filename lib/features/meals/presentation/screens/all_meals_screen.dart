import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../../core/shared/widgets/diamond_clipper.dart';
import 'meal_detail.dart';

enum SortOption { urgency, priceLow, priceHigh, rating, discount }

enum FilterOption { all, urgent, highDiscount, topRated }

class AllMealsScreen extends StatefulWidget {
  final List<MealOffer> allOffers;
  const AllMealsScreen({super.key, required this.allOffers});

  @override
  State<AllMealsScreen> createState() => _AllMealsScreenState();
}

class _AllMealsScreenState extends State<AllMealsScreen> {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.urgency;
  FilterOption _filterOption = FilterOption.all;

  List<MealOffer> get _filteredAndSortedOffers {
    List<MealOffer> filtered = widget.allOffers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((offer) {
        return offer.title.toLowerCase().contains(query) ||
            offer.restaurant.name.toLowerCase().contains(query) ||
            offer.location.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filters
    switch (_filterOption) {
      case FilterOption.urgent:
        filtered = filtered.where((o) => o.minutesLeft <= 30).toList();
        break;
      case FilterOption.highDiscount:
        filtered = filtered.where((o) {
          final discount =
              (o.originalPrice - o.donationPrice) / o.originalPrice;
          return discount >= 0.4;
        }).toList();
        break;
      case FilterOption.topRated:
        filtered = filtered.where((o) => o.restaurant.rating >= 4.5).toList();
        break;
      case FilterOption.all:
        break;
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case SortOption.urgency:
          final urgencyA = a.minutesLeft;
          final urgencyB = b.minutesLeft;
          if (urgencyA != urgencyB) return urgencyA.compareTo(urgencyB);
          return b.restaurant.rating.compareTo(a.restaurant.rating);
        case SortOption.priceLow:
          return a.donationPrice.compareTo(b.donationPrice);
        case SortOption.priceHigh:
          return b.donationPrice.compareTo(a.donationPrice);
        case SortOption.rating:
          return b.restaurant.rating.compareTo(a.restaurant.rating);
        case SortOption.discount:
          final discountA =
              (a.originalPrice - a.donationPrice) / a.originalPrice;
          final discountB =
              (b.originalPrice - b.donationPrice) / b.originalPrice;
          return discountB.compareTo(discountA);
      }
    });

    return filtered;
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 20),
            ...SortOption.values.map((option) {
              final labels = {
                SortOption.urgency: 'Urgency (Time Left)',
                SortOption.priceLow: 'Price: Low to High',
                SortOption.priceHigh: 'Price: High to Low',
                SortOption.rating: 'Highest Rated',
                SortOption.discount: 'Best Discount',
              };
              return RadioListTile<SortOption>(
                title: Text(labels[option]!),
                value: option,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  Navigator.pop(context);
                },
                activeColor: AppColors.primaryAccent,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter By',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 20),
            ...FilterOption.values.map((option) {
              final labels = {
                FilterOption.all: 'All Meals',
                FilterOption.urgent: 'Urgent (≤30 min)',
                FilterOption.highDiscount: 'High Discount (≥40%)',
                FilterOption.topRated: 'Top Rated (≥4.5)',
              };
              return RadioListTile<FilterOption>(
                title: Text(labels[option]!),
                value: option,
                groupValue: _filterOption,
                onChanged: (value) {
                  setState(() => _filterOption = value!);
                  Navigator.pop(context);
                },
                activeColor: AppColors.primaryAccent,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Professional Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Transform.rotate(
                        angle: 45 * pi / 180,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final router = GoRouter.of(context);
                              if (router.canPop()) {
                                router.pop();
                              } else {
                                router.go('/home');
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: -45 * pi / 180,
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 18,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipPath(
                        clipper: DiamondClipper(),
                        child: Image.asset(
                          'lib/resources/assets/images/kathir_edit.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, st) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.1),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 20,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All Meals',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Enhanced Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                            decoration: BoxDecoration(
                              color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(Icons.search,
                                  color: Colors.grey[600], size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Search meals, restaurants...',
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _showFilterDialog,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.deepTeal,
                                  AppColors.tealAqua
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryAccent.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                if (_filterOption != FilterOption.all)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sort & Results Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showSortDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sort',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredAndSortedOffers.length} ${_filteredAndSortedOffers.length == 1 ? 'meal' : 'meals'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Professional Grid View
            Expanded(
              child: _filteredAndSortedOffers.isEmpty
                  ? _buildEmptyState()
                  : _buildProfessionalGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 60,
              color: AppColors.primaryAccent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No meals found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredAndSortedOffers.length,
      itemBuilder: (context, index) {
        return _ProfessionalMealCard(
          offer: _filteredAndSortedOffers[index],
          index: index,
        );
      },
    );
  }
}

class _ProfessionalMealCard extends StatefulWidget {
  final MealOffer offer;
  final int index;

  const _ProfessionalMealCard({
    required this.offer,
    required this.index,
  });

  @override
  State<_ProfessionalMealCard> createState() => _ProfessionalMealCardState();
}

class _ProfessionalMealCardState extends State<_ProfessionalMealCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  // Removed heart UI; keep flag out
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final discount = ((offer.originalPrice - offer.donationPrice) /
            offer.originalPrice *
            100)
        .round();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ProductDetailPage(product: offer),
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
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _hovering
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Section
                  Expanded(
                    flex: 3,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Hero(
                            tag: 'meal_${offer.id}',
                            child: Image.network(
                              offer.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Theme.of(context).cardColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white54,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Theme.of(context).cardColor,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Discount Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.deepTeal,
                                  AppColors.tealAqua
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryAccent.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$discount% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Favorite Button removed
                        // Urgency Badge
                        if (offer.minutesLeft <= 30)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${offer.minutesLeft} min left',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content Section
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      offer.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        offer.restaurant.rating
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${offer.quantity} left',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${offer.originalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    '\$${offer.donationPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryAccent,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
