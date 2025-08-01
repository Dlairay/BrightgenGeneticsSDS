import 'package:flutter/material.dart';

class GeneticsSummaryPage extends StatefulWidget {
  @override
  _GeneticsSummaryPageState createState() => _GeneticsSummaryPageState();
}

class _GeneticsSummaryPageState extends State<GeneticsSummaryPage> {
  Map<String, bool> expandedTraits = {};
  Map<String, Map<String, bool>> expandedSubItems = {};

  final List<GeneticTrait> traits = [
    GeneticTrait(
      title: 'Eczema tendency',
      percentage: 94,
      gene: 'FLG',
      icon: Icons.healing,
      color: Color(0xFFFFB366),
      subItems: [
        SubItem(title: 'What is this gene?', content: 'The FLG gene plays a key role in helping children learn to understand and produce speech. A strong expression of this gene is crucial for early language development, including speaking, reading, and communication.'),
        SubItem(title: 'Did you know?', content: 'Children with stronger FLG gene expression often show earlier language development and better communication skills.'),
        SubItem(title: 'Helpful Lifestyle Tips', content: 'Apply moisturizer right after bathing (\'lock and seal\' method). Keep baths short and lukewarm. Use a humidifier in dry environments.'),
        SubItem(title: 'What to Watch For', content: 'Monitor for early signs of dry or irritated skin, especially after bathing or in dry weather.'),
        SubItem(title: 'Suggested Care Items', content: 'Gentle, fragrance-free moisturizers and mild cleansers designed for sensitive skin.'),
        SubItem(title: 'When to See a Doctor', content: 'If persistent redness, itching, or rash appears despite proper skincare routine.'),
      ],
    ),
    GeneticTrait(
      title: 'Language Learning Strength',
      percentage: 90,
      gene: 'FOXP2',
      icon: Icons.record_voice_over,
      color: Color(0xFF98E4D6),
      subItems: [
        SubItem(title: 'What is this gene?', content: 'The FOXP2 gene is crucial for speech and language development, affecting motor control needed for articulation.'),
        SubItem(title: 'Did you know?', content: 'This gene is often called the "language gene" and variations can affect how easily children learn to speak.'),
        SubItem(title: 'Helpful Lifestyle Tips', content: 'Read aloud daily, engage in conversations, sing songs, and expose your child to multiple languages early.'),
        SubItem(title: 'What to Watch For', content: 'Early babbling, first words, and progression in vocabulary development.'),
        SubItem(title: 'Suggested Care Items', content: 'Age-appropriate books, musical instruments, and interactive language learning toys.'),
        SubItem(title: 'When to See a Doctor', content: 'If language milestones are significantly delayed compared to typical development.'),
      ],
    ),
    GeneticTrait(
      title: 'Enhanced Memory & Learning',
      percentage: 86,
      gene: 'BDNF',
      icon: Icons.psychology,
      color: Color(0xFFFFE066),
      subItems: [
        SubItem(title: 'What is this gene?', content: 'BDNF (Brain-Derived Neurotrophic Factor) supports the growth and maintenance of neurons, crucial for learning and memory.'),
        SubItem(title: 'Did you know?', content: 'Higher BDNF levels are associated with better memory formation and cognitive flexibility.'),
        SubItem(title: 'Helpful Lifestyle Tips', content: 'Encourage physical activity, provide varied learning experiences, and ensure adequate sleep for memory consolidation.'),
        SubItem(title: 'What to Watch For', content: 'Strong pattern recognition, good memory for details, and quick learning of new concepts.'),
        SubItem(title: 'Suggested Care Items', content: 'Educational puzzles, memory games, and varied sensory learning materials.'),
        SubItem(title: 'When to See a Doctor', content: 'If learning difficulties persist or if there are concerns about cognitive development.'),
      ],
    ),
    GeneticTrait(
      title: 'ADHD Tendency',
      percentage: 72,
      gene: 'DRD4, DRD5, DAT1, ADRA2A',
      icon: Icons.flash_on,
      color: Color(0xFFFF9999),
      subItems: [
        SubItem(title: 'What is this gene?', content: 'These genes affect dopamine regulation and attention control, influencing focus and hyperactivity levels.'),
        SubItem(title: 'Did you know?', content: 'ADHD traits can also bring advantages like creativity, high energy, and ability to hyperfocus on interesting topics.'),
        SubItem(title: 'Helpful Lifestyle Tips', content: 'Maintain consistent routines, provide regular physical activity, and create calm, organized environments.'),
        SubItem(title: 'What to Watch For', content: 'Difficulty sitting still, trouble focusing on tasks, impulsive behavior, or excessive fidgeting.'),
        SubItem(title: 'Suggested Care Items', content: 'Fidget toys, structured activity schedules, and tools for organization.'),
        SubItem(title: 'When to See a Doctor', content: 'If attention or hyperactivity issues significantly impact daily functioning or learning.'),
      ],
    ),
    GeneticTrait(
      title: 'Stress Sensitivity',
      percentage: 66,
      gene: 'COMT (Val/Val variant)',
      icon: Icons.favorite,
      color: Color(0xFFE8B4FF),
      subItems: [
        SubItem(title: 'What is this gene?', content: 'The COMT gene affects how quickly the body breaks down stress hormones like dopamine and norepinephrine.'),
        SubItem(title: 'Did you know?', content: 'People with this variant may be more sensitive to stress but also more responsive to positive environments.'),
        SubItem(title: 'Helpful Lifestyle Tips', content: 'Create calm, predictable environments and teach stress-reduction techniques early.'),
        SubItem(title: 'What to Watch For', content: 'Strong reactions to changes in routine, overstimulation, or high-stress environments.'),
        SubItem(title: 'Suggested Care Items', content: 'Comfort items, noise-reducing headphones, and calming sensory tools.'),
        SubItem(title: 'When to See a Doctor', content: 'If stress responses seem excessive or interfere with daily activities.'),
      ],
    ),
    GeneticTrait(
      title: 'Seafood Allergy Risk',
      percentage: 48,
      gene: 'HLA-DQB1',
      icon: Icons.warning,
      color: Color(0xFFFFCC99),
      subItems: [
        SubItem(title: 'What is this gene?', content: 'HLA genes help the immune system distinguish between the body\'s own proteins and foreign substances.'),
        SubItem(title: 'Did you know?', content: 'Having this genetic variant doesn\'t guarantee an allergy, but suggests increased vigilance is warranted.'),
        SubItem(title: 'Helpful Lifestyle Tips', content: 'Introduce seafood gradually and in small amounts, keep a food diary.'),
        SubItem(title: 'What to Watch For', content: 'Skin reactions, digestive issues, or respiratory symptoms after eating seafood.'),
        SubItem(title: 'Suggested Care Items', content: 'EpiPen if allergies develop, antihistamines, and emergency action plan.'),
        SubItem(title: 'When to See a Doctor', content: 'For any allergic reactions to food, or to discuss allergy testing and management.'),
      ],
    ),
    GeneticTrait(
      title: 'Picky Eating (Bitter Sensitivity)',
      percentage: 32,
      gene: 'TAS2R38',
      icon: Icons.restaurant,
      color: Color(0xFFB4E7CE),
      subItems: [
        SubItem(title: 'What is this gene?', content: 'TAS2R38 affects taste sensitivity, particularly to bitter compounds found in many vegetables.'),
        SubItem(title: 'Did you know?', content: 'Children with this variant may be "supertasters" who experience flavors more intensely than others.'),
        SubItem(title: 'Helpful Lifestyle Tips', content: 'Offer foods multiple times, pair bitter foods with sweet ones, and avoid forcing eating.'),
        SubItem(title: 'What to Watch For', content: 'Strong preferences for sweet/salty foods and rejection of vegetables or bitter foods.'),
        SubItem(title: 'Suggested Care Items', content: 'Fun plates and utensils, food preparation tools for child involvement.'),
        SubItem(title: 'When to See a Doctor', content: 'If eating restrictions lead to nutritional concerns or extreme weight loss/gain.'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bloomie_background3.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Bloomie logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Center(
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
              ),
              
              // Title and description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Genetic Summary',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF717070),
                        fontSize: 30,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'These are some traits your baby may be genetically predisposed to develop.\nTap on each trait to view a detailed description.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF818181),
                        fontSize: 15,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Scrollable traits list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                  itemCount: traits.length,
                  itemBuilder: (context, index) {
                    return _buildTraitCard(traits[index]);
                  },
                ),
              ),
              
              // Continue button and bottom nav
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Go back to home or previous page
                      },
                      child: Container(
                        width: 206,
                        height: 55,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFFAB494),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Continue to home',
                            style: TextStyle(
                              color: const Color(0xFF995444),
                              fontSize: 20,
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Bottom navigation
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
                            // Stay on current page or show stats
                            print("Already viewing genetics summary");
                          }),
                          _buildBottomNavIcon('assets/images/home.png', () {
                            Navigator.pop(context); // Go back to home
                          }),
                          _buildBottomNavIcon('assets/images/drbloom.png', () {
                            // Navigate to chat bot (you'll need to import the ChatBotPage)
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatBotPage()));
                            print("Navigate to Dr Bloom chat");
                          }),
                          _buildBottomNavIcon('assets/images/profile.png', () {
                            // Navigate to profile (you'll need to import the ProfilePage)
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                            print("Navigate to profile");
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
      ),
    );
  }

  Widget _buildTraitCard(GeneticTrait trait) {
    bool isExpanded = expandedTraits[trait.title] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: ShapeDecoration(
        color: const Color(0xFFFDE8CB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Main trait card
          GestureDetector(
            onTap: () {
              setState(() {
                expandedTraits[trait.title] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: trait.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      trait.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trait.title,
                          style: TextStyle(
                            color: Color(0xFF717070),
                            fontSize: 20,
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Development likelihood: ',
                                style: TextStyle(
                                  color: Color(0xFF818181),
                                  fontSize: 15,
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: '${trait.percentage}%',
                                style: TextStyle(
                                  color: Color(0xFF818181),
                                  fontSize: 20,
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gene ${trait.gene}',
                          style: TextStyle(
                            color: Color(0xFF818181),
                            fontSize: 15,
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: trait.percentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF9C9C9C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Expand/collapse icon
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Color(0xFF717070),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded sub-items
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: trait.subItems.map((subItem) => _buildSubItem(trait.title, subItem)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubItem(String traitTitle, SubItem subItem) {
    String key = '${traitTitle}_${subItem.title}';
    bool isExpanded = expandedSubItems[traitTitle]?[subItem.title] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (expandedSubItems[traitTitle] == null) {
                  expandedSubItems[traitTitle] = {};
                }
                expandedSubItems[traitTitle]![subItem.title] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      subItem.title,
                      style: TextStyle(
                        color: Color(0xFF717070),
                        fontSize: 16,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    color: Color(0xFF717070),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Text(
                subItem.content,
                style: TextStyle(
                  color: Color(0xFF818181),
                  fontSize: 14,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
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

class GeneticTrait {
  final String title;
  final int percentage;
  final String gene;
  final IconData icon;
  final Color color;
  final List<SubItem> subItems;

  GeneticTrait({
    required this.title,
    required this.percentage,
    required this.gene,
    required this.icon,
    required this.color,
    required this.subItems,
  });
}

class SubItem {
  final String title;
  final String content;

  SubItem({
    required this.title,
    required this.content,
  });
}