/// Models for Boss AI Chat Agent responses
class AgentChatResponse {
  final bool ok;
  final String response;
  final String sessionId;
  final int? messageCount;
  final String? error;

  AgentChatResponse({
    required this.ok,
    required this.response,
    required this.sessionId,
    this.messageCount,
    this.error,
  });

  factory AgentChatResponse.fromJson(Map<String, dynamic> json) {
    return AgentChatResponse(
      ok: json['ok'] ?? false,
      response: json['response'] ?? '',
      sessionId: json['session_id'] ?? '',
      messageCount: json['message_count'],
      error: json['error'],
    );
  }
}

class ParsedAgentResponse {
  final String message;
  final dynamic data;
  final String? action;

  ParsedAgentResponse({
    required this.message,
    this.data,
    this.action,
  });

  factory ParsedAgentResponse.fromJson(Map<String, dynamic> json) {
    return ParsedAgentResponse(
      message: json['message'] ?? '',
      data: json['data'],
      action: json['action'],
    );
  }
}

class MealResult {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String restaurantName;
  final List<String> allergens;
  final double? score;

  MealResult({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.restaurantName,
    required this.allergens,
    this.score,
  });

  factory MealResult.fromJson(Map<String, dynamic> json) {
    return MealResult(
      id: json['id'] ?? json['meal_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      restaurantName: json['restaurant_name'] ?? '',
      allergens: (json['allergens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
    );
  }
}

class CartItem {
  final String cartItemId;
  final String mealId;
  final String title;
  final String? category;
  final String restaurantName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final int availableStock;
  final String? addedAt;

  CartItem({
    required this.cartItemId,
    required this.mealId,
    required this.title,
    this.category,
    required this.restaurantName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.availableStock,
    this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'] ?? '',
      mealId: json['meal_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'],
      restaurantName: json['restaurant_name'] ?? '',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      availableStock: json['available_stock'] ?? 0,
      addedAt: json['added_at'],
    );
  }
}

class CartData {
  final List<CartItem> items;
  final int count;
  final double total;
  final int? totalQuantity;

  CartData({
    required this.items,
    required this.count,
    required this.total,
    this.totalQuantity,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    return CartData(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
      totalQuantity: json['total_quantity'],
    );
  }
}

class BuildCartData {
  final List<CartItem> items;
  final double total;
  final double remainingBudget;
  final int? count;
  final int? totalQuantity;

  BuildCartData({
    required this.items,
    required this.total,
    required this.remainingBudget,
    this.count,
    this.totalQuantity,
  });

  factory BuildCartData.fromJson(Map<String, dynamic> json) {
    return BuildCartData(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] ?? 0).toDouble(),
      remainingBudget: (json['remaining_budget'] ?? 0).toDouble(),
      count: json['count'],
      totalQuantity: json['total_quantity'],
    );
  }
}

class HealthResponse {
  final String status;
  final String timestamp;

  HealthResponse({
    required this.status,
    required this.timestamp,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] ?? 'unknown',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
