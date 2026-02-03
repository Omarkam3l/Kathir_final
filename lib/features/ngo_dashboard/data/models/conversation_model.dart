import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.ngoId,
    required super.restaurantId,
    required super.restaurantName,
    super.restaurantAvatar,
    super.lastMessage,
    required super.lastMessageAt,
    super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'].toString(),
      ngoId: json['ngo_id'].toString(),
      restaurantId: json['restaurant_id'].toString(),
      restaurantName: json['other_party_name'] ?? 
                      json['restaurant_business_name'] ?? 
                      json['restaurant_name'] ?? 
                      'Unknown',
      restaurantAvatar: json['other_party_avatar'] ?? json['restaurant_avatar'],
      lastMessage: json['last_message'],
      lastMessageAt: DateTime.parse(json['last_message_at']),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ngo_id': ngoId,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'restaurant_avatar': restaurantAvatar,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt.toIso8601String(),
        'unread_count': unreadCount,
      };
}
