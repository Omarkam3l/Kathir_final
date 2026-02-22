import 'package:flutter/material.dart';
import '../models/agent_response.dart';

/// Cart summary widget with gradient background
class CartSummaryWidget extends StatelessWidget {
  final CartData cartData;

  const CartSummaryWidget({
    super.key,
    required this.cartData,
  });

  @override
  Widget build(BuildContext context) {
    if (cartData.count == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your cart is empty! 🛒',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1e293b),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching for meals and I can help you build a cart.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748b),
              ),
            ),
          ],
        ),
      );
    }

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
            '🛒 Your Cart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          
          // Cart items
          ...cartData.items.map((item) => _buildCartItem(item)),
          
          // Total
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
                  'Total: ${cartData.total.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (cartData.totalQuantity != null)
                  Text(
                    '(${cartData.totalQuantity} portions)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
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
          const SizedBox(height: 2),
          Text(
            'Stock: ${item.availableStock} | ${item.restaurantName}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
