import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agent_response.dart';

/// API service for Boss AI Chat - mirrors the JS fetch calls
class BossChatApiService {
  // TODO: Replace with your actual backend URL
  static const String baseUrl = 'http://localhost:8000';
  
  final http.Client _client;

  BossChatApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Check server health status
  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return HealthResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Send message to AI agent
  Future<AgentChatResponse> sendAgentChat({
    required String message,
    String? sessionId,
    required String userId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/agent/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'session_id': sessionId,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return AgentChatResponse.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get current cart
  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/cart/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get cart');
      }
    } catch (e) {
      throw Exception('Failed to get cart: $e');
    }
  }

  /// Search meals
  Future<Map<String, dynamic>> searchMeals({
    String? query,
    double? maxPrice,
    double? minPrice,
    String? category,
    List<String>? excludeAllergens,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        if (query != null && query.isNotEmpty) 'query': query,
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (category != null) 'category': category,
        'limit': limit.toString(),
      };

      if (excludeAllergens != null && excludeAllergens.isNotEmpty) {
        for (var allergen in excludeAllergens) {
          queryParams['exclude_allergens'] = allergen;
        }
      }

      final uri = Uri.parse('$baseUrl/meals/search').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search meals');
      }
    } catch (e) {
      throw Exception('Failed to search meals: $e');
    }
  }

  /// Build cart with budget
  Future<Map<String, dynamic>> buildCart({
    required double budget,
    String? restaurantId,
    String? restaurantName,
    int targetMealCount = 5,
    int maxQtyPerMeal = 3,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/cart/build'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'budget': budget,
          if (restaurantId != null) 'restaurant_id': restaurantId,
          if (restaurantName != null) 'restaurant_name': restaurantName,
          'target_meal_count': targetMealCount,
          'max_qty_per_meal': maxQtyPerMeal,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to build cart');
      }
    } catch (e) {
      throw Exception('Failed to build cart: $e');
    }
  }

  /// Search favorites
  Future<Map<String, dynamic>> searchFavorites({
    required String userId,
    String? query,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId,
        if (query != null && query.isNotEmpty) 'query': query,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/favorites/search').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search favorites');
      }
    } catch (e) {
      throw Exception('Failed to search favorites: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
