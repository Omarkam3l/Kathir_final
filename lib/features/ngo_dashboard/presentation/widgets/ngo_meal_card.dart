import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../user_home/domain/entities/meal.dart';

class NgoMealCard extends StatelessWidget {
  final Meal meal;
  final bool isDark;
  final VoidCallback onClaim;
  final VoidCallback? onViewDetails;

  const NgoMealCard({
    super.key,
    required this.meal,
    required this.isDark,
    required this.onClaim,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isReserved = meal.status == 'reserved';

    return GestureDetector(
      onTap: () => context.push('/ngo/meal/${meal.id}', extra: meal),
      child: Container(
        margin: ResponsiveUtils.margin(context, bottom: 10),
        padding: ResponsiveUtils.padding(context, all: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: ResponsiveUtils.borderRadius(context, 14),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Opacity(
          opacity: isReserved ? 0.6 : 1.0,
          child: Row(
            children: [
              _buildImage(context, isReserved),
              SizedBox(width: ResponsiveUtils.spacing(context, 10)),
              Expanded(
                child: _buildContent(context, isReserved),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isReserved) {
    final imageSize = ResponsiveUtils.iconSize(context, 75);
    return Stack(
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            borderRadius: ResponsiveUtils.borderRadius(context, 10),
            color: Colors.grey[300],
            image: meal.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(meal.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: meal.imageUrl.isEmpty
              ? Center(
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.grey,
                    size: ResponsiveUtils.iconSize(context, 30),
                  ),
                )
              : null,
        ),
        if (_isVegetarian)
          Positioned(
            top: ResponsiveUtils.spacing(context, 3),
            right: ResponsiveUtils.spacing(context, 3),
            child: Container(
              padding: ResponsiveUtils.padding(context, horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: ResponsiveUtils.borderRadius(context, 3),
              ),
              child: Text(
                'Veg',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveUtils.fontSize(context, 7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (isReserved)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: ResponsiveUtils.borderRadius(context, 10),
              ),
              child: Center(
                child: Container(
                  padding: ResponsiveUtils.padding(context, horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: ResponsiveUtils.borderRadius(context, 3),
                  ),
                  child: Text(
                    'Reserved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.fontSize(context, 8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isReserved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          meal.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 2)),
        Text(
          meal.restaurant.name,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 11),
            color: Colors.grey[500],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 5)),
        Row(
          children: [
            _buildTag(context, '${meal.quantity}${meal.unit.substring(0, 2)}', Icons.scale),
            SizedBox(width: ResponsiveUtils.spacing(context, 6)),
            _buildTag(context, '~${(meal.quantity * 3).clamp(10, 100)}', Icons.group),
            SizedBox(width: ResponsiveUtils.spacing(context, 6)),
            // Price badge
            Container(
              padding: ResponsiveUtils.padding(context, horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: meal.donationPrice == 0 
                    ? (isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade100)
                    : (isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade100),
                borderRadius: ResponsiveUtils.borderRadius(context, 3),
              ),
              child: Text(
                meal.donationPrice == 0 
                    ? 'FREE' 
                    : 'EGP ${meal.donationPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 9),
                  fontWeight: FontWeight.bold,
                  color: meal.donationPrice == 0 
                      ? (isDark ? Colors.green[300] : Colors.green[700])
                      : (isDark ? Colors.orange[300] : Colors.orange[700]),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: ResponsiveUtils.iconSize(context, 11),
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 3)),
                  Expanded(
                    child: Text(
                      'Pickup by ${_formatTime(meal.pickupDeadline ?? meal.expiry)}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 10),
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 6)),
            if (!isReserved)
              ElevatedButton.icon(
                onPressed: onClaim,
                icon: Icon(
                  Icons.shopping_cart,
                  size: ResponsiveUtils.iconSize(context, 14),
                ),
                label: Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: ResponsiveUtils.padding(context, horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: ResponsiveUtils.borderRadius(context, 6),
                  ),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String text, IconData icon) {
    return Container(
      padding: ResponsiveUtils.padding(context, horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3A2B) : const Color(0xFFE7F3EB),
        borderRadius: ResponsiveUtils.borderRadius(context, 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.iconSize(context, 11),
            color: isDark ? Colors.grey[300] : Colors.grey[600],
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 3)),
          Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 9),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  bool get _isVegetarian {
    return meal.category.toLowerCase().contains('veg') ||
        meal.title.toLowerCase().contains('veg');
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour $period';
  }
}
