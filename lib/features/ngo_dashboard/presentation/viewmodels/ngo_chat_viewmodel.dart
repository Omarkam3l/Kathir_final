import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/message.dart';

class NgoChatViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String conversationId;
  final String restaurantName;

  NgoChatViewModel({
    required this.conversationId,
    required this.restaurantName,
  });

  bool isLoading = true;
  bool isSending = false;
  String? error;
  List<Message> messages = [];
  RealtimeChannel? _subscription;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> loadMessages() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      messages = (res as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      // Mark messages as read
      await _markMessagesAsRead();

      // Subscribe to real-time updates
      _subscribeToMessages();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToMessages() {
    _subscription = _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newMessage = MessageModel.fromJson(payload.newRecord);
            
            // Prevent duplicate messages (check if message already exists)
            final exists = messages.any((m) => m.id == newMessage.id);
            if (!exists) {
              messages.add(newMessage);
              
              // Mark as read if not mine
              if (!newMessage.isMine(currentUserId ?? '')) {
                _markMessageAsRead(newMessage.id);
              }
              
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    isSending = true;
    notifyListeners();

    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content.trim(),
      }).select().single();

      // Immediately add the sent message to the list
      final sentMessage = MessageModel.fromJson(response);
      messages.add(sentMessage);
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      error = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
