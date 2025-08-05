import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../core/utils/logger.dart';
import '../providers/auth_provider.dart';
import '../core/widgets/persistent_bottom_nav.dart';

class DrBloomChatScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const DrBloomChatScreen({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);

  @override
  _DrBloomChatScreenState createState() => _DrBloomChatScreenState();
}

class _DrBloomChatScreenState extends State<DrBloomChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isLoading = false;
  String? _sessionId;
  bool _sessionCompleted = false;

  @override
  void initState() {
    super.initState();
    _startDrBloomSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startDrBloomSession() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.startDrBloomSession(
        widget.childId,
        initialConcern: "I'd like to consult with Dr. Bloom about my child.",
      );

      setState(() {
        _sessionId = response['session_id'];
        _messages.add(ChatMessage(
          text: response['initial_response'] ?? "Hello! I'm Dr. Bloom, your AI pediatric consultant. What would you like to discuss about your child today?",
          isBot: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      AppLogger.error('Failed to start Dr. Bloom session: $e');
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: "Sorry, I'm having trouble connecting right now. Please try again later.",
          isBot: true,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _sessionId == null || _sessionCompleted) return;

    final messageText = _controller.text.trim();
    _controller.clear();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isBot: false,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await ApiService.sendDrBloomMessage(_sessionId!, messageText);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response['agent_response'] ?? 'I received your message.',
          isBot: true,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    } catch (e) {
      AppLogger.error('Failed to send Dr. Bloom message: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: "I'm sorry, I didn't receive that message clearly. Could you please try again?",
          isBot: true,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _completeDrBloomSession() async {
    if (_sessionId == null || _sessionCompleted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.completeDrBloomSession(widget.childId, _sessionId!);
      
      setState(() {
        _sessionCompleted = true;
        _isLoading = false;
      });

      // Show completion dialog with medical log info
      _showCompletionDialog(response);
    } catch (e) {
      AppLogger.error('Failed to complete Dr. Bloom session: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete consultation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCompletionDialog(Map<String, dynamic> response) {
    final medicalLog = response['medical_log'] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text(
                'Consultation Complete',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (medicalLog != null) ...[
                  const Text(
                    '📋 Medical Log Created',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (medicalLog['emergency_warning'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        border: Border.all(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ ${medicalLog['emergency_warning']}',
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  _buildLogSection('🩺 Problem Discussed', medicalLog['problem_discussed']),
                  
                  if (medicalLog['immediate_recommendations'] != null && 
                      (medicalLog['immediate_recommendations'] as List).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '✅ What You Can Do Right Now:',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...(medicalLog['immediate_recommendations'] as List).map((rec) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          '• ${rec ?? 'No recommendation available'}',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 13,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  if (medicalLog['follow_up_questions'] != null && 
                      (medicalLog['follow_up_questions'] as List).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '❓ Questions to Ask Your Doctor:',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...(medicalLog['follow_up_questions'] as List).map((question) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          '• ${question ?? 'No question specified'}',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 13,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const Text(
                    'No medical topics were detected in this conversation.',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 Tips for Medical Consultations:',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '• Dr. Bloom is designed for medical consultations\n• Discuss symptoms, health concerns, or medical questions\n• For general behavioral advice, use the Weekly Check-in feature',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'This consultation has been saved and can be reviewed in the Immunity & Resilience dashboard.',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: Color(0xFF1976D2),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog only
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogSection(String title, dynamic content) {
    if (content == null) return Container();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.toString(),
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              color: Color(0xFF555555),
            ),
          ),
        ),
      ],
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF4EA),
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: const Text(
          '🩺 Dr. Bloom Consultation',
          style: TextStyle(
            color: Color(0xFF717070),
            fontSize: 18,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_sessionId != null && !_sessionCompleted)
            TextButton(
              onPressed: _completeDrBloomSession,
              child: const Text(
                'Complete',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bloomie_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Starting Dr. Bloom session...',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 16,
                              color: Color(0xFF717070),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isTyping) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
            ),

            // Input area
            if (!_sessionCompleted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false, // Don't add safe area to bottom
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Describe your concern...',
                            hintStyle: const TextStyle(
                              fontFamily: 'Fredoka',
                              color: Color(0xFF999999),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                          ),
                          maxLines: null,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Persistent bottom navigation
            PersistentBottomNav(
              currentChildId: widget.childId,
              currentChildName: widget.childName,
              selectedIndex: 0, // Dr. Bloom is selected
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF4CAF50),
              radius: 18,
              child: const Text(
                '🩺',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isBot ? Colors.white : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(16),
                border: message.isBot ? Border.all(color: const Color(0xFFE1E5E9)) : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  color: message.isBot ? const Color(0xFF333333) : Colors.white,
                ),
              ),
            ),
          ),
          
          if (!message.isBot) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF98E4D6),
              radius: 18,
              backgroundImage: AssetImage(_getChildProfileImage()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4CAF50),
            radius: 18,
            child: const Text(
              '🩺',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E5E9)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Dr. Bloom is typing...',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to get child profile image based on selected child
  String _getChildProfileImage() {
    final selectedChild = context.read<AuthProvider>().selectedChild;
    final childName = selectedChild?.name;
    
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
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}