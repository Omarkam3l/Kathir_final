import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../../core/utils/app_styles.dart';
import 'package:provider/provider.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../domain/entities/meal_offer.dart';

/// Compact meal card widget with animations and interactions
class MealCardCompact extends StatefulWidget {
  final MealOffer offer;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const MealCardCompact({
    super.key,
    required this.offer,
    required this.isSelected,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<MealCardCompact> createState() => _MealCardCompactState();
}

class _MealCardCompactState extends State<MealCardCompact>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
    );

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
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

  String _formatExpiry(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final isSelected = widget.isSelected;

    final width = isSelected ? AppDimensions.cardWidthExpanded : AppDimensions.cardWidthCompact;
    final height = isSelected ? AppDimensions.cardHeightExpanded : AppDimensions.cardHeightCompact;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onDoubleTap: widget.onTap,
            child: AnimatedScale(
              scale: _hovering ? 1.05 : 1.0,
              duration: const Duration(milliseconds: AppDimensions.animationDurationMedium),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: AppDimensions.animationDurationMedium),
                curve: Curves.easeInOut,
                width: width,
                height: height,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXXLarge),
                  boxShadow: _hovering ? AppStyles.hoverCardShadow : AppStyles.defaultCardShadow,
                ),
                child: Column(
                  children: [
                    _buildImageSection(offer, isSelected),
                    _buildContentSection(offer, isSelected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(MealOffer offer, bool isSelected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
          tag: 'meal_${offer.id}',
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXXLarge),
            ),
            child: SizedBox(
              height: isSelected
                  ? AppDimensions.cardImageHeightExpanded
                  : AppDimensions.cardImageHeightCompact,
              width: double.infinity,
              child: Image.network(
                offer.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 36,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildFavoriteButton(offer),
        _buildRestaurantBadge(offer),
      ],
    );
  }

  Widget _buildFavoriteButton(MealOffer offer) {
    return Positioned(
      top: 10,
      left: 10,
      child: Material(
            color: Theme.of(context).cardColor,
            shape: const CircleBorder(),
            child: Consumer<FoodieState>(
              builder: (context, foodie, _) {
                final fav = foodie.isFavourite(offer.id);
                return InkWell(
                  onTap: () {
                    foodie.toggleFavourite(offer);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          fav ? 'Removed from favourites' : 'Added to favourites',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                    ),
                    child: Center(
                      child: Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? Colors.red : Theme.of(context).iconTheme.color,
                        size: AppDimensions.iconMedium,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildRestaurantBadge(MealOffer offer) {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
          color: AppColors.primaryAccent.withOpacity(0.12),
        ),
        child: Center(
          child: Text(
            offer.restaurant.name.isNotEmpty ? offer.restaurant.name[0] : 'R',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(MealOffer offer, bool isSelected) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offer.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${offer.restaurant.name} • ${offer.location}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${offer.restaurant.rating.toStringAsFixed(1)}/5',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${offer.quantity} Left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                _buildTimerBadge(offer),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Estimated \$${offer.originalPrice.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Expires: ${_formatExpiry(offer.expiry)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '\$${offer.originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Donation \$${offer.donationPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            _buildAddToCartButton(offer, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge(MealOffer offer) {
    final isUrgent = offer.minutesLeft <= 30;
    final color = isUrgent ? AppColors.secondaryAccent : AppColors.primaryAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '${offer.minutesLeft} min',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(MealOffer offer, bool isSelected) {
    return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final foodie = context.read<FoodieState>();
              foodie.addToCart(offer);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${offer.title} added to cart'),
                  duration: const Duration(seconds: 1),
                ),
              );
              widget.onTap();
            },
            style: AppStyles.primaryButtonStyle.copyWith(
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              vertical: isSelected ? 14 : 10,
            ),
          ),
        ),
            child: const Text(
              'Add to Cart',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        );
  }
}
