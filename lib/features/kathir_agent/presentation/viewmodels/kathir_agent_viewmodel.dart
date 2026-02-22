import 'package:flutter/material.dart';
import '../../data/models/agent_message.dart';
import '../../data/services/kathir_agent_service.dart';

class KathirAgentViewModel extends ChangeNotifier {
  final KathirAgentService _service = KathirAgentService();
  
  final List<AgentMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  bool _isAgentAvailable = false;
  
  List<AgentMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get isAgentAvailable => _isAgentAvailable;
  
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
      _isAgentAvailable = await _service.checkHealth();
      
      if (_isAgentAvailable) {
        // Add welcome message
        _addMessage(AgentMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Hi! I\'m Kathir AI Assistant. I can help you find meals, build your cart within budget, and save on surplus food. What would you like today?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
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
    notifyListeners();
    
    try {
      // Send to agent
      final response = await _service.chat(message: message);
      _addMessage(response);
    } catch (e) {
      _error = 'Failed to send message: $e';
      print('❌ Send message error: $e');
      
      // Add error message
      _addMessage(AgentMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
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
  void clearConversation() {
    _messages.clear();
    _service.resetConversation();
    _error = null;
    notifyListeners();
    
    // Re-initialize
    initialize();
  }
  
  void _addMessage(AgentMessage message) {
    _messages.add(message);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messages.clear();
    super.dispose();
  }
}
