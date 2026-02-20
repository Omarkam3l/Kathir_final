/// Chat message model for UI
enum MessageSender { user, bot }

enum MessageType {
  text,
  mealResults,
  cart,
  buildCart,
  loading,
}

class ChatMessage {
  final String id;
  final MessageSender sender;
  final MessageType type;
  final String? text;
  final dynamic data; // Can be List<MealResult>, CartData, BuildCartData
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    this.text,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    MessageSender? sender,
    MessageType? type,
    String? text,
    dynamic data,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      text: text ?? this.text,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
