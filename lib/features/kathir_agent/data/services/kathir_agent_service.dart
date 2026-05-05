import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agent_message.dart';

class KathirAgentService {
  static const String baseUrl = 'https://omark3405-kathir-v2.hf.space';
  
  final _supabase = Supabase.instance.client;
  String? _threadId;

  /// Chat with Kathir Agent
  Future<AgentMessage> chat({required String message}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('No access token available');
      
      print('🤖 Sending: $message');
      
      final response = await http.post(
        Uri.parse('$baseUrl/agent/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'user_id': userId,
          'thread_id': _threadId,
        }),
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
  
  /// Parse API response
  Future<AgentMessage> _parseResponse(String responseBody) async {
    try {
      final data = jsonDecode(responseBody);
      
      print('📦 Response keys: ${data.keys.toList()}');
      print('📦 Raw data: ${responseBody.substring(0, responseBody.length > 300 ? 300 : responseBody.length)}');
      
      // Save session ID
      if (data['session_id'] != null) {
        _threadId = data['session_id'];
      }
      
      String messageText = 'Response received';
      Map<String, dynamic>? responseData;
      
      // Check if response is directly in the root (new V2 format)
      if (data['message'] != null && !data.containsKey('response')) {
        print('✅ New V2 format detected');
        messageText = data['message'];
        responseData = data['data'];
        
        // Convert items to meals if present
        if (responseData != null && responseData['items'] != null) {
          final items = responseData['items'] as List;
          responseData['meals'] = items.map((item) => {
            'id': item['meal_id'] ?? item['id'],
            'meal_id': item['meal_id'] ?? item['id'],
            'title': item['title'],
            'image_url': item['image_url'],
            'price': item['unit_price'] ?? item['price'],
            'unit_price': item['unit_price'] ?? item['price'],
            'original_price': item['original_price'],
            'quantity': item['quantity'] ?? 1,
            'subtotal': item['subtotal'],
            'restaurant_name': 'Malfoof Restaurant',
          }).toList();
        }
      }
      // Old format with nested response
      else if (data['response'] != null) {
        print('✅ Old format detected');
        dynamic responseValue = data['response'];
        
        // Decode if string
        if (responseValue is String) {
          try {
            responseValue = jsonDecode(responseValue);
          } catch (e) {
            messageText = responseValue;
            responseValue = null;
          }
        }
        
        // Parse response object
        if (responseValue is Map<String, dynamic>) {
          if (responseValue.containsKey('name') && responseValue.containsKey('arguments')) {
            // Tool call
            messageText = _getToolCallMessage(responseValue);
          } else if (responseValue.containsKey('error')) {
            // Error
            messageText = responseValue['error'] ?? 'An error occurred';
          } else {
            // Normal message
            messageText = responseValue['message'] ?? responseValue['text'] ?? 'Response received';
            responseData = responseValue['data'];
            
            // Convert items to meals format
            if (responseData != null && responseData['items'] != null) {
              final items = responseData['items'] as List;
              responseData['meals'] = items.map((item) => {
                'id': item['meal_id'] ?? item['id'],
                'meal_id': item['meal_id'] ?? item['id'],
                'title': item['title'],
                'image_url': item['image_url'],
                'price': item['unit_price'] ?? item['price'],
                'unit_price': item['unit_price'] ?? item['price'],
                'original_price': item['original_price'],
                'quantity': item['quantity'] ?? 1,
                'subtotal': item['subtotal'],
                'restaurant_name': 'Malfoof Restaurant',
              }).toList();
            }
          }
        }
      }
      
      print('💬 Final message: $messageText');
      
      return AgentMessage.fromJson({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': messageText,
        'isUser': false,
        'timestamp': DateTime.now().toIso8601String(),
        'data': responseData,
      });
    } catch (e, stack) {
      print('⚠️ Parse error: $e');
      print('⚠️ Stack: $stack');
      return AgentMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I had trouble understanding the response.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Get friendly message for tool calls
  String _getToolCallMessage(Map<String, dynamic> toolCall) {
    final action = toolCall['arguments']?['action'];
    
    switch (action) {
      case 'build_cart':
        final budget = toolCall['arguments']?['payload']?['budget'];
        return 'Building your cart with $budget EGP budget...';
      case 'search':
      case 'search_meals':
        final query = toolCall['arguments']?['payload']?['query'];
        return query != null ? 'Searching for $query meals...' : 'Searching for meals...';
      default:
        return 'Processing your request...';
    }
  }
  
  /// Build cart with budget (legacy method - use chat instead)
  Future<AgentMessage> buildCart({
    required double budget,
    String? restaurantName,
  }) async {
    // Just use the chat method with a budget message
    return chat(message: 'Build me a cart with $budget EGP budget');
  }
  
  /// Reset conversation
  void resetConversation() {
    _threadId = null;
  }
  
  /// Check health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
