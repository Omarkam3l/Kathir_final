import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Opacity(
          opacity: isReserved ? 0.6 : 1.0,
          child: Row(
            children: [
              _buildImage(isReserved),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContent(context, isReserved),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(bool isReserved) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
            image: meal.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(meal.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: meal.imageUrl.isEmpty
              ? const Center(child: Icon(Icons.restaurant, color: Colors.grey))
              : null,
        ),
        if (_isVegetarian)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Veg',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Reserved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
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
      children: [
        Text(
          meal.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          meal.restaurant.name,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildTag('${meal.quantity}${meal.unit.substring(0, 2)}', Icons.scale),
            const SizedBox(width: 8),
            _buildTag('~${(meal.quantity * 3).clamp(10, 100)}', Icons.group),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Pickup by ${_formatTime(meal.pickupDeadline ?? meal.expiry)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            if (!isReserved)
              GestureDetector(
                onTap: () {
                  onClaim();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDark ? Colors.black : Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3A2B) : const Color(0xFFE7F3EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.grey[300] : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
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
