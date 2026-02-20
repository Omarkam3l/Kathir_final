import 'package:flutter/material.dart';
import '../models/agent_response.dart';

/// Build cart summary widget with gradient background
class BuildCartSummaryWidget extends StatelessWidget {
  final BuildCartData buildCartData;

  const BuildCartSummaryWidget({
    super.key,
    required this.buildCartData,
  });

  @override
  Widget build(BuildContext context) {
    final budget = buildCartData.total + buildCartData.remainingBudget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ Cart Built Successfully!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Budget: ${budget.toStringAsFixed(0)} EGP',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          
          // Cart items
          ...buildCartData.items.map((item) => _buildCartItem(item)),
          
          // Total and Remaining
          Container(
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.only(top: 15),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white30,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${buildCartData.total.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining: ${buildCartData.remainingBudget.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.quantity}x @ ${item.unitPrice.toStringAsFixed(0)} EGP = ${item.subtotal.toStringAsFixed(0)} EGP',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
