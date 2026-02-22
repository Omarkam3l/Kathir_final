import 'package:flutter/material.dart';

/// Tips widget showing usage tips
class TipsWidget extends StatelessWidget {
  const TipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ℹ️ Tips',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 15),
        _buildTipItem('Ask for specific dishes or cuisines'),
        _buildTipItem('Set price ranges for budget-friendly options'),
        _buildTipItem('Mention dietary restrictions (gluten-free, dairy-free)'),
        _buildTipItem('Request cart building with your budget'),
        _buildTipItem('Ask to view or modify your cart'),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748b),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
