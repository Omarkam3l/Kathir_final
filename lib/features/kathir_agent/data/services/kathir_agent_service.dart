import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agent_message.dart';

class KathirAgentService {
  // Hugging Face Space URL
  static const String baseUrl = 'https://omark3405-boss-restaurant-chat.hf.space';
  // static const String baseUrl = 'http://localhost:8000'; // Local development
  
  final _supabase = Supabase.instance.client;
  String? _threadId;

  /// Chat with Kathir Agent
  Future<AgentMessage> chat({
    required String message,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      // Get JWT token for authentication
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('No access token available');
      
      print('🤖 Sending message to Kathir Agent: $message');
      print('🔐 Using JWT token for authentication');
      
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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - agent took too long to respond');
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save session ID for conversation continuity
        if (data['session_id'] != null) {
          _threadId = data['session_id'];
        }
        
        // Parse the nested response JSON
        String messageText = 'Response received';
        Map<String, dynamic>? responseData;
        
        if (data['response'] != null) {
          try {
            final responseJson = jsonDecode(data['response']);
            messageText = responseJson['message'] ?? 'Response received';
            responseData = responseJson['data'];
            
            print('📦 Response data keys: ${responseData?.keys.toList()}');
            print('📦 Has items: ${responseData?.containsKey('items')}');
            print('📦 Has meals: ${responseData?.containsKey('meals')}');
            
            // Enrich meal data with images from Supabase
            if (responseData != null && responseData['items'] != null) {
              final items = responseData['items'] as List;
              print('🔍 Enriching ${items.length} items with Supabase data...');
              print('📦 First item: ${items.isNotEmpty ? items[0] : "empty"}');
              final enrichedItems = await _enrichMealData(items);
              responseData['meals'] = enrichedItems;
              print('✅ Enriched meals: ${enrichedItems.length}');
              print('📦 First enriched meal: ${enrichedItems.isNotEmpty ? enrichedItems[0] : "empty"}');
            } else if (responseData != null && responseData['meals'] != null) {
              // Already has meals, try to enrich them too
              final meals = responseData['meals'] as List;
              print('🔍 Enriching ${meals.length} existing meals...');
              final enrichedMeals = await _enrichMealData(meals);
              responseData['meals'] = enrichedMeals;
              print('✅ Enriched meals: ${enrichedMeals.length}');
            } else {
              print('⚠️ No items or meals found in response data');
            }
          } catch (e) {
            print('⚠️ Failed to parse response JSON: $e');
            messageText = data['response'].toString();
          }
        }
        
        final agentMessage = AgentMessage.fromJson({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'message': messageText,
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
          'data': responseData,
        });
        
        print('📬 Created AgentMessage:');
        print('   - Message: $messageText');
        print('   - Has data: ${agentMessage.data != null}');
        print('   - Has meals: ${agentMessage.data?.meals != null}');
        print('   - Meals count: ${agentMessage.data?.meals?.length ?? 0}');
        
        return agentMessage;
      } else {
        throw Exception('Failed to chat: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Kathir Agent error: $e');
      rethrow;
    }
  }
  
  /// Search meals directly (without agent)
  Future<List<AgentMeal>> searchMeals({
    required String query,
    double? maxPrice,
    double? minPrice,
    String? category,
  }) async {
    try {
      final queryParams = {
        'query': query,
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (category != null) 'category': category,
      };
      
      final uri = Uri.parse('$baseUrl/meals/search').replace(
        queryParameters: queryParams,
      );
      
      print('🔍 Searching meals: $uri');
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = (data['meals'] as List?)
            ?.map((m) => AgentMeal.fromJson(m))
            .toList() ?? [];
        
        print('✅ Found ${meals.length} meals');
        return meals;
      } else {
        throw Exception('Failed to search meals: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }
  
  /// Get cart from agent
  Future<List<AgentMeal>> getCart() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('No access token available');
      
      final response = await http.get(
        Uri.parse('$baseUrl/cart/?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['items'] as List?)
            ?.map((m) => AgentMeal.fromJson(m))
            .toList() ?? [];
        
        return items;
      } else {
        throw Exception('Failed to get cart');
      }
    } catch (e) {
      print('❌ Cart error: $e');
      return [];
    }
  }
  
  /// Build cart with budget
  Future<AgentMessage> buildCart({
    required double budget,
    String? restaurantName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('No access token available');
      
      final response = await http.post(
        Uri.parse('$baseUrl/cart/build'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'budget': budget,
          'user_id': userId,
          'restaurant_name': restaurantName ?? 'Malfoof Restaurant',
        }),
      ).timeout(
        const Duration(seconds: 30),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return AgentMessage.fromJson({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'message': data['message'] ?? 'Cart built successfully',
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
          'data': data,
        });
      } else {
        throw Exception('Failed to build cart');
      }
    } catch (e) {
      print('❌ Build cart error: $e');
      rethrow;
    }
  }
  
  /// Reset conversation
  void resetConversation() {
    _threadId = null;
  }
  
  /// Enrich meal data with images and details from Supabase
  Future<List<Map<String, dynamic>>> _enrichMealData(List items) async {
    final enrichedItems = <Map<String, dynamic>>[];
    
    for (final item in items) {
      final mealId = item['meal_id'] ?? item['id'];
      if (mealId == null) {
        print('⚠️ Meal has no ID, skipping enrichment');
        enrichedItems.add(item);
        continue;
      }
      
      try {
        print('🔍 Fetching meal details for: $mealId');
        
        // Fetch meal details from Supabase
        final mealData = await _supabase
            .from('meals')
            .select('id, title, image_url, discounted_price, original_price')
            .eq('id', mealId)
            .maybeSingle();
        
        if (mealData != null) {
          print('✅ Found meal: ${mealData['title']}, image: ${mealData['image_url']}');
          
          // Merge API data with Supabase data
          enrichedItems.add({
            'id': mealData['id'],
            'meal_id': mealData['id'],
            'title': mealData['title'] ?? item['title'],
            'image_url': mealData['image_url'],
            'original_price': mealData['original_price'],
            'unit_price': item['unit_price'] ?? item['price'] ?? mealData['discounted_price'],
            'quantity': item['quantity'] ?? 1,
            'subtotal': item['subtotal'],
          });
        } else {
          print('⚠️ Meal not found in database: $mealId');
          enrichedItems.add(item);
        }
      } catch (e) {
        print('❌ Failed to enrich meal $mealId: $e');
        // Use original data if enrichment fails
        enrichedItems.add(item);
      }
    }
    
    return enrichedItems;
  }
  
  /// Check if agent is available
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(
        const Duration(seconds: 5),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}
