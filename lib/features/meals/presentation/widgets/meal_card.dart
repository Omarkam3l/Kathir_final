import 'package:flutter/material.dart';
import '../../../user_home/domain/entities/meal.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;
  const MealCard({super.key, required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final expiresIn = meal.expiry.difference(DateTime.now());
    final urgent = expiresIn.inHours < 12;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
              child: Image.network(meal.imageUrl, width: 120, height: 100, fit: BoxFit.cover, semanticLabel: meal.title),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(meal.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(meal.restaurant.name, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 4), Text(meal.restaurant.rating.toStringAsFixed(1))]),
                    Text('\$${meal.donationPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  if (urgent) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Text('Urgent', style: TextStyle(color: Colors.red)))
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }
}
