import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/figma_models.dart';

class FoodieProductDetailScreen extends StatelessWidget {
  final MenuItem item;
  const FoodieProductDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              item.imageUrl,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: AppColors.lightBackground,
                child:
                    const Icon(Icons.fastfood, color: AppColors.primaryAccent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(item.subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.primaryAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Text(l10n.addToCart,
                    style: const TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
