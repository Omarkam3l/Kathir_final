import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/agent_message.dart';
import '../../data/services/kathir_agent_service.dart';

class KathirAgentViewModel extends ChangeNotifier {
  final KathirAgentService _service = KathirAgentService();
  
  final List<AgentMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  bool _isAgentAvailable = false;
  String? _sessionId;
  
  static const String _messagesKey = 'kathir_agent_messages';
  static const String _sessionIdKey = 'kathir_agent_session_id';
  
  List<AgentMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get isAgentAvailable => _isAgentAvailable;
  bool get hasActiveSession => _sessionId != null && _messages.isNotEmpty;
  
  // Get all meals from messages
  List<AgentMeal> get allMeals {
    final meals = <AgentMeal>[];
    for (final message in _messages) {
      if (message.data?.meals != null) {
        meals.addAll(message.data!.meals!);
      }
    }
    return meals;
  }
  
  // Get meals not added to cart
  List<AgentMeal> get availableMeals {
    return allMeals.where((m) => !m.addedToCart).toList();
  }
  
  // Calculate total savings
  double get totalSavings {
    double savings = 0;
    for (final meal in allMeals.where((m) => m.addedToCart)) {
      if (meal.originalPrice != null) {
        savings += (meal.originalPrice! - meal.price) * meal.quantity;
      }
    }
    return savings;
  }
  
  // Calculate total spent
  double get totalSpent {
    double total = 0;
    for (final meal in allMeals.where((m) => m.addedToCart)) {
      total += meal.price * meal.quantity;
    }
    return total;
  }
  
  // Count added meals
  int get addedMealsCount {
    return allMeals.where((m) => m.addedToCart).length;
  }
  
  /// Initialize and check agent availability
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load saved session first
      await _loadSession();
      
      _isAgentAvailable = await _service.checkHealth();
      
      if (_isAgentAvailable) {
        // Only add welcome message if no existing session
        if (_messages.isEmpty) {
          _addMessage(AgentMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Hi! I\'m Kathir AI Assistant. I can help you find meals, build your cart within budget, and save on surplus food. What would you like today?',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          await _saveSession();
        }
      } else {
        _error = 'Agent is currently unavailable. Please try again later.';
      }
    } catch (e) {
      _error = 'Failed to connect to agent: $e';
      print('❌ Initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Send message to agent
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || _isSending) return;
    
    _isSending = true;
    _error = null;
    
    // Add user message
    final userMessage = AgentMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    await _saveSession();
    notifyListeners();
    
    try {
      // Send to agent
      final response = await _service.chat(message: message);
      _addMessage(response);
      await _saveSession();
    } catch (e) {
      _error = 'Failed to send message: $e';
      print('❌ Send message error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Add user-friendly error message
      String errorMessage = 'Sorry, I encountered an error. ';
      if (e.toString().contains('timeout')) {
        errorMessage += 'The request took too long. Please try again.';
      } else if (e.toString().contains('rate_limit')) {
        errorMessage += 'The service is currently busy. Please try again in a moment.';
      } else if (e.toString().contains('authentication') || e.toString().contains('token')) {
        errorMessage += 'Authentication error. Please try logging out and back in.';
      } else {
        errorMessage += 'Please try again later.';
      }
      
      _addMessage(AgentMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      await _saveSession();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
  
  /// Mark meal as added to cart
  void markMealAsAdded(String mealId) {
    for (final message in _messages) {
      if (message.data?.meals != null) {
        final meals = message.data!.meals!;
        final index = meals.indexWhere((m) => m.id == mealId);
        if (index != -1) {
          meals[index] = meals[index].copyWith(addedToCart: true);
        }
      }
    }
    notifyListeners();
  }
  
  /// Add all meals to cart
  void markAllMealsAsAdded() {
    for (final message in _messages) {
      if (message.data?.meals != null) {
        final meals = message.data!.meals!;
        for (int i = 0; i < meals.length; i++) {
          meals[i] = meals[i].copyWith(addedToCart: true);
        }
      }
    }
    notifyListeners();
  }
  
  /// Build cart with budget
  Future<void> buildCartWithBudget(double budget) async {
    if (_isSending) return;
    
    _isSending = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _service.buildCart(budget: budget);
      _addMessage(response);
    } catch (e) {
      _error = 'Failed to build cart: $e';
      print('❌ Build cart error: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
  
  /// Clear conversation
  Future<void> clearConversation() async {
    _messages.clear();
    _sessionId = null;
    _service.resetConversation();
    _error = null;
    await _clearSession();
    notifyListeners();
    
    // Re-initialize
    await initialize();
  }
  
  /// Save session to local storage
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save messages
      final messagesJson = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(_messagesKey, jsonEncode(messagesJson));
      
      // Save session ID
      if (_sessionId != null) {
        await prefs.setString(_sessionIdKey, _sessionId!);
      }
      
      print('💾 Session saved: ${_messages.length} messages');
    } catch (e) {
      print('❌ Failed to save session: $e');
    }
  }
  
  /// Load session from local storage
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load messages
      final messagesString = prefs.getString(_messagesKey);
      if (messagesString != null) {
        final List<dynamic> messagesJson = jsonDecode(messagesString);
        _messages.clear();
        _messages.addAll(
          messagesJson.map((json) => AgentMessage.fromJson(json)).toList(),
        );
        print('📂 Session loaded: ${_messages.length} messages');
      }
      
      // Load session ID
      _sessionId = prefs.getString(_sessionIdKey);
      if (_sessionId != null) {
        print('🔑 Session ID loaded: $_sessionId');
      }
    } catch (e) {
      print('❌ Failed to load session: $e');
      _messages.clear();
      _sessionId = null;
    }
  }
  
  /// Clear session from local storage
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesKey);
      await prefs.remove(_sessionIdKey);
      print('🗑️ Session cleared');
    } catch (e) {
      print('❌ Failed to clear session: $e');
    }
  }
  
  void _addMessage(AgentMessage message) {
    _messages.add(message);
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Don't clear messages on dispose - they're saved
    super.dispose();
  }
}
