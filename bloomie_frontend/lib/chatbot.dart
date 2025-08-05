import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/logger.dart';
import 'core/constants/app_colors.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'main.dart';

class ChatBotPage extends StatefulWidget {
  final List<ChatMessage>? initialMessages;
  
  const ChatBotPage({super.key, this.initialMessages});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool isTyping = false;
  String? _sessionId;
  bool _isLoading = true;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    
    _controller.addListener(() {
      setState(() {
        isTyping = _controller.text.trim().isNotEmpty;
      });
    });
    
    // Start Dr. Bloom session
    _initializeDrBloomSession();
  }
  
  Future<void> _initializeDrBloomSession() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final selectedChild = authProvider.selectedChild;
      
      if (selectedChild == null) {
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            text: "Please select a child first to start a consultation.",
            isBot: true,
          ));
        });
        return;
      }
      
      AppLogger.info('Starting Dr. Bloom session for child: ${selectedChild.id}');
      
      // Start Dr. Bloom session
      final response = await ApiService.startDrBloomSession(selectedChild.id);
      
      setState(() {
        _sessionId = response['session_id'];
        _isLoading = false;
        _messages.add(ChatMessage(
          text: response['initial_response'] ?? "Hello! I'm Dr. Bloom, your AI pediatric consultant. What would you like to discuss about ${selectedChild.name} today?",
          isBot: true,
        ));
      });
      
      AppLogger.info('Dr. Bloom session started with ID: $_sessionId');
      
    } catch (e) {
      AppLogger.error('Failed to start Dr. Bloom session', error: e);
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: "Sorry, I couldn't start the consultation. Please try again later.",
          isBot: true,
        ));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty && _sessionId != null) {
      final messageText = _controller.text.trim();
      
      // Add user message to the chat
      setState(() {
        _messages.add(ChatMessage(
          text: messageText,
          isBot: false,
        ));
      });
      
      _controller.clear();
      AppLogger.info('Sending message to session $_sessionId: $messageText');
      
      // Show typing indicator
      setState(() {
        _messages.add(ChatMessage(
          text: "Dr. Bloom is typing...",
          isBot: true,
        ));
      });
      
      try {
        // Call Dr. Bloom API with session ID
        final response = await ApiService.sendDrBloomMessage(_sessionId!, messageText);
        
        // Remove typing indicator
        setState(() {
          _messages.removeLast();
        });
        
        // Add bot response
        if (response['agent_response'] != null) {
          setState(() {
            _messages.add(ChatMessage(
              text: response['agent_response'],
              isBot: true,
            ));
          });
          AppLogger.info('Received response from Dr. Bloom');
        } else {
          throw Exception('No response from server');
        }
        
      } catch (e) {
        AppLogger.error('Failed to send message', error: e);
        
        // Remove typing indicator
        setState(() {
          _messages.removeLast();
        });
        
        // Show error message
        setState(() {
          _messages.add(ChatMessage(
            text: "Sorry, I couldn't process your message. Please try again later.",
            isBot: true,
          ));
        });
      }
    } else if (_sessionId == null) {
      AppLogger.error('No active Dr. Bloom session');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active consultation. Please go back and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _completeSession() async {
    if (_sessionId == null || _isCompleting) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final selectedChild = authProvider.selectedChild;
    
    if (selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No child selected for this consultation.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isCompleting = true;
    });
    
    try {
      AppLogger.info('Completing Dr. Bloom session: $_sessionId');
      
      final response = await ApiService.completeDrBloomSession(selectedChild.id, _sessionId!);
      
      AppLogger.info('Session completed successfully');
      
      // Show success dialog with summary
      if (mounted) {
        _showCompletionDialog(response);
      }
      
    } catch (e) {
      AppLogger.error('Failed to complete session', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete consultation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCompleting = false;
      });
    }
  }
  
  void _showCompletionDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '✅ Consultation Complete',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your consultation with Dr. Bloom has been completed and logged.',
                style: TextStyle(fontFamily: 'Fredoka'),
              ),
              const SizedBox(height: 16),
              if (response['conversation_deleted'] == true) ...[
                const Text(
                  '💬 Conversation has been logged and deleted for privacy.',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'You can view the consultation summary in your child\'s records.',
                style: TextStyle(fontFamily: 'Fredoka'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            },
            child: const Text(
              'Back to Dashboard',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with menu and bloomie logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                children: [
                  // Menu icon (3 lines) positioned on the left - INTERACTIVE
                  Positioned(
                    left: 0,
                    top: 16,
                    child: GestureDetector(
                      onTap: () {
                        // Chat history not implemented yet
                        AppLogger.info('Chat history clicked');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat history coming soon!')),
                        );
                      },
                      child: const Icon(Icons.menu, color: Colors.grey, size: 24),
                    ),
                  ),
                  // Centered Bloomie logo - consistent sizing
                  Center(
                    child: Container(
                      width: 239,
                      height: 59,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/bloomie_icon.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chat messages area
            Expanded(
              child: _isLoading 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Starting Dr. Bloom consultation...',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
            ),

            // Input bar - UPDATED to cover fully to bottom with no gaps
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Complete Consultation Button (only show if session is active)
                  if (_sessionId != null && !_isLoading) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCompleting ? null : _completeSession,
                          icon: _isCompleting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle, size: 20),
                          label: Text(
                            _isCompleting ? 'Completing...' : 'Complete Consultation',
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Input field section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        // Plus button with attachment menu
                        GestureDetector(
                          onTap: () {
                            _showAttachmentMenu();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.add,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Text input field
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (value) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Ask anything...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontFamily: 'Fredoka',
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Send button (when typing) and mic button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isTyping)
                              GestureDetector(
                                onTap: _sendMessage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.send,
                                    color: Color(0xFF727272),
                                    size: 24,
                                  ),
                                ),
                              ),
                            
                            // Mic button
                            GestureDetector(
                              onTap: () {
                                AppLogger.info('Voice recording activated');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.mic,
                                  color: Color(0xFF727272),
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom navigation bar - EXTENDS TO BOTTOM WITHOUT GAPS
            Container(
              height: 90,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4E3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, -4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChatBottomNavIcon('assets/images/stats.png', const Color(0xFF98E4D6), () {
                    // Statistics - not implemented yet
                    AppLogger.info('Statistics clicked');
                  }),
                  _buildChatBottomNavIcon('assets/images/home.png', const Color(0xFFFFE066), () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Dashboard()),
                    );
                  }),
                  _buildChatBottomNavIcon('assets/images/drbloom.png', const Color(0xFF98E4D6), () {
                    // Already in chat, maybe scroll to top or show menu
                    AppLogger.info('Already in Dr Bloom chat');
                  }),
                  _buildChatBottomNavIcon('assets/images/profile.png', const Color(0xFFFFB366), () {
                    // Profile - opens child selector
                    Navigator.pop(context); // Go back to dashboard which has profile functionality
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            // Bot avatar
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 20,
              child: Image.asset(
                'assets/images/drbloom.png',
                width: 18,
                height: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: message.isBot 
                    ? Colors.grey[300]
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.withOpacity(Colors.black, 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isBot ? Colors.grey[700] : Colors.white,
                  fontSize: 16,
                  fontFamily: 'Fredoka',
                ),
              ),
            ),
          ),
          
          if (!message.isBot) ...[
            const SizedBox(width: 10),
            // User avatar - using selected child's photo
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              radius: 20,
              backgroundImage: AssetImage(_getChildProfileImage(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatBottomNavIcon(String imagePath, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          imagePath,
          width: 48,
          height: 48,
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              Icons.camera_alt,
              "Camera",
              Colors.orange[300]!,
              () {
                Navigator.pop(context);
                AppLogger.info('Camera selected');
              },
            ),
            _buildAttachmentOption(
              Icons.photo,
              "Photos",
              Colors.green[300]!,
              () {
                Navigator.pop(context);
                AppLogger.info('Photos selected');
              },
            ),
            _buildAttachmentOption(
              Icons.insert_drive_file,
              "Files",
              Colors.blue[300]!,
              () {
                Navigator.pop(context);
                AppLogger.info('Files selected');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.withOpacity(color, 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to get child profile image based on selected child
  String _getChildProfileImage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childName = authProvider.selectedChild?.name;
    
    if (childName == null) return 'assets/images/default_child.png';
    
    // Hard-coded mapping for now - can be extended later
    switch (childName.toLowerCase()) {
      case 'amy':
        return 'assets/images/babyamy.jpg';
      case 'emma':
        return 'assets/images/babyemma.jpg';
      case 'lucas':
        return 'assets/images/babylucas.jpg';
      case 'sophia':
        return 'assets/images/babysophia.jpg';
      case 'noah':
        return 'assets/images/babynoah.jpg';
      case 'olivia':
        return 'assets/images/babyolivia.jpg';
      case 'nigolas':
        return 'assets/images/babyamy.jpg'; // Using Amy's image for Nigolas for now
      default:
        return 'assets/images/babyamy.jpg'; // Use Amy's image as default
    }
  }
}

class ChatMessage {
  final String text;
  final bool isBot;

  ChatMessage({required this.text, required this.isBot});
}