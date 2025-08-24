import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dynamic_questionnaire_screen.dart';
import 'screens/immunity_dashboard_screen.dart';
import 'screens/growth_milestones_screen.dart';
import 'screens/dr_bloom_chat_screen.dart';
import 'screens/latest_recommendations_detail_screen.dart';
import 'screens/traits_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/child_selector_screen.dart';
import 'screens/profile_page.dart';
import 'screens/auth_wrapper.dart';
import 'providers/app_state_provider.dart';
import 'providers/questionnaire_provider.dart';
import 'providers/auth_provider.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'core/constants/app_colors.dart';
import 'core/widgets/persistent_bottom_nav.dart';
import 'core/utils/no_animation_route.dart';


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
      child: const BloomieApp(),
    ),
  );
}

class BloomieApp extends StatelessWidget {
  const BloomieApp({super.key});

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

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Simple approach - cache the result with timestamps
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool _shouldFetchData(String childId) {
    final timestamp = _cacheTimestamps[childId];
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp) > _cacheExpiry;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final selectedChild = authProvider.selectedChild;
        
        // If no child is selected, show empty state instead of making API calls
        if (selectedChild == null) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bloomie_background2.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No child selected',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please select or add a child to continue',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: PersistentBottomNav(
              currentChildId: 'no_child',
              currentChildName: 'No Child',
              selectedIndex: 1,
            ),
          );
        }
        
        final childId = selectedChild.id;
        final childName = selectedChild.name;
        
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              // Clear cache and refresh
              _cache.clear();
              _cacheTimestamps.clear();
              await authProvider.forceRefresh();
            },
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bloomie_background2.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
              children: [
                // Main static content
                Expanded(
                  child: SafeArea(
                    bottom: false, // Don't add safe area to bottom
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(context, childName),
                          const SizedBox(height: 20),
                          _buildCarousel(context, childId, childName),
                          _buildGridSection(context, childId, childName),
                          const SizedBox(height: 20), // Extra padding at bottom
                        ],
                      ),
                    ),
                  ),
                ),
                // Persistent bottom navigation
                PersistentBottomNav(
                  currentChildId: childId,
                  currentChildName: childName,
                  selectedIndex: 1, // Home is selected
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  // Carousel card builder
  Widget _buildUniformCarouselCard({
    required String title,
    required String subtitle,
    required String footer,
    required String buttonText,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section (Fixed Height)
          SizedBox(
            height: 20,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: borderColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle Section (Flexible Height for multiline)
          Flexible(
            child: Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 11,
                fontWeight: title.contains('Check-in') ? FontWeight.w600 : FontWeight.normal,
                color: title.contains('Check-in') ? borderColor : const Color(0xFF949494),
              ),
              maxLines: title.contains('Focus') ? null : 1, // Allow unlimited lines for Focus card
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          
          // Footer Section (Expandable)
          Expanded(
            child: Text(
              footer,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: title.contains('Check-in') ? 10 : 9,
                color: title.contains('Check-in') ? const Color(0xFF949494) : const Color(0xFF949494),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Button Section (Fixed Height)
          SizedBox(
            height: 32,
            child: Center(
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: borderColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Grid card builder
  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required String iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Large image taking up most of the space
            Expanded(
              flex: 7, // 70% of space for image
              child: Center(
                child: Image.asset(
                  iconPath,
                  width: 75, // Increased from 60
                  height: 75, // Increased from 60
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Text at bottom
            Expanded(
              flex: 3, // 30% of space for text
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11, // Reduced from 12
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1), // Reduced from 2
                    Flexible(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 9, // Reduced from 10
                          color: Color(0xFF949494),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation button builder
  Widget _buildNavButton({
    required String iconPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Image.asset(
              iconPath,
              width: 32,
              height: 32,
              color: isSelected ? color : AppColors.withOpacity(color, 0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppColors.withOpacity(color, 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to map child names to profile images
  String _getChildProfileImage(String? childName) {
    if (childName == null) return 'assets/images/babyamy.jpg';
    
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
        // Use Amy's image as default fallback
        return 'assets/images/babyamy.jpg';
    }
  }

  // Latest Recommendations Card Builder  
  Widget _buildLatestRecommendationsCard(String childId, String childName, BuildContext context) {
    // Check cache first
    if (_cache.containsKey(childId) && !_shouldFetchData(childId)) {
      return _buildRecommendationsCardContent(_cache[childId]!, childName, context);
    }
    
    // Fetch data if not cached or expired
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getLatestRecommendations(childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildUniformCarouselCard(
            title: '📌 Today\'s Parenting Focus',
            subtitle: 'Loading recommendations...',
            footer: 'Please wait',
            buttonText: 'Loading...',
            backgroundColor: const Color(0xFFFDE6BE),
            borderColor: const Color(0xFFFAB494),
            onPressed: () {},
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildUniformCarouselCard(
            title: '📌 Today\'s Parenting Focus',
            subtitle: 'No recommendations available',
            footer: 'Complete a check-in to get started',
            buttonText: 'Start Check-in',
            backgroundColor: const Color(0xFFFDE6BE),
            borderColor: const Color(0xFFFAB494),
            onPressed: () {
              Navigator.push(
                context,
                NoAnimationPageRoute(
                  builder: (context) => DynamicQuestionnaireScreen(childId: childId),
                ),
              );
            },
          );
        }

        final data = snapshot.data!;
        
        // Cache the result
        _cache[childId] = data;
        _cacheTimestamps[childId] = DateTime.now();
        
        // Debug logging to see what data we got
        print('🔍 Latest recommendations data: ${data.toString()}');
        
        return _buildRecommendationsCardContent(data, childName, context);
      },
    );
  }

  // Latest recommendations widget
  Widget _buildRecommendationsCardContent(Map<String, dynamic> data, String childName, BuildContext context) {
    // Use the actual child ID from AuthProvider context instead of data
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childId = authProvider.selectedChild?.id ?? data['child_id'] as String? ?? 'default_child';
    final recommendations = data['recommendations'] as List<dynamic>? ?? [];
    final lastCheckIn = data['last_check_in'] as String?;
    
    // Debug logging
    print('🔍 Recommendations array: ${recommendations.toString()}');
    print('🔍 Recommendations isEmpty: ${recommendations.isEmpty}');
    final lastCheckInDate = lastCheckIn != null 
        ? DateTime.tryParse(lastCheckIn)?.toLocal().toString().split(' ')[0] ?? 'N/A'
        : 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          NoAnimationPageRoute(
            builder: (context) => LatestRecommendationsDetailScreen(
              childId: childId,
              childName: childName,
            ),
          ),
        );
      },
      child: Container(
        height: 230,
        padding: const EdgeInsets.all(10), // Reduced padding for more space
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFAB494), width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title at the top
            Text(
              '📌 Today\'s Parenting Focus',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18, // Increased font size
                fontWeight: FontWeight.w700,
                color: const Color(0xFF995444),
              ),
            ),
            const SizedBox(height: 10),
            
            // Content area with layered image and recommendations
            Expanded(
              child: Stack(
                children: [
                  // Background image - positioned behind everything
                  Positioned(
                    right: -20, // Slightly off the edge
                    bottom: -20, // Slightly off the bottom
                    child: Opacity(
                      opacity: 0.15, // Make it subtle so text is readable
                      child: Image.asset(
                        'assets/images/parenting-focus-icon.png',
                        height: 180, // Much larger now
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  // Recommendations in foreground - full width
                  Padding(
                    padding: const EdgeInsets.only(right: 10), // Small padding from edge
                    child: recommendations.isEmpty
                        ? Text(
                            'No recommendations yet. Complete a weekly check-in to get started!',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 12,
                              color: const Color(0xFF949494),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: recommendations.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final rec = recommendations[index];
                              final traitName = rec['trait_name'] ?? 'Unknown trait';
                              final action = rec['action'] ?? 'No recommendation';
                              
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent, // Fully transparent
                                  border: Border.all(color: const Color(0xFFFAB494)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      traitName,
                                      style: const TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF995444),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      action,
                                      style: const TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 11,
                                        color: Color(0xFF949494),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
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

  // Header section with logo only
  Widget _buildHeader(BuildContext context, String childName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Center(
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
    );
  }

  // Welcome text section
  Widget _buildWelcomeText(String childName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      child: Center(
        child: Text(
          'Welcome Back, $childName!',
          style: const TextStyle(
            color: Color(0xFF949494),
            fontSize: 28,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Carousel section with recommendations and check-in
  Widget _buildCarousel(BuildContext context, String childId, String childName) {
    final PageController _pageController = PageController(
      viewportFraction: 0.9, // Show partial cards on sides
    );
    
    return Container(
      height: 230,
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            // Enable mouse drag for web
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildLatestRecommendationsCard(childId, childName, context),
              _buildWeeklyCheckInCard(context, childId),
            ],
          ),
          // Add navigation arrows for web
          if (MediaQuery.of(context).size.width > 600) // Only show on web/desktop
            Positioned(
              left: 10,
              top: 95,
              child: IconButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white70,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          if (MediaQuery.of(context).size.width > 600) // Only show on web/desktop
            Positioned(
              right: 10,
              top: 95,
              child: IconButton(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white70,
                  shape: const CircleBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Grid section with feature cards
  Widget _buildGridSection(BuildContext context, String childId, String childName) {
    return Container(
      height: 400, // Fixed height instead of Expanded
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.05, // 5% left margin to match carousel
        30,
        MediaQuery.of(context).size.width * 0.05, // 5% right margin to match carousel  
        20
      ),
      child: Column(
        children: [
          // First Row
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGridCard(
                    title: 'Growth & Development',
                    subtitle: 'Nutritional roadmap',
                    iconPath: 'assets/images/bicep.png',
                    color: const Color(0xFFFAB494),
                    onTap: () => Navigator.push(
                      context,
                      NoAnimationPageRoute(
                        builder: (context) => GrowthMilestonesScreen(
                          childId: childId,
                          childName: childName,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildGridCard(
                    title: 'Immunity & Resilience',
                    subtitle: 'Health tracking',
                    iconPath: 'assets/images/no-virus.png',
                    color: const Color(0xFFFAB494),
                    onTap: () => Navigator.push(
                      context,
                      NoAnimationPageRoute(
                        builder: (context) => ImmunityDashboardScreen(
                          childId: childId,
                          childName: childName,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Second Row
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGridCard(
                    title: 'Genetic Traits',
                    subtitle: 'View profile stats',
                    iconPath: 'assets/images/dna.png',
                    color: const Color(0xFFFAB494),
                    onTap: () => Navigator.push(
                      context,
                      NoAnimationPageRoute(
                        builder: (context) => TraitsScreen(childId: childId),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildGridCard(
                    title: 'History',
                    subtitle: 'Past recommendations',
                    iconPath: 'assets/images/notes.png',
                    color: const Color(0xFFFAB494),
                    onTap: () => Navigator.push(
                      context,
                      NoAnimationPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // Weekly check-in card with proper design
  Widget _buildWeeklyCheckInCard(BuildContext context, String childId) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFFDE6BE),
          ],
        ),
        border: Border.all(color: const Color(0xFFFAB494), width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side - Icon (70% of widget height)
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/questionnaire-icon.png',
                height: 220 * 0.7, // 70% of widget height
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Right side - Text and button
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Weekly Check-in',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF995444),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        NoAnimationPageRoute(
                          builder: (context) => DynamicQuestionnaireScreen(childId: childId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFAB494),
                      foregroundColor: const Color(0xFF995444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Start Now',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
