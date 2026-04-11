import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Response from create-payment-intent Edge Function
class PaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;
  final String customerId;
  final String ephemeralKey;
  final double amount;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.customerId,
    required this.ephemeralKey,
    required this.amount,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['clientSecret'] as String,
      paymentIntentId: json['paymentIntentId'] as String,
      customerId: json['customerId'] as String,
      ephemeralKey: json['ephemeralKey'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// Response from get-payment-status Edge Function
class PaymentStatusResponse {
  final String status;
  final List<OrderInfo> orders;
  final String? message;

  PaymentStatusResponse({
    required this.status,
    required this.orders,
    this.message,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    final ordersList = json['orders'] as List? ?? [];
    return PaymentStatusResponse(
      status: json['status'] as String,
      orders: ordersList.map((o) => OrderInfo.fromJson(o)).toList(),
      message: json['message'] as String?,
    );
  }
}

class OrderInfo {
  final String orderId;
  final String orderNumber;
  final double totalAmount;

  OrderInfo({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }
}

/// Service for handling Stripe payments
class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a PaymentIntent on the backend
  /// This calculates prices server-side for security
  Future<PaymentIntentResponse> createPaymentIntent({
    required String deliveryMethod,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? specialInstructions,
    String? ngoId,
    String? promoCode,
  }) async {
    try {
      debugPrint('🚀 Creating PaymentIntent...');
      debugPrint('  Delivery Method: $deliveryMethod');
      debugPrint('  Delivery Address: $deliveryAddress');
      debugPrint('  NGO ID: $ngoId');
      debugPrint('  Promo Code: $promoCode');
      
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ User not authenticated');
        throw Exception('Please login first');
      }
      debugPrint('✅ User authenticated: ${user.id}');

      final response = await _supabase.functions.invoke(
        'create-payment-intent',
        body: {
          'delivery_method': deliveryMethod,
          'delivery_address': deliveryAddress,
          'delivery_latitude': deliveryLatitude,
          'delivery_longitude': deliveryLongitude,
          'special_instructions': specialInstructions,
          'ngo_id': ngoId,
          'promo_code': promoCode,
        },
      );

      debugPrint('📦 Response status: ${response.status}');

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map ? errorData['error'] : 'Failed to create payment';
        debugPrint('❌ Error: $errorMessage');
        throw Exception(errorMessage);
      }

      final paymentIntent = PaymentIntentResponse.fromJson(response.data);
      debugPrint('✅ PaymentIntent created: ${paymentIntent.paymentIntentId}');
      debugPrint('   Amount: ${paymentIntent.amount} EGP');

      return paymentIntent;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating PaymentIntent: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Wait for order creation after payment success
  /// Polls the backend until webhook creates the order
  Future<List<OrderInfo>> waitForOrderCreation(
    String paymentIntentId, {
    int maxAttempts = 25,
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    debugPrint('⏳ Waiting for order creation...');
    debugPrint('   PaymentIntent ID: $paymentIntentId');
    debugPrint('   Max attempts: $maxAttempts');
    debugPrint('   Poll interval: ${pollInterval.inSeconds}s');

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('🔍 Polling attempt $attempt/$maxAttempts...');

        final response = await _supabase.functions.invoke(
          'get-payment-status',
          body: {
            'payment_intent_id': paymentIntentId,
          },
        );

        if (response.status == 200) {
          final data = Map<String, dynamic>.from(
            response.data is Map
                ? response.data as Map
                : <String, dynamic>{},
          );
          final statusResponse = PaymentStatusResponse.fromJson(data);

          debugPrint('   Status: ${statusResponse.status}');

          if (statusResponse.status == 'completed' &&
              statusResponse.orders.isNotEmpty) {
            debugPrint('✅ Orders created!');
            for (final order in statusResponse.orders) {
              debugPrint('   - ${order.orderNumber}: ${order.totalAmount} EGP');
            }
            return statusResponse.orders;
          }

          if (statusResponse.status == 'succeeded' ||
              statusResponse.status == 'processing') {
            debugPrint(
              '   Payment ${statusResponse.status}, waiting for webhook...',
            );
          } else {
            debugPrint('   Payment status: ${statusResponse.status}');
          }
        }

        // Wait before next attempt
        if (attempt < maxAttempts) {
          await Future.delayed(pollInterval);
        }
      } catch (e) {
        debugPrint('⚠️ Polling error (attempt $attempt): $e');
        // Continue polling even if one attempt fails
        if (attempt < maxAttempts) {
          await Future.delayed(pollInterval);
        }
      }
    }

    debugPrint('⏰ Polling timeout - last-chance status check');
    try {
      final last = await getPaymentStatus(paymentIntentId);
      if (last.status == 'completed' && last.orders.isNotEmpty) {
        return last.orders;
      }
    } catch (e) {
      debugPrint('⚠️ Final status check failed: $e');
    }
    return [];
  }

  /// Check payment status without waiting
  Future<PaymentStatusResponse> getPaymentStatus(String paymentIntentId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-payment-status',
        body: {
          'payment_intent_id': paymentIntentId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to get payment status');
      }

      final data = Map<String, dynamic>.from(
        response.data is Map ? response.data as Map : <String, dynamic>{},
      );
      return PaymentStatusResponse.fromJson(data);
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      rethrow;
    }
  }
}
