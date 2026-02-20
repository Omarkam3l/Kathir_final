import 'package:flutter/material.dart';
import '../models/agent_response.dart';

/// Meal card widget - displays meal information
class MealCardWidget extends StatelessWidget {
  final MealResult meal;

  const MealCardWidget({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe2e8f0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  meal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${meal.price.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              meal.category,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748b),
              ),
            ),
          ),
          
          // Description
          if (meal.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meal.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748b),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Allergens
          if (meal.allergens.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: meal.allergens.map((allergen) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf59e0b),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⚠️ $allergen',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Score
          if (meal.score != null) ...[
            const SizedBox(height: 8),
            Text(
              'Relevance: ${(meal.score! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748b),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
