import 'package:flutter/material.dart';
import 'main.dart';
import 'chatbot.dart' as chatbot;

class BloomieHomePage extends StatelessWidget {
  const BloomieHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      body: SafeArea(
        child: Column(
          children: [
            // Header section with logo and profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Stack(
                children: [
                  // Centered Bloomie logo
                  Center(
                    child: Container(
                      width: 200, 
                      height: 50,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/bloomie_icon.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Profile icon positioned on the right
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => ProfilePage()),
                        // );
                      },
                      child: ClipOval(
                        child: Container(
                          width: 50,
                          height: 50,
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
                              width: 50,
                              height: 50,
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

            const SizedBox(height: 20),

            // Welcome text - centered
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
                          fontSize: 28,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      TextSpan(
                        text: 'Amy',
                        style: TextStyle(
                          color: Color(0xFF717070),
                          fontSize: 28,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      TextSpan(
                        text: '!',
                        style: TextStyle(
                          color: Color(0xFF717070),
                          fontSize: 28,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Horizontal scrolling cards section
            SizedBox(
              height: 180,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Today's parenting focus card
                    GestureDetector(
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => ParentingFocusPage()),
                        // );
                      },
                      child: _buildParentingFocusCard(),
                    ),
                    const SizedBox(width: 15),
                    // Bi-weekly Questionnaire card
                    GestureDetector(
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => QuestionnairePage()),
                        // );
                      },
                      child: _buildQuestionnaireCard(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Bottom cards section - Full space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Statistics Card - takes up more space
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => StatisticsPage()),
                          // );
                        },
                        child: _buildBottomCard(
                          'Statistics',
                          'View Insight Summary\n\nView Genetic Report',
                          const Color(0xFFFDE5BE),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Right column with two stacked cards
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Records Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(builder: (context) => RecordsPage()),
                                // );
                              },
                              child: _buildSmallBottomCard(
                                'Records',
                                'Upload any relevant documents',
                                const Color(0xFFFDE5BE),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Dr Bloom Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(builder: (context) => ChatBotPage()),
                                // );
                              },
                              child: _buildSmallBottomCard(
                                'Dr Bloom',
                                'Chat with Dr Bloom for any inquiries',
                                const Color(0xFFFDE5BE),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bottom navigation
            Container(
              height: 80,
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
                  _buildBottomNavIcon('assets/images/stats.png', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsPage()));
                  }),
                  _buildBottomNavIcon('assets/images/home.png', () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePageQuestionnaireReminder()));
                  }),
                  _buildBottomNavIcon('assets/images/drbloom.png', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => chatbot.ChatBotPage()));
                  }),
                  _buildBottomNavIcon('assets/images/profile.png', () {
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

  Widget _buildParentingFocusCard() {
    return Container(
      width: 300,
      height: 180,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s parenting focus',
            style: TextStyle(
              color: Color(0xFF717070),
              fontSize: 18,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Playtime to improve motor skills',
                  style: TextStyle(
                    color: Color(0xFF717070),
                    fontSize: 16,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              // Baby illustration placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.child_care,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireCard() {
    return Container(
      width: 300,
      height: 180,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bi-weekly Questionnaire',
            style: TextStyle(
              color: Color(0xFF717070),
              fontSize: 18,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Answer these questions to track your child\'s development',
                  style: TextStyle(
                    color: Color(0xFF717070),
                    fontSize: 16,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              // Questionnaire icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.assignment,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(String title, String description, Color color) {
    return Container(
      width: double.infinity,
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
              fontSize: 16,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF717070),
              fontSize: 12,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w300,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF717070),
              decorationThickness: 1.0,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBottomCard(String title, String description, Color color) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF717070),
              fontSize: 14,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF717070),
              fontSize: 10,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w300,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF717070),
              decorationThickness: 1.0,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavIcon(String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          imagePath,
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}