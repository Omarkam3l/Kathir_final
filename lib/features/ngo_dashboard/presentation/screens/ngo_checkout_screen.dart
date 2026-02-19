import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';

class NgoCheckoutScreen extends StatefulWidget {
  final NgoCartViewModel cart;

  const NgoCheckoutScreen({super.key, required this.cart});

  @override
  State<NgoCheckoutScreen> createState() => _NgoCheckoutScreenState();
}

class _NgoCheckoutScreenState extends State<NgoCheckoutScreen> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;
  String _pickupLocation = 'NGO Office';
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(isDark),
            const SizedBox(height: 24),
            _buildPickupDetails(isDark),
            const SizedBox(height: 24),
            _buildConfirmButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.cart.cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.meal.title} x${item.quantity}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                    const Text(
                      'Free',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${widget.cart.cartCount} meals',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CO₂ Savings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.eco, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.cart.co2Savings.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetails(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Pickup Location',
              hintText: 'Enter pickup location',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _pickupLocation = value,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Any special instructions',
              prefixIcon: const Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _confirmOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Confirm Pickup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    if (_pickupLocation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a pickup location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      debugPrint('🔄 Creating orders for ${widget.cart.cartItems.length} items...');

      // Create orders for each cart item
      for (final item in widget.cart.cartItems) {
        final orderData = {
          'user_id': userId,
          'ngo_id': userId,
          'restaurant_id': item.meal.restaurant.id,
          'status': 'pending',
          'delivery_type': 'donation',
          'subtotal': 0.0,
          'total_amount': 0.0,
          'delivery_address': _pickupLocation.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        final orderResult = await _supabase
            .from('orders')
            .insert(orderData)
            .select('id')
            .single();

        final orderId = orderResult['id'];
        debugPrint('✅ Created order: $orderId');

        // Create order item
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'meal_id': item.meal.id,
          'quantity': item.quantity,
          'unit_price': 0.0,
          'meal_title': item.meal.title,
        });

        // Update meal quantity
        final newQuantity = item.meal.quantity - item.quantity;
        await _supabase.from('meals').update({
          'quantity_available': newQuantity,
          'status': newQuantity <= 0 ? 'sold' : 'active',
        }).eq('id', item.meal.id);

        debugPrint('✅ Updated meal quantity: ${item.meal.id}');
      }

      // Clear cart
      await widget.cart.clearCart();
      debugPrint('✅ Cart cleared');

      if (mounted) {
        context.go('/ngo/order-summary', extra: 'success');
      }
    } catch (e) {
      debugPrint('❌ Error confirming order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
