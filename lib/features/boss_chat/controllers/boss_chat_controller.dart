import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/agent_response.dart';
import '../models/chat_message.dart';
import '../services/boss_chat_api_service.dart';

/// Controller for Boss AI Chat - manages state and business logic
class BossChatController extends ChangeNotifier {
  final BossChatApiService _apiService;
  final String userId;
  
  // State
  final List<ChatMessage> _messages = [];
  String? _sessionId;
  int _messageCount = 0;
  int _cartCount = 0;
  double _cartTotal = 0.0;
  bool _isLoading = false;
  bool _isConnected = false;
  String _connectionStatus = 'Connecting...';

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get sessionId => _sessionId;
  int get messageCount => _messageCount;
  int get cartCount => _cartCount;
  double get cartTotal => _cartTotal;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  BossChatController({
    required this.userId,
    BossChatApiService? apiService,
  }) : _apiService = apiService ?? BossChatApiService() {
    _init();
  }

  void _init() {
    // Add welcome message
    _addWelcomeMessage();
    // Check server status
    checkServerStatus();
    // Update cart stats
    updateCartStats();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: const Uuid().v4(),
      sender: MessageSender.bot,
      type: MessageType.text,
      text: '''Welcome to Boss Food Ordering! 👋

I'm your AI-powered food assistant using advanced language models. I can help you:

🔍 Search for meals by name, category, or description
💰 Find meals within your budget
🚫 Filter by dietary restrictions and allergens
🛒 Build and manage your cart intelligently
⭐ Browse your favorite meals
🤖 Understand natural language requests

Powered by: Google Gemini 2.0 Flash + LangGraph

Try asking: "Show me chicken dishes under 80 EGP" or "Build me a cart with 500 EGP"''',
    );
    _messages.add(welcomeMessage);
    notifyListeners();
  }

  /// Check server health status
  Future<void> checkServerStatus() async {
    try {
      await _apiService.checkHealth();
      _isConnected = true;
      _connectionStatus = 'Connected';
    } catch (e) {
      _isConnected = false;
      _connectionStatus = 'Offline';
    }
    notifyListeners();
  }

  /// Update cart statistics
  Future<void> updateCartStats() async {
    try {
      final data = await _apiService.getCart();
      if (data['ok'] == true) {
        _cartCount = data['count'] ?? 0;
        _cartTotal = (data['total'] ?? 0).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating cart stats: $e');
    }
  }

  /// Send a message to the AI agent
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      sender: MessageSender.user,
      type: MessageType.text,
      text: text,
    );
    _messages.add(userMessage);
    _messageCount++;
    notifyListeners();

    // Add loading indicator
    final loadingId = const Uuid().v4();
    final loadingMessage = ChatMessage(
      id: loadingId,
      sender: MessageSender.bot,
      type: MessageType.loading,
    );
    _messages.add(loadingMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // Call agent API
      final response = await _apiService.sendAgentChat(
        message: text,
        sessionId: _sessionId,
        userId: userId,
      );

      // Remove loading message
      _messages.removeWhere((m) => m.id == loadingId);

      if (response.ok) {
        // Store session ID
        _sessionId = response.sessionId;

        // Parse agent response
        try {
          final parsedResponse = ParsedAgentResponse.fromJson(
            json.decode(response.response),
          );

          // Handle different action types
          if (parsedResponse.action == 'search' && parsedResponse.data != null) {
            _handleSearchResponse(parsedResponse);
          } else if (parsedResponse.action == 'cart' && parsedResponse.data != null) {
            _handleCartResponse(parsedResponse);
          } else if (parsedResponse.action == 'build' && parsedResponse.data != null) {
            _handleBuildCartResponse(parsedResponse);
          } else {
            // Default: show message as text
            _addBotTextMessage(parsedResponse.message);
          }
        } catch (e) {
          // If JSON parsing fails, show as text
          _addBotTextMessage(response.response);
        }

        // Update cart stats
        await updateCartStats();
      } else {
        _addBotTextMessage('Error: ${response.error ?? "Unknown error"}');
      }
    } catch (e) {
      // Remove loading message
      _messages.removeWhere((m) => m.id == loadingId);
      _addBotTextMessage('Error communicating with agent: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleSearchResponse(ParsedAgentResponse response) {
    final data = response.data;
    if (data['meals'] != null) {
      final meals = (data['meals'] as List)
          .map((m) => MealResult.fromJson(m))
          .toList();

      // Add message with meal results
      final message = ChatMessage(
        id: const Uuid().v4(),
        sender: MessageSender.bot,
        type: MessageType.mealResults,
        text: response.message,
        data: meals,
      );
      _messages.add(message);
    } else {
      _addBotTextMessage(response.message);
    }
  }

  void _handleCartResponse(ParsedAgentResponse response) {
    final cartData = CartData.fromJson(response.data);
    
    final message = ChatMessage(
      id: const Uuid().v4(),
      sender: MessageSender.bot,
      type: MessageType.cart,
      text: response.message,
      data: cartData,
    );
    _messages.add(message);
  }

  void _handleBuildCartResponse(ParsedAgentResponse response) {
    final buildCartData = BuildCartData.fromJson(response.data);
    
    final message = ChatMessage(
      id: const Uuid().v4(),
      sender: MessageSender.bot,
      type: MessageType.buildCart,
      text: response.message,
      data: buildCartData,
    );
    _messages.add(message);
  }

  void _addBotTextMessage(String text) {
    final message = ChatMessage(
      id: const Uuid().v4(),
      sender: MessageSender.bot,
      type: MessageType.text,
      text: text,
    );
    _messages.add(message);
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _sessionId = null;
    _messageCount = 0;
    _addWelcomeMessage();
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
