import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/question_1_slider.dart';
import 'screens/dynamic_questionnaire_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth_wrapper.dart';
import 'insights_summary.dart';
import 'providers/app_state_provider.dart';
import 'providers/questionnaire_provider.dart';
import 'providers/auth_provider.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'core/utils/logger.dart';
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await StorageService.init();
  ApiService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => QuestionnaireProvider()),
      ],
      child: const FigmaToCodeApp(),
    ),
  );
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFFAF4EA),
      ),
      home: const AuthWrapper(),
    );
  }
}

class HomePageQuestionnaireReminder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF4EA),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header section with logo and profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Stack(
                children: [
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
                  // Profile icon positioned on the right - aligned with logo and using Baby Amy's photo - NOW INTERACTIVE
                  Positioned(
                    right: 0,
                    top: 3,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilePage()),
                        );
                      },
                      child: ClipOval(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/babyamy.jpg',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // Welcome text - moved down to center between logo and card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome Back, ',
                        style: TextStyle(
                          color: Color(0xFF717070),
                          fontSize: 33,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      TextSpan(
                        text: 'Amy',
                        style: TextStyle(
                          color: Color(0xFF717070),
                          fontSize: 33,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      TextSpan(
                        text: '!',
                        style: TextStyle(
                          color: Color(0xFF717070),
                          fontSize: 33,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Horizontally scrollable cards section - NOW ALL INTERACTIVE WITH FIXED SHADOWS
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), // Fixed padding for shadows
                child: Row(
                  children: [
                    // Bi-weekly Questionnaire Card - NOW DYNAMIC AND INTERACTIVE
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DynamicQuestionnaireScreen(
                              childId: 'amy_001', // TODO: Use actual child ID from user state
                            ),
                          ),
                        );
                        AppLogger.info('Starting dynamic bi-weekly questionnaire');
                      },
                      child: _buildQuestionnaireCard(),
                    ),
                    
                    const SizedBox(width: 15),
                    
                    // Today's Parenting Focus Card - NOW INTERACTIVE
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ParentingFocusPage()),
                        );
                      },
                      child: _buildParentingFocusCard(),
                    ),
                    
                    const SizedBox(width: 15),
                    
                    // Additional card - NOW INTERACTIVE
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdditionalContentPage()),
                        );
                      },
                      child: _buildAdditionalCard(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section with Statistics, Records, Dr Bloom - NOW ALL INTERACTIVE
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Statistics Card - NOW INTERACTIVE
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showInsightsSummary(context);
                          },
                          child: _buildStatisticsCard(),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Right column
                      Expanded(
                        child: Column(
                          children: [
                            // Records Card - NOW INTERACTIVE
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RecordsPage()),
                                );
                              },
                              child: _buildBottomCard(
                                'Records',
                                'Upload any relevant documents',
                                const Color(0xFFFDE5BE),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Dr Bloom Card - NOW LINKS TO ACTUAL CHAT
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ChatBotPage()),
                                );
                              },
                              child: _buildBottomCard(
                                'Dr Bloom',
                                'Chat with Dr Bloom for any inquiries',
                                const Color(0xFFFDE5BE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom navigation with PNG icons - NOW ALL INTERACTIVE
            Container(
              height: 90,
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
                  _buildBottomNavIcon('assets/images/stats.png', const Color(0xFF98E4D6), () {
                    showInsightsSummary(context);
                  }),
                  _buildBottomNavIcon('assets/images/home.png', const Color(0xFFFFE066), () {
                    // Already on home page, maybe scroll to top or refresh
                    AppLogger.info('Already on home page');
                  }),
                  _buildBottomNavIcon('assets/images/drbloom.png', const Color(0xFF98E4D6), () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatBotPage()));
                  }),
                  _buildBottomNavIcon('assets/images/profile.png', const Color(0xFFFFB366), () {
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

  Widget _buildQuestionnaireCard() {
    return Container(
      width: 380,
      height: 240,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE1DD),
        borderRadius: BorderRadius.all(Radius.circular(21)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          const Positioned(
            left: 31,
            top: 20,
            child: Text(
              'Dynamic Check-in',
              style: TextStyle(
                color: Color(0xFF717070),
                fontSize: 25,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const Positioned(
            left: 31,
            top: 100,
            right: 110,
            child: Center(
              child: Text(
                'Answer these questions to track your child\'s development',
                style: TextStyle(
                  color: Color(0xFF717070),
                  fontSize: 18,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w300,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          // Decorative icon - centered vertically on the right
          Positioned(
            right: 30,
            top: 80,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.assignment,
                size: 45,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentingFocusCard() {
    return Container(
      width: 380,
      height: 240,
      decoration: const BoxDecoration(
        color: Color(0xFFFFEFD3),
        borderRadius: BorderRadius.all(Radius.circular(21)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 31,
            top: 20,
            child: Text(
              'Today\'s parenting focus',
              style: TextStyle(
                color: Color(0xFF717070),
                fontSize: 25,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const Positioned(
            left: 31,
            top: 80,
            child: SizedBox(
              width: 200,
              child: Text(
                'Playtime to improve motor skills',
                style: TextStyle(
                  color: Color(0xFF717070),
                  fontSize: 18,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w300,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          // Decorative icon - centered vertically on the right
          Positioned(
            right: 30,
            top: 80,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.yellow[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.child_care,
                size: 45,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalCard() {
    return Container(
      width: 380,
      height: 240,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E8),
        borderRadius: BorderRadius.all(Radius.circular(21)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Additional Content',
          style: TextStyle(
            color: Color(0xFF717070),
            fontSize: 25,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard(String title, String description, Color color, {bool isLarge = false}) {
    return Container(
      height: isLarge ? 266 : 129,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF717070),
              fontSize: 18,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF717070),
              fontSize: 13,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w300,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF717070),
              decorationThickness: 1.0,
              decorationStyle: TextDecorationStyle.solid,
            ),
            textAlign: TextAlign.left,
            maxLines: isLarge ? 6 : 3,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      height: 266,
      decoration: BoxDecoration(
        color: const Color(0xFFFDE5BE),
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: const TextStyle(
              color: Color(0xFF717070),
              fontSize: 18,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'View Insight Summary',
                  style: TextStyle(
                    color: Color(0xFF717070),
                    fontSize: 13,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w300,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF717070),
                    decorationThickness: 1.0,
                  ),
                ),
                TextSpan(
                  text: '\n\n',
                  style: TextStyle(
                    color: Color(0xFF717070),
                    fontSize: 13,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w300,
                    decoration: TextDecoration.none,
                  ),
                ),
                TextSpan(
                  text: 'View Genetic Report',
                  style: TextStyle(
                    color: Color(0xFF717070),
                    fontSize: 13,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w300,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF717070),
                    decorationThickness: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated method to display larger PNG images without any background or border - NOW INTERACTIVE
  Widget _buildBottomNavIcon(String imagePath, Color color, VoidCallback onTap) {
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
}

// CHAT HISTORY MODEL AND STORAGE
class ChatHistory {
  static List<Map<String, dynamic>> _chatSessions = [
    {
      'id': '1',
      'title': 'Development Questions',
      'lastMessage': 'Thank you for your advice!',
      'timestamp': DateTime.now().subtract(Duration(hours: 2)),
      'messages': [
        {'text': 'How may I help you today?', 'isBot': true},
        {'text': 'My child is 2 years old, when should they start talking?', 'isBot': false},
        {'text': 'Most children start saying their first words around 12-18 months...', 'isBot': true},
        {'text': 'Thank you for your advice!', 'isBot': false},
      ]
    },
    {
      'id': '2',
      'title': 'Sleep Schedule',
      'lastMessage': 'What about nap times?',
      'timestamp': DateTime.now().subtract(Duration(days: 1)),
      'messages': [
        {'text': 'How may I help you today?', 'isBot': true},
        {'text': 'Help with sleep schedule for toddler', 'isBot': false},
        {'text': 'A consistent bedtime routine is very important...', 'isBot': true},
        {'text': 'What about nap times?', 'isBot': false},
      ]
    },
    {
      'id': '3',
      'title': 'Nutrition Advice',
      'lastMessage': 'Any specific food recommendations?',
      'timestamp': DateTime.now().subtract(Duration(days: 3)),
      'messages': [
        {'text': 'How may I help you today?', 'isBot': true},
        {'text': 'What foods are best for my 18-month-old?', 'isBot': false},
        {'text': 'At 18 months, focus on variety and nutrients...', 'isBot': true},
        {'text': 'Any specific food recommendations?', 'isBot': false},
      ]
    },
  ];

  static List<Map<String, dynamic>> getChatSessions() => _chatSessions;
  
  static void addChatSession(String title, List<ChatMessage> messages) {
    _chatSessions.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'lastMessage': messages.isNotEmpty ? messages.last.text : '',
      'timestamp': DateTime.now(),
      'messages': messages.map((msg) => {'text': msg.text, 'isBot': msg.isBot}).toList(),
    });
  }
}

// CHAT HISTORY PAGE
class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final chatSessions = ChatHistory.getChatSessions();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5E3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chat History',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            color: Color(0xFF717070),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat history list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatSessions.length,
              itemBuilder: (context, index) {
                final session = chatSessions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.withOpacity(Colors.black, 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      session['title'],
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          session['lastMessage'],
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(session['timestamp']),
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatBotPage(
                            initialMessages: (session['messages'] as List)
                                .map((msg) => ChatMessage(
                                      text: msg['text'],
                                      isBot: msg['isBot'],
                                    ))
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // Bottom navigation with interactive PNG icons - SAME AS HOMEPAGE
          Container(
            height: 90,
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
                _buildChatHistoryBottomNavIcon('assets/images/stats.png', const Color(0xFF98E4D6), () {
                  showInsightsSummary(context);
                }),
                _buildChatHistoryBottomNavIcon('assets/images/home.png', const Color(0xFFFFE066), () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePageQuestionnaireReminder()),
                  );
                }),
                _buildChatHistoryBottomNavIcon('assets/images/drbloom.png', const Color(0xFF98E4D6), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatBotPage()),
                  );
                }),
                _buildChatHistoryBottomNavIcon('assets/images/profile.png', const Color(0xFFFFB366), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method for bottom navigation icons in ChatHistoryPage
  Widget _buildChatHistoryBottomNavIcon(String imagePath, Color color, VoidCallback onTap) {
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }
}

// UPDATED CHAT PAGE
class ChatBotPage extends StatefulWidget {
  final List<ChatMessage>? initialMessages;
  
  const ChatBotPage({Key? key, this.initialMessages}) : super(key: key);

  @override
  _ChatBotPageState createState() => _ChatBotPageState();
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
      AppLogger.info('Message sent: ${_controller.text}');
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
            // Top bar with menu and centered bloomie logo (removed back button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                children: [
                  // Menu icon (3 lines) positioned on the left - NOW INTERACTIVE
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
                          showInsightsSummary(context);
                        }),
                        _buildChatBottomNavIcon('assets/images/home.png', const Color(0xFFFFE066), () {
                          Navigator.pop(context); // Go back to home
                        }),
                        _buildChatBottomNavIcon('assets/images/drbloom.png', const Color(0xFF98E4D6), () {
                          // Already in chat, maybe scroll to top or show menu
                          AppLogger.info('Already in Dr Bloom chat');
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
                AppLogger.info('Camera selected');
                // Placeholder - add actual camera functionality later
                setState(() {
                  _messages.add(ChatMessage(
                    text: "📷 Camera feature coming soon!",
                    isBot: false,
                  ));
                });
              },
            ),
            _buildAttachmentOption(
              Icons.photo,
              "Photos",
              Colors.green[300]!,
              () {
                Navigator.pop(context);
                AppLogger.info('Photos selected');
                // Placeholder - add actual gallery functionality later
                setState(() {
                  _messages.add(ChatMessage(
                    text: "📷 Photo gallery feature coming soon!",
                    isBot: false,
                  ));
                });
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
}

class ChatMessage {
  final String text;
  final bool isBot;

  ChatMessage({required this.text, required this.isBot});
}

// PLACEHOLDER PAGES - Replace these with your actual pages later

class QuestionnairePage extends StatelessWidget {
  const QuestionnairePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Question1Slider();
  }
}

class ParentingFocusPage extends StatelessWidget {
  const ParentingFocusPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Parenting Focus'),
        backgroundColor: Color(0xFFFFEFD3),
      ),
      backgroundColor: Color(0xFFFAF4EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Parenting Focus Page',
              style: TextStyle(fontSize: 24, fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Today\'s parenting tips and activities',
              style: TextStyle(fontSize: 16, fontFamily: 'Fredoka'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdditionalContentPage extends StatelessWidget {
  const AdditionalContentPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Content'),
        backgroundColor: Color(0xFFE8F5E8),
      ),
      backgroundColor: Color(0xFFFAF4EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Additional Content Page',
              style: TextStyle(fontSize: 24, fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'More features coming soon!',
              style: TextStyle(fontSize: 16, fontFamily: 'Fredoka'),
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
        backgroundColor: Color(0xFFFDE5BE),
      ),
      backgroundColor: Color(0xFFFAF4EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Color(0xFF98E4D6)),
            SizedBox(height: 20),
            Text(
              'Statistics Page',
              style: TextStyle(fontSize: 24, fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View insights and genetic reports',
              style: TextStyle(fontSize: 16, fontFamily: 'Fredoka'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Records'),
        backgroundColor: Color(0xFFFDE5BE),
      ),
      backgroundColor: Color(0xFFFAF4EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 80, color: Colors.brown),
            SizedBox(height: 20),
            Text(
              'Records Page',
              style: TextStyle(fontSize: 24, fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Upload and manage documents',
              style: TextStyle(fontSize: 16, fontFamily: 'Fredoka'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFFFFB366),
      ),
      backgroundColor: Color(0xFFFAF4EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/babyamy.jpg'),
            ),
            SizedBox(height: 20),
            Text(
              'Amy\'s Profile',
              style: TextStyle(fontSize: 24, fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage profile settings',
              style: TextStyle(fontSize: 16, fontFamily: 'Fredoka'),
            ),
          ],
        ),
      ),
    );
  }
}