import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';

enum PickupMethod { selfPickup, delivery }

class NgoCheckoutScreen extends StatefulWidget {
  final NgoCartViewModel cart;

  const NgoCheckoutScreen({super.key, required this.cart});

  @override
  State<NgoCheckoutScreen> createState() => _NgoCheckoutScreenState();
}

class _NgoCheckoutScreenState extends State<NgoCheckoutScreen> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;
  PickupMethod _pickupMethod = PickupMethod.selfPickup;
  String? _selectedPickupLocation;
  LatLng? _selectedLocationCoords;
  
  // Billing
  double _deliveryFee = 0.0;
  double _serviceFee = 0.0;
  double _taxAmount = 0.0;
  final double _taxRate = 0.14; // 14% tax rate

  @override
  void initState() {
    super.initState();
    _calculateFees();
  }

  void _calculateFees() {
    // Calculate service fee (5% of subtotal for paid items)
    _serviceFee = widget.cart.total * 0.05;
    
    // Calculate delivery fee based on method
    if (_pickupMethod == PickupMethod.delivery) {
      _deliveryFee = 20.0; // Fixed delivery fee
    } else {
      _deliveryFee = 0.0;
    }
    
    // Calculate tax (14% of subtotal + service fee + delivery fee)
    final taxableAmount = widget.cart.total + _serviceFee + _deliveryFee;
    _taxAmount = taxableAmount * _taxRate;
  }

  double get _totalAmount {
    return widget.cart.total + _serviceFee + _deliveryFee + _taxAmount;
  }

  @override
  void dispose() {
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
            _buildPickupMethodSelector(isDark),
            const SizedBox(height: 24),
            _buildOrderSummary(isDark),
            const SizedBox(height: 24),
            _buildPickupDetails(isDark),
            const SizedBox(height: 24),
            _buildBillingSummary(isDark),
            const SizedBox(height: 24),
            _buildConfirmButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupMethodSelector(bool isDark) {
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
            'Pickup Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMethodOption(
                  isDark,
                  PickupMethod.selfPickup,
                  Icons.store,
                  'Self Pickup',
                  'Pick up from restaurant',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMethodOption(
                  isDark,
                  PickupMethod.delivery,
                  Icons.local_shipping,
                  'Delivery',
                  'Deliver to location',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(
    bool isDark,
    PickupMethod method,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _pickupMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _pickupMethod = method;
          _calculateFees();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF0F1F16) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primaryGreen
                    : (isDark ? Colors.white : Colors.black),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
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
                    Text(
                      item.meal.donationPrice == 0
                          ? 'FREE'
                          : 'EGP ${(item.meal.donationPrice * item.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: item.meal.donationPrice == 0 
                            ? AppColors.primaryGreen 
                            : (isDark ? Colors.white : Colors.black),
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
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                widget.cart.total == 0
                    ? 'FREE'
                    : 'EGP ${widget.cart.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.cart.total == 0 
                      ? AppColors.primaryGreen 
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
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
            _pickupMethod == PickupMethod.selfPickup
                ? 'Pickup Location'
                : 'Delivery Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_pickupMethod == PickupMethod.selfPickup)
            _buildSelfPickupInfo(isDark)
          else
            _buildDeliveryLocationSelector(isDark),
        ],
      ),
    );
  }

  Widget _buildSelfPickupInfo(bool isDark) {
    // Get first restaurant from cart items
    final firstMeal = widget.cart.cartItems.first.meal;
    final restaurant = firstMeal.restaurant;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.store,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.addressText ?? 'Restaurant location',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationSelector(bool isDark) {
    return Column(
      children: [
        if (_selectedPickupLocation != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedPickupLocation!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _selectLocationOnMap(),
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _selectLocationOnMap,
            icon: const Icon(Icons.map),
            label: const Text('Select Pickup Location on Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectLocationOnMap() async {
    final result = await context.push<Map<String, dynamic>>(
      '/ngo/select-location',
    );
    
    if (result != null && mounted) {
      setState(() {
        _selectedPickupLocation = result['address'] as String;
        _selectedLocationCoords = result['coords'] as LatLng;
      });
    }
  }

  Widget _buildBillingSummary(bool isDark) {
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
            'Billing Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildBillingRow('Subtotal', widget.cart.total, isDark),
          const SizedBox(height: 8),
          _buildBillingRow('Service Fee (5%)', _serviceFee, isDark),
          const SizedBox(height: 8),
          _buildBillingRow('Delivery Fee', _deliveryFee, isDark),
          const SizedBox(height: 8),
          _buildBillingRow('Tax (14%)', _taxAmount, isDark),
          Divider(
            height: 24,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                _totalAmount == 0
                    ? 'FREE'
                    : 'EGP ${_totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _totalAmount == 0
                      ? AppColors.primaryGreen
                      : AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(String label, double amount, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          amount == 0 ? 'FREE' : 'EGP ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: amount == 0
                ? AppColors.primaryGreen
                : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
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
    // Validate location based on pickup method
    String pickupAddress;
    double? pickupLatitude;
    double? pickupLongitude;
    
    if (_pickupMethod == PickupMethod.selfPickup) {
      // Use restaurant location
      final firstMeal = widget.cart.cartItems.first.meal;
      pickupAddress = firstMeal.restaurant.addressText ?? 'Restaurant location';
      pickupLatitude = firstMeal.restaurant.latitude;
      pickupLongitude = firstMeal.restaurant.longitude;
    } else {
      // Delivery - must have selected location
      if (_selectedPickupLocation == null || _selectedLocationCoords == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a delivery location on the map'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      pickupAddress = _selectedPickupLocation!;
      pickupLatitude = _selectedLocationCoords!.latitude;
      pickupLongitude = _selectedLocationCoords!.longitude;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      debugPrint('🔄 Creating orders for ${widget.cart.cartItems.length} items...');

      // Group cart items by restaurant
      final Map<String, List<CartItem>> itemsByRestaurant = {};
      for (final item in widget.cart.cartItems) {
        final restaurantId = item.meal.restaurant.id;
        itemsByRestaurant.putIfAbsent(restaurantId, () => []).add(item);
      }

      debugPrint('📦 Creating ${itemsByRestaurant.length} order(s) for different restaurants');

      // Create one order per restaurant
      for (final entry in itemsByRestaurant.entries) {
        final restaurantId = entry.key;
        final items = entry.value;

        // Calculate totals for this restaurant
        double subtotal = 0.0;
        for (final item in items) {
          subtotal += item.meal.donationPrice * item.quantity;
        }

        // Calculate fees for this order
        final serviceFee = subtotal * 0.05;
        final deliveryFee = _pickupMethod == PickupMethod.delivery ? 20.0 : 0.0;
        final taxableAmount = subtotal + serviceFee + deliveryFee;
        final taxAmount = taxableAmount * _taxRate;
        final totalAmount = taxableAmount + taxAmount;

        final orderData = {
          'user_id': userId,
          'ngo_id': userId,
          'restaurant_id': restaurantId,
          'status': 'pending',
          'delivery_type': _pickupMethod == PickupMethod.selfPickup ? 'pickup' : 'donation',
          'subtotal': subtotal,
          'service_fee': serviceFee,
          'delivery_fee': deliveryFee,
          'platform_commission': taxAmount,
          'total_amount': totalAmount,
          'delivery_address': pickupAddress,
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'pickup_address_text': pickupAddress,
          'created_at': DateTime.now().toIso8601String(),
        };

        final orderResult = await _supabase
            .from('orders')
            .insert(orderData)
            .select('id, order_number')
            .single();

        final orderId = orderResult['id'];
        final orderNumber = orderResult['order_number'];
        debugPrint('✅ Created order: $orderNumber (ID: $orderId) - Total: EGP ${totalAmount.toStringAsFixed(2)}');

        // Create order items for this restaurant
        for (final item in items) {
          await _supabase.from('order_items').insert({
            'order_id': orderId,
            'meal_id': item.meal.id,
            'quantity': item.quantity,
            'unit_price': item.meal.donationPrice,
            'meal_title': item.meal.title,
          });

          // Update meal quantity
          final newQuantity = item.meal.quantity - item.quantity;
          await _supabase.from('meals').update({
            'quantity_available': newQuantity,
            'status': newQuantity <= 0 ? 'sold' : 'active',
          }).eq('id', item.meal.id);

          debugPrint('✅ Added item: ${item.meal.title} x${item.quantity} @ EGP ${item.meal.donationPrice}');
        }
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
