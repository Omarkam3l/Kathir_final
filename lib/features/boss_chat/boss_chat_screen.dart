import 'package:flutter/material.dart';
import 'package:kathir_final/features/authentication/presentation/blocs/auth_provider.dart';
import 'package:provider/provider.dart';
import 'controllers/boss_chat_controller.dart';
import 'widgets/message_bubble.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/stats_widget.dart';
import 'widgets/tips_widget.dart';

/// Boss AI Chat Screen - Main chat interface
class BossChatScreen extends StatefulWidget {
  const BossChatScreen({super.key});

  @override
  State<BossChatScreen> createState() => _BossChatScreenState();
}

class _BossChatScreenState extends State<BossChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(BossChatController controller) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    controller.sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _sendQuickMessage(BossChatController controller, String message) {
    _messageController.text = message;
    _sendMessage(controller);
  }

  @override
  Widget build(BuildContext context) {
    // Get authenticated user ID
    final userId = context.read<AuthProvider>().user?.id ?? '';
    
    if (userId.isEmpty) {
      // If no user is logged in, show error
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: const Center(
            child: Text(
              'Please log in to use Boss AI Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => BossChatController(userId: userId),
      child: Consumer<BossChatController>(
        builder: (context, controller, _) {
          // Auto-scroll when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context, controller),
                      const SizedBox(height: 20),
                      
                      // Main Content
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Show sidebar only on tablets/desktop
                            final showSidebar = constraints.maxWidth > 1024;
                            
                            if (showSidebar) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sidebar
                                  SizedBox(
                                    width: 300,
                                    child: _buildSidebar(controller),
                                  ),
                                  const SizedBox(width: 20),
                                  
                                  // Chat Area
                                  Expanded(
                                    child: _buildChatArea(controller),
                                  ),
                                ],
                              );
                            } else {
                              // Mobile: Only chat area
                              return _buildChatArea(controller);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BossChatController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🍽️ Boss Food Ordering',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563eb),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'AI-Powered Food Assistant for Cairo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
          
          // Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: controller.isConnected
                        ? const Color(0xFF10b981)
                        : const Color(0xFFef4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  controller.connectionStatus,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
          ),
          
          // Back button
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: const Color(0xFF64748b),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BossChatController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            QuickActionsWidget(
              onQuickMessage: (msg) => _sendQuickMessage(controller, msg),
            ),
            const SizedBox(height: 30),
            
            // Stats
            StatsWidget(
              messageCount: controller.messageCount,
              cartCount: controller.cartCount,
              cartTotal: controller.cartTotal,
            ),
            const SizedBox(height: 30),
            
            // Tips
            const TipsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea(BossChatController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(
                  message: controller.messages[index],
                );
              },
            ),
          ),
          
          // Input Area
          _buildInputArea(controller),
        ],
      ),
    );
  }

  Widget _buildInputArea(BossChatController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFf8fafc),
        border: Border(
          top: BorderSide(color: Color(0xFFe2e8f0)),
        ),
      ),
      child: Column(
        children: [
          // Input field and send button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about food... (e.g., \'Show me seafood dishes\')',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748b),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFe2e8f0),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFe2e8f0),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563eb),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(controller),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: const Color(0xFF2563eb),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: controller.isLoading
                      ? null
                      : () => _sendMessage(controller),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: controller.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '📤',
                            style: TextStyle(fontSize: 20),
                          ),
                  ),
                ),
              ),
            ],
          ),
          
          // Hint badges
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHintBadge(
                'Categories',
                'What categories do you have?',
                controller,
              ),
              _buildHintBadge(
                'Budget',
                'Show me meals under 50 EGP',
                controller,
              ),
              _buildHintBadge(
                'Allergies',
                'I have allergies to dairy',
                controller,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHintBadge(
    String label,
    String message,
    BossChatController controller,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _sendQuickMessage(controller, message),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFe2e8f0)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1e293b),
            ),
          ),
        ),
      ),
    );
  }
}
