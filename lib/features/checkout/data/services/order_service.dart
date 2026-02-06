import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../profile/presentation/providers/foodie_state.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create order with multiple items (supports multiple restaurants)
  Future<List<Map<String, dynamic>>> createOrder({
    required String userId,
    required List<CartItem> items,
    required String deliveryType,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required double total,
    String? deliveryAddress,
    String? paymentMethod,
  }) async {
    try {
      if (items.isEmpty) {
        throw Exception('Cannot create order with empty cart');
      }

      // Group items by restaurant
      final Map<String, List<CartItem>> itemsByRestaurant = {};
      for (final item in items) {
        final restaurantId = item.meal.restaurant.id;
        if (!itemsByRestaurant.containsKey(restaurantId)) {
          itemsByRestaurant[restaurantId] = [];
        }
        itemsByRestaurant[restaurantId]!.add(item);
      }

      final List<Map<String, dynamic>> createdOrders = [];

      // Create separate order for each restaurant
      for (final entry in itemsByRestaurant.entries) {
        final restaurantId = entry.key;
        final restaurantItems = entry.value;

        // Calculate subtotal for this restaurant
        final restaurantSubtotal = restaurantItems.fold<double>(
          0,
          (sum, item) => sum + (item.meal.donationPrice * item.qty),
        );

        // Calculate fees proportionally based on subtotal
        final proportion = restaurantSubtotal / subtotal;
        final restaurantServiceFee = serviceFee * proportion;
        final restaurantDeliveryFee = deliveryFee * proportion;
        final restaurantTotal = restaurantSubtotal + restaurantServiceFee + restaurantDeliveryFee;

        // Generate order number
        final orderNumberResponse = await _supabase.rpc('generate_order_number');
        final orderNumber = orderNumberResponse as String;

        // 1. Create order for this restaurant
        final orderResponse = await _supabase.from('orders').insert({
          'user_id': userId,
          'restaurant_id': restaurantId,
          'order_number': orderNumber,
          'status': 'pending',
          'delivery_type': deliveryType,
          'subtotal': restaurantSubtotal,
          'service_fee': restaurantServiceFee,
          'delivery_fee': restaurantDeliveryFee,
          'platform_fee': restaurantServiceFee, // Platform commission
          'total_amount': restaurantTotal,
          'delivery_address': deliveryAddress,
          'payment_method': paymentMethod ?? 'card',
          'payment_status': 'pending',
        }).select().single();

        final orderId = orderResponse['id'] as String;

        // 2. Create order items for this restaurant
        final orderItems = restaurantItems.map((item) => {
          'order_id': orderId,
          'meal_id': item.meal.id,
          'meal_title': item.meal.title,
          'quantity': item.qty,
          'unit_price': item.meal.donationPrice,
        }).toList();

        await _supabase.from('order_items').insert(orderItems);

        // 3. Update meal quantities
        for (final item in restaurantItems) {
          await _supabase.rpc('decrement_meal_quantity', params: {
            'meal_id': item.meal.id,
            'qty': item.qty,
          });
        }

        createdOrders.add({
          'order_id': orderId,
          'order_number': orderNumber,
          'restaurant_id': restaurantId,
          'total': restaurantTotal,
        });
      }

      // 4. Clear cart after all orders are created
      await _supabase.from('cart_items').delete().eq('user_id', userId);

      return createdOrders;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  /// Get order details
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final orderResponse = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              id,
              meal_id,
              meal_title,
              quantity,
              unit_price,
              meals (
                id,
                title,
                image_url,
                category
              )
            ),
            restaurants (
              restaurant_name,
              address_text,
              phone
            )
          ''')
          .eq('id', orderId)
          .single();

      return orderResponse;
    } catch (e) {
      print('Error getting order: $e');
      rethrow;
    }
  }

  /// Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              id,
              meal_id,
              meal_title,
              quantity,
              unit_price,
              meals (
                id,
                title,
                image_url
              )
            ),
            restaurants (
              restaurant_name
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'payment_status': paymentStatus})
          .eq('id', orderId);
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      // Get order items to restore meal quantities
      final orderItems = await _supabase
          .from('order_items')
          .select('meal_id, quantity')
          .eq('order_id', orderId);

      // Restore meal quantities
      for (final item in orderItems as List) {
        await _supabase.rpc('increment_meal_quantity', params: {
          'meal_id': item['meal_id'],
          'qty': item['quantity'],
        });
      }

      // Update order status
      await updateOrderStatus(orderId, 'cancelled');
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }
}
