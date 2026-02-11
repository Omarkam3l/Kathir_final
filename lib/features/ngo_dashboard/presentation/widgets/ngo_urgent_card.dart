import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../user_home/domain/entities/meal.dart';

class NgoUrgentCard extends StatelessWidget {
  final Meal meal;
  final bool isDark;
  final VoidCallback onClaim;
  final VoidCallback onViewDetails;

  const NgoUrgentCard({
    super.key,
    required this.meal,
    required this.isDark,
    required this.onClaim,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final minutesLeft = meal.pickupMinutesLeft;
    final isVeryUrgent = minutesLeft <= 45;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[300],
                  image: meal.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(meal.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: meal.imageUrl.isEmpty
                    ? const Center(child: Icon(Icons.restaurant, size: 32, color: Colors.grey))
                    : null,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVeryUrgent ? Colors.red[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isVeryUrgent ? Colors.red[100]! : Colors.orange[100]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm,
                        size: 12,
                        color: isVeryUrgent ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${minutesLeft}m left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isVeryUrgent ? Colors.red : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.black54, Colors.black26],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        meal.restaurant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meal.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        meal.donationPrice > 0
                            ? 'EGP ${meal.donationPrice.toStringAsFixed(0)}'
                            : 'Free',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Approx ${meal.quantity} ${meal.unit}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        Text(
                          ' 0.8km',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: onViewDetails,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Details',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: onClaim,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Claim',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
