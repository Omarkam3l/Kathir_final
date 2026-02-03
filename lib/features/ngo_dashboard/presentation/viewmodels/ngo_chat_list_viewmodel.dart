import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/entities/conversation.dart';

class NgoChatListViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = true;
  String? error;
  List<Conversation> conversations = [];
  int totalUnreadCount = 0;

  Future<void> loadConversations() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user role to determine which filter to use
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = profile['role'] as String?;

      // Query conversations based on role - apply filter BEFORE order
      final res = role == 'ngo'
          ? await _supabase
              .from('conversation_details')
              .select()
              .eq('ngo_id', userId)
              .order('last_message_at', ascending: false)
          : await _supabase
              .from('conversation_details')
              .select()
              .eq('restaurant_id', userId)
              .order('last_message_at', ascending: false);

      conversations = (res as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      totalUnreadCount = conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getOrCreateConversation(String restaurantId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Check if conversation exists
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('ngo_id', userId)
          .eq('restaurant_id', restaurantId)
          .maybeSingle();

      if (existing != null) {
        return existing['id'].toString();
      }

      // Create new conversation
      final newConv = await _supabase
          .from('conversations')
          .insert({
            'ngo_id': userId,
            'restaurant_id': restaurantId,
          })
          .select('id')
          .single();

      return newConv['id'].toString();
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }
}
