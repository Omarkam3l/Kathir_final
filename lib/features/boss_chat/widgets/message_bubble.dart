import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'meal_card_widget.dart';
import 'cart_summary_widget.dart';
import 'build_cart_summary_widget.dart';
import 'loading_indicator_widget.dart';

/// Message bubble widget - renders different message types
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: _buildMessageContent(context, isUser),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUser
              ? [const Color(0xFFf093fb), const Color(0xFFf5576c)]
              : [const Color(0xFF667eea), const Color(0xFF764ba2)],
        ),
      ),
      child: Center(
        child: Text(
          isUser ? '👤' : '🤖',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    switch (message.type) {
      case MessageType.loading:
        return const LoadingIndicatorWidget();
      case MessageType.mealResults:
        return _buildMealResultsContent(context);
      case MessageType.cart:
        return CartSummaryWidget(cartData: message.data);
      case MessageType.buildCart:
        return BuildCartSummaryWidget(buildCartData: message.data);
      case MessageType.text:
      default:
        return _buildTextContent(context, isUser);
    }
  }

  Widget _buildTextContent(BuildContext context, bool isUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF2563eb) : const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.text ?? '',
        style: TextStyle(
          fontSize: 14,
          color: isUser ? Colors.white : const Color(0xFF1e293b),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildMealResultsContent(BuildContext context) {
    final meals = message.data as List<dynamic>;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.text != null && message.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                message.text!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
            ),
          ...meals.map((meal) => MealCardWidget(meal: meal)),
        ],
      ),
    );
  }
}
