import 'package:flutter/material.dart';
import 'main.dart';

void main() {
  runApp(const BloomieChatApp());
}

class BloomieChatApp extends StatelessWidget {
  const BloomieChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatBotPage(),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    
    // Load initial messages or add default welcome message
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      _messages.addAll(widget.initialMessages!);
    } else {
      _messages.add(ChatMessage(
        text: "How may I help you today?",
        isBot: true,
      ));
    }
    
    _controller.addListener(() {
      setState(() {
        isTyping = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: _controller.text,
          isBot: false,
        ));
      });
      print('Sent: ${_controller.text}');
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E3),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatHistoryPage()),
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
              child: ListView.builder(
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
                  // Input field section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                                print("Voice recording activated");
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsPage()));
                  }),
                  _buildChatBottomNavIcon('assets/images/home.png', const Color(0xFFFFE066), () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePageQuestionnaireReminder()),
                    );
                  }),
                  _buildChatBottomNavIcon('assets/images/drbloom.png', const Color(0xFF98E4D6), () {
                    // Already in chat, maybe scroll to top or show menu
                    print("Already in Dr Bloom chat");
                  }),
                  _buildChatBottomNavIcon('assets/images/profile.png', const Color(0xFFFFB366), () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
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
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
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
                    : const Color(0xFFFFB366),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
            // User avatar - using Baby Amy's photo
            CircleAvatar(
              backgroundColor: const Color(0xFF98E4D6),
              radius: 20,
              backgroundImage: AssetImage('assets/images/babyamy.jpg'),
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
                print("Camera selected");
              },
            ),
            _buildAttachmentOption(
              Icons.photo,
              "Photos",
              Colors.green[300]!,
              () {
                Navigator.pop(context);
                print("Photos selected");
              },
            ),
            _buildAttachmentOption(
              Icons.insert_drive_file,
              "Files",
              Colors.blue[300]!,
              () {
                Navigator.pop(context);
                print("Files selected");
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
              color: color.withValues(alpha: 0.2),
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
}

class ChatMessage {
  final String text;
  final bool isBot;

  ChatMessage({required this.text, required this.isBot});
}