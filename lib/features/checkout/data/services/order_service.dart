import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../profile/presentation/providers/foodie_state.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Map delivery type from frontend to database values
  String _mapDeliveryType(String deliveryType) {
    switch (deliveryType.toLowerCase()) {
      case 'donate':
        return 'donation';
      case 'delivery':
        return 'delivery';
      case 'pickup':
        return 'pickup';
      default:
        return 'delivery'; // Default fallback
    }
  }

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
    String? ngoId,  // Add NGO ID parameter
  }) async {
    try {
      debugPrint('🚀 ========== CREATE ORDER START ==========');
      debugPrint('📦 Order Details:');
      debugPrint('  User ID: $userId');
      debugPrint('  Delivery Type: $deliveryType');
      debugPrint('  Items Count: ${items.length}');
      debugPrint('  Subtotal: $subtotal');
      debugPrint('  Service Fee: $serviceFee');
      debugPrint('  Delivery Fee: $deliveryFee');
      debugPrint('  Total: $total');
      debugPrint('  Payment Method: $paymentMethod');
      debugPrint('  Delivery Address: $deliveryAddress');
      debugPrint('  NGO ID: $ngoId');
      
      // Map delivery type to match database constraint
      final mappedDeliveryType = _mapDeliveryType(deliveryType);
      debugPrint('✅ Mapped delivery type: $deliveryType → $mappedDeliveryType');
      
      // Validate inputs
      if (items.isEmpty) {
        debugPrint('❌ Validation failed: Empty cart');
        throw Exception('Cannot create order with empty cart');
      }
      
      // Validate NGO for donation orders
      if (mappedDeliveryType == 'donation' && (ngoId == null || ngoId.isEmpty)) {
        debugPrint('❌ Validation failed: No NGO selected for donation');
        throw Exception('NGO ID is required for donation orders');
      }
      
      // Validate numeric values
      if (subtotal.isNaN || subtotal.isInfinite || subtotal < 0) {
        debugPrint('❌ Validation failed: Invalid subtotal: $subtotal');
        throw Exception('Invalid subtotal value: $subtotal');
      }
      if (serviceFee.isNaN || serviceFee.isInfinite || serviceFee < 0) {
        debugPrint('❌ Validation failed: Invalid service fee: $serviceFee');
        throw Exception('Invalid service fee value: $serviceFee');
      }
      if (deliveryFee.isNaN || deliveryFee.isInfinite || deliveryFee < 0) {
        debugPrint('❌ Validation failed: Invalid delivery fee: $deliveryFee');
        throw Exception('Invalid delivery fee value: $deliveryFee');
      }
      if (total.isNaN || total.isInfinite || total < 0) {
        debugPrint('❌ Validation failed: Invalid total: $total');
        throw Exception('Invalid total value: $total');
      }
      
      debugPrint('✅ All validations passed');

      // Group items by restaurant
      debugPrint('📊 Grouping items by restaurant...');
      final Map<String, List<CartItem>> itemsByRestaurant = {};
      for (final item in items) {
        final restaurantId = item.meal.restaurant.id;
        if (!itemsByRestaurant.containsKey(restaurantId)) {
          itemsByRestaurant[restaurantId] = [];
        }
        itemsByRestaurant[restaurantId]!.add(item);
      }
      debugPrint('✅ Found ${itemsByRestaurant.length} restaurant(s)');

      final List<Map<String, dynamic>> createdOrders = [];

      // Create separate order for each restaurant
      int restaurantIndex = 0;
      for (final entry in itemsByRestaurant.entries) {
        restaurantIndex++;
        final restaurantId = entry.key;
        final restaurantItems = entry.value;
        
        debugPrint('');
        debugPrint('🏪 Processing Restaurant $restaurantIndex/${ itemsByRestaurant.length}');
        debugPrint('  Restaurant ID: $restaurantId');
        debugPrint('  Items: ${restaurantItems.length}');

        // Calculate subtotal for this restaurant
        final restaurantSubtotal = restaurantItems.fold<double>(
          0,
          (sum, item) => sum + (item.meal.donationPrice * item.qty),
        );
        debugPrint('  Subtotal: $restaurantSubtotal');

        // Validate restaurant subtotal
        if (restaurantSubtotal.isNaN || restaurantSubtotal.isInfinite || restaurantSubtotal < 0) {
          debugPrint('❌ Invalid restaurant subtotal: $restaurantSubtotal');
          throw Exception('Invalid restaurant subtotal: $restaurantSubtotal');
        }

        // Calculate fees proportionally based on subtotal
        final proportion = subtotal > 0 ? restaurantSubtotal / subtotal : 0;
        final restaurantServiceFee = serviceFee * proportion;
        final restaurantDeliveryFee = deliveryFee * proportion;
        final restaurantTotal = restaurantSubtotal + restaurantServiceFee + restaurantDeliveryFee;
        
        debugPrint('  Service Fee: $restaurantServiceFee');
        debugPrint('  Delivery Fee: $restaurantDeliveryFee');
        debugPrint('  Total: $restaurantTotal');

        // Validate calculated values
        if (restaurantServiceFee.isNaN || restaurantServiceFee.isInfinite) {
          debugPrint('❌ Invalid restaurant service fee: $restaurantServiceFee');
          throw Exception('Invalid restaurant service fee: $restaurantServiceFee');
        }
        if (restaurantDeliveryFee.isNaN || restaurantDeliveryFee.isInfinite) {
          debugPrint('❌ Invalid restaurant delivery fee: $restaurantDeliveryFee');
          throw Exception('Invalid restaurant delivery fee: $restaurantDeliveryFee');
        }
        if (restaurantTotal.isNaN || restaurantTotal.isInfinite) {
          debugPrint('❌ Invalid restaurant total: $restaurantTotal');
          throw Exception('Invalid restaurant total: $restaurantTotal');
        }

        // Generate order number
        debugPrint('  Generating order number...');
        final orderNumberResponse = await _supabase.rpc('generate_order_number');
        final orderNumber = orderNumberResponse as String;
        debugPrint('  ✅ Order Number: $orderNumber');

        // 1. Create order for this restaurant
        debugPrint('  Creating order record...');
        final orderData = {
          'user_id': userId,
          'restaurant_id': restaurantId,
          'order_number': orderNumber,
          'status': 'pending',
          'delivery_type': mappedDeliveryType,  // Use mapped delivery type
          'subtotal': restaurantSubtotal,
          'service_fee': restaurantServiceFee,
          'delivery_fee': restaurantDeliveryFee,
          'platform_commission': restaurantServiceFee, // Platform commission
          'total_amount': restaurantTotal,
          'delivery_address': deliveryAddress,
          'payment_method': paymentMethod ?? 'card',
          'payment_status': 'pending',
        };
        
        // Add NGO ID for donation orders
        if (mappedDeliveryType == 'donation' && ngoId != null && ngoId.isNotEmpty) {
          orderData['ngo_id'] = ngoId;
          debugPrint('  NGO ID added: $ngoId');
        }
        
        debugPrint('  Order data prepared: ${orderData.keys.join(', ')}');
        
        try {
          final orderResponse = await _supabase
              .from('orders')
              .insert(orderData)
              .select()
              .single();

          final orderId = orderResponse['id'] as String;
          debugPrint('  ✅ Order created with ID: $orderId');

          // 2. Create order items for this restaurant
          debugPrint('  Creating ${restaurantItems.length} order items...');
          final orderItems = restaurantItems.map((item) {
            debugPrint('    - ${item.meal.title} x${item.qty} @ ${item.meal.donationPrice}');
            return {
              'order_id': orderId,
              'meal_id': item.meal.id,
              'meal_title': item.meal.title,
              'quantity': item.qty,
              'unit_price': item.meal.donationPrice,
            };
          }).toList();

          await _supabase.from('order_items').insert(orderItems);
          debugPrint('  ✅ Order items created');

          // 3. Update meal quantities
          debugPrint('  Updating meal quantities...');
          for (final item in restaurantItems) {
            await _supabase.rpc('decrement_meal_quantity', params: {
              'meal_id': item.meal.id,
              'qty': item.qty,
            });
            debugPrint('    - Decremented ${item.meal.title} by ${item.qty}');
          }
          debugPrint('  ✅ Meal quantities updated');

          createdOrders.add({
            'order_id': orderId,
            'order_number': orderNumber,
            'restaurant_id': restaurantId,
            'total': restaurantTotal,
          });
          
          debugPrint('✅ Restaurant $restaurantIndex order completed');
        } catch (e, stackTrace) {
          debugPrint('❌ Error creating order for restaurant $restaurantId: $e');
          debugPrint('Stack trace: $stackTrace');
          rethrow;
        }
      }

      // 4. Clear cart after all orders are created
      debugPrint('');
      debugPrint('🧹 Clearing cart...');
      await _supabase.from('cart_items').delete().eq('user_id', userId);
      debugPrint('✅ Cart cleared');
      
      debugPrint('');
      debugPrint('🎉 ========== ORDER CREATION SUCCESS ==========');
      debugPrint('📦 Created ${createdOrders.length} order(s)');
      for (var order in createdOrders) {
        debugPrint('  - Order ${order['order_number']}: EGP ${order['total']}');
      }
      debugPrint('==============================================');

      return createdOrders;
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ ========== ORDER CREATION FAILED ==========');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('==============================================');
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
      debugPrint('Error getting order: $e');
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
      debugPrint('Error getting user orders: $e');
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
      debugPrint('Error updating order status: $e');
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
      debugPrint('Error updating payment status: $e');
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
      debugPrint('Error cancelling order: $e');
      rethrow;
    }
  }
}
