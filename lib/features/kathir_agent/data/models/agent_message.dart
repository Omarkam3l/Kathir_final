class AgentMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AgentMessageData? data;

  AgentMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.data,
  });

  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    return AgentMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['message'] ?? json['content'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      data: json['data'] != null ? AgentMessageData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'data': data?.toJson(),
    };
  }
}

class AgentMessageData {
  final List<AgentMeal>? meals;
  final int? count;
  final String? action;
  final double? total;
  final double? remainingBudget;

  AgentMessageData({
    this.meals,
    this.count,
    this.action,
    this.total,
    this.remainingBudget,
  });

  factory AgentMessageData.fromJson(Map<String, dynamic> json) {
    return AgentMessageData(
      meals: json['meals'] != null
          ? (json['meals'] as List).map((m) => AgentMeal.fromJson(m)).toList()
          : null,
      count: json['count'],
      action: json['action'],
      total: json['total']?.toDouble(),
      remainingBudget: json['remaining_budget']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meals': meals?.map((m) => m.toJson()).toList(),
      'count': count,
      'action': action,
      'total': total,
      'remaining_budget': remainingBudget,
    };
  }
}

class AgentMeal {
  final String id;
  final String title;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final String restaurantName;
  final int quantity;
  final bool addedToCart;

  AgentMeal({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    required this.restaurantName,
    this.quantity = 1,
    this.addedToCart = false,
  });

  factory AgentMeal.fromJson(Map<String, dynamic> json) {
    return AgentMeal(
      id: json['id'] ?? json['meal_id'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? json['discounted_price'] ?? json['unit_price'] ?? json['subtotal'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      imageUrl: json['image_url'] ?? json['image'], // Fallback to 'image' field
      restaurantName: json['restaurant_name'] ?? 'Malfoof Restaurant', // Default restaurant
      quantity: json['quantity'] ?? 1,
      addedToCart: json['added_to_cart'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'original_price': originalPrice,
      'image_url': imageUrl,
      'restaurant_name': restaurantName,
      'quantity': quantity,
      'added_to_cart': addedToCart,
    };
  }

  AgentMeal copyWith({
    String? id,
    String? title,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? restaurantName,
    int? quantity,
    bool? addedToCart,
  }) {
    return AgentMeal(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      restaurantName: restaurantName ?? this.restaurantName,
      quantity: quantity ?? this.quantity,
      addedToCart: addedToCart ?? this.addedToCart,
    );
  }
}
