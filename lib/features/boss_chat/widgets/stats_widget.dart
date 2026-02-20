import 'package:flutter/material.dart';

/// Stats widget showing message count, cart items, and cart total
class StatsWidget extends StatelessWidget {
  final int messageCount;
  final int cartCount;
  final double cartTotal;

  const StatsWidget({
    super.key,
    required this.messageCount,
    required this.cartCount,
    required this.cartTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Stats',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 15),
        _buildStatItem('Messages:', messageCount.toString()),
        _buildStatItem('Cart Items:', cartCount > 0 ? cartCount.toString() : '-'),
        _buildStatItem(
          'Cart Total:',
          cartTotal > 0 ? '${cartTotal.toStringAsFixed(0)} EGP' : '-',
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFe2e8f0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748b),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563eb),
            ),
          ),
        ],
      ),
    );
  }
}
