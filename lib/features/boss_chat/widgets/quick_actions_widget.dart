import 'package:flutter/material.dart';

/// Quick action button widget
class QuickActionsWidget extends StatelessWidget {
  final Function(String) onQuickMessage;

  const QuickActionsWidget({
    super.key,
    required this.onQuickMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 15),
        _buildActionButton(
          '🍗 Chicken Dishes',
          'Show me chicken dishes',
        ),
        _buildActionButton(
          '🦐 Affordable Seafood',
          'I want seafood under 100 EGP',
        ),
        _buildActionButton(
          '🍰 Desserts',
          'Show me desserts',
        ),
        _buildActionButton(
          '🌾 Gluten-Free',
          'I need gluten-free meals',
        ),
        _buildActionButton(
          '💰 Budget Cart (500 EGP)',
          'Build a cart with 500 EGP budget',
        ),
        _buildActionButton(
          '🛒 View Cart',
          'Show my cart',
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => onQuickMessage(message),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFe2e8f0), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1e293b),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
