import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class ChatPageUpdated extends StatefulWidget {
  const ChatPageUpdated({super.key});

  @override
  State<ChatPageUpdated> createState() => _ChatPageUpdatedState();
}

class _ChatPageUpdatedState extends State<ChatPageUpdated> {
  final _messageController = TextEditingController();
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.addChatMessage(text, isBot: false);
      _messageController.clear();
      
      // Simulate bot response after delay
      Future.delayed(const Duration(seconds: 1), () {
        provider.addChatMessage(
          "Thanks for your message! I'm Dr. Bloom and I'm here to help.",
          isBot: true,
        );
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dr. Bloom', style: AppTextStyles.h2),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Chat messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = provider.chatMessages[index];
                    return Align(
                      alignment: message.isBot
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: message.isBot
                              ? Colors.grey.shade300
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isBot ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Input field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.withOpacity(Colors.black, 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (text) {
                          provider.setTyping(text.isNotEmpty);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: provider.isTyping ? _sendMessage : null,
                      icon: Icon(
                        Icons.send,
                        color: provider.isTyping
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}