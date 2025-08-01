import 'package:flutter/material.dart';

class InsightsSummaryModal extends StatefulWidget {
  const InsightsSummaryModal({Key? key}) : super(key: key);

  @override
  State<InsightsSummaryModal> createState() => _InsightsSummaryModalState();
}

class _InsightsSummaryModalState extends State<InsightsSummaryModal> {
  String selectedSection = 'overview'; // overview, attention, nutrition, spark
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF4EA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with logo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
                const Spacer(),
                // Bloomie logo
                Container(
                  width: 100,
                  height: 30,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/bloomie_icon.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 24), // Balance the close button
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _buildSelectedContent(),
          ),
          
          // Bottom navigation dots
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavIcon(Icons.bar_chart, Colors.blue[300]!, 'overview'),
                _buildNavIcon(Icons.remove_red_eye, Colors.orange[300]!, 'attention'),
                _buildNavIcon(Icons.restaurant, Colors.green[300]!, 'nutrition'),
                _buildNavIcon(Icons.auto_awesome, Colors.purple[300]!, 'spark'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, Color color, String section) {
    bool isSelected = selectedSection == section;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSection = section;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (selectedSection) {
      case 'overview':
        return _buildOverviewContent();
      case 'attention':
        return _buildAttentionContent();
      case 'nutrition':
        return _buildNutritionContent();
      case 'spark':
        return _buildSparkContent();
      default:
        return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Understanding Insights Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Important Colour Scheme',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 20),
          
          // Color legend
          Row(
            children: [
              _buildColorLegend('High', Colors.red),
              const SizedBox(width: 20),
              _buildColorLegend('Mid', Colors.orange),
              const SizedBox(width: 20),
              _buildColorLegend('Low', Colors.green),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Expandable sections
          _buildExpandableSection(
            'Attention Chart',
            'How long your child can pay attention towards one task.',
            Icons.remove_red_eye,
            Colors.orange,
          ),
          
          _buildExpandableSection(
            'Nutrition Highlights',
            'Get food and health recommendation.',
            Icons.restaurant,
            Colors.green,
          ),
          
          _buildExpandableSection(
            'Nurture the Spark',
            'Discover latest activities tailored to your child.',
            Icons.auto_awesome,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attention Chart',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 20),
          
          // Attention level indicators
          Row(
            children: [
              _buildColorLegend('High', Colors.red),
              const SizedBox(width: 15),
              _buildColorLegend('Mid', Colors.orange),
              const SizedBox(width: 15),
              _buildColorLegend('Low', Colors.green),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Pie chart placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Attention Chart\n(Pie Chart)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF717070),
                  fontFamily: 'Fredoka',
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          _buildExpandableSection(
            'Focus & Attention',
            'Short attention span.\nOften loses attention during middle/daily activities/during dinner.',
            Icons.visibility,
            Colors.orange,
          ),
          
          _buildExpandableSection(
            'Social Engagement',
            'Good attention span.\nCreates a "focus zone".',
            Icons.people,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutritional Highlights',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This week\'s nutrition insights!\nSee food trends and more for Bloomie magnesium intake.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 30),
          
          // Nutrition bars
          _buildNutritionBar('Iron', 0.8, Colors.red),
          _buildNutritionBar('Magnesium', 0.6, Colors.orange),
          _buildNutritionBar('Omega-3', 0.9, Colors.green),
          
          const SizedBox(height: 30),
          
          _buildExpandableSection(
            'Sleep & Appetite Issues',
            'Try to solve sleeping troubles.\nMelatonin-containing foods...',
            Icons.bed,
            Colors.orange,
          ),
          
          _buildExpandableSection(
            'Mild Nutrient Gaps',
            'This describes the nutrients your child needs.',
            Icons.restaurant_menu,
            Colors.orange,
          ),
          
          _buildExpandableSection(
            'Balanced Nutrition',
            'This offering a mix of tasty greens.\nDHA and omega support...',
            Icons.balance,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSparkContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nurture The Spark',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dr Bloomie tailors activities to boost holistic development according to your child\'s data.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 30),
          
          // Activity cards with images
          _buildActivityCard(
            '1. Beginner Music Class 🎵',
            'Why: Builds rhythm & listening skills Impact: They love connection skills & stimulated, regulation.',
            'Classes around you: Link',
          ),
          
          _buildActivityCard(
            '2. Group storytelling 📚',
            'Why: Encourages expression, listening, and collaboration. Impact: Supports confidence and language development.',
            'Classes around you: Link',
          ),
          
          _buildActivityCard(
            '3. Calm-down kit 😌',
            'Why: Helps toddlers transition between activities. Impact: Reduces meltdowns and builds emotional intelligence.',
            'Kit Link: Link',
          ),
        ],
      ),
    );
  }

  Widget _buildColorLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF717070),
            fontFamily: 'Fredoka',
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(String title, String content, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF717070),
            fontFamily: 'Fredoka',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF717070),
                fontFamily: 'Fredoka',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionBar(String nutrient, double value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nutrient,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, String description, String link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE5BE),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF717070),
              fontFamily: 'Fredoka',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            link,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontFamily: 'Fredoka',
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the modal
void showInsightsSummary(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const InsightsSummaryModal(),
  );
}