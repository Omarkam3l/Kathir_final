class Conversation {
  final String id;
  final String ngoId;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantAvatar;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.ngoId,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantAvatar,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });
}
