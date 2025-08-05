import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/auth_models.dart';
import 'dynamic_questionnaire_screen.dart';
import 'upload_genetic_report_screen.dart';
import 'child_selector_screen.dart';
import 'traits_screen.dart';
import 'auth/login_screen.dart';
import '../chatbot.dart';
import 'statistics_screen.dart';

class SingleChildDashboard extends StatelessWidget {
  const SingleChildDashboard({super.key});

  void _startCheckIn(BuildContext context, String childId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicQuestionnaireScreen(childId: childId),
      ),
    );
  }

  void _openChildSelector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChildSelectorScreen(),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final selectedChild = authProvider.selectedChild;
            final user = authProvider.currentUser;
            
            if (user == null) {
              return const Center(child: Text('No user data available'));
            }

            // If no child selected and children available, show child selector
            if (selectedChild == null) {
              if (authProvider.children.isEmpty) {
                return _buildNoChildrenView(context);
              } else {
                // Auto-select first child if none selected
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authProvider.selectChild(authProvider.children.first);
                });
                return const Center(child: CircularProgressIndicator());
              }
            }

            return _buildSingleChildView(context, selectedChild, user);
          },
        ),
      ),
    );
  }

  Widget _buildNoChildrenView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Bloomie! 👶',
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first child to get started with personalized recommendations and tracking.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadGeneticReportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChildView(BuildContext context, Child selectedChild, User user) {
    return Column(
      children: [
        // Header section with logo and profile (like original design)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Stack(
            children: [
              // Centered Bloomie logo
              Center(
                child: Container(
                  width: 239, 
                  height: 59,
                  decoration: const BoxDecoration(
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

        const SizedBox(height: 35),

        // Welcome text for selected child (like original design)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
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
                    text: selectedChild.name,
                    style: const TextStyle(
                      color: Color(0xFF717070),
                      fontSize: 33,
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const TextSpan(
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

        // Scrollable cards section (like original design)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                // Questionnaire Card
                GestureDetector(
                  onTap: () => _startCheckIn(context, selectedChild.id),
                  child: _buildQuestionnaireCard(),
                ),
                
                const SizedBox(width: 15),
                
                // Additional cards can be added here
                _buildParentingFocusCard(),
                
                const SizedBox(width: 15),
                
                _buildAdditionalCard(),
              ],
            ),
          ),
        ),

        // Bottom section with Statistics, Records, Dr Bloom (like original design)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Statistics Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsScreen(),
                          ),
                        );
                      },
                      child: _buildStatisticsCard(),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Right column
                  Expanded(
                    child: Column(
                      children: [
                        // View Traits Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TraitsScreen(childId: selectedChild.id),
                              ),
                            );
                          },
                          child: _buildBottomCard(
                            'Genetic Profile',
                            'See genetic traits analysis',
                            const Color(0xFFE8F5E8),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Upload Report Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UploadGeneticReportScreen(),
                              ),
                            );
                          },
                          child: _buildBottomCard(
                            'Upload Report',
                            'Add genetic report for this child',
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

        // Bottom navigation (like original design)
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
              _buildBottomNavIcon('assets/images/stats.png', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              }),
              _buildBottomNavIcon('assets/images/home.png', () {
                // Already on home
              }),
              _buildBottomNavIcon('assets/images/drbloom.png', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatBotPage(),
                  ),
                );
              }),
              _buildBottomNavIcon('assets/images/profile.png', () => _openChildSelector(context)),
            ],
          ),
        ),
      ],
    );
  }

  // Card building methods (from original design)
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
          const Positioned(
            left: 31,
            top: 20,
            child: Text(
              'Weekly Check-in',
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
                'Answer questions to track your child\'s development',
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
        color: Colors.transparent,
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

  Widget _buildBottomCard(String title, String description, Color color) {
    return Container(
      height: 129,
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
            maxLines: 3,
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View Recommendation History',
            style: TextStyle(
              color: Color(0xFF717070),
              fontSize: 18,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View development progress and insights for this child',
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
    );
  }

  Widget _buildBottomNavIcon(String imagePath, VoidCallback onTap) {
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