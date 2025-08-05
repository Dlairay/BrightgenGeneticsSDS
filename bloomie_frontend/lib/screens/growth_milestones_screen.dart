import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/utils/logger.dart';
import '../core/widgets/persistent_bottom_nav.dart';

class GrowthMilestonesScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const GrowthMilestonesScreen({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);

  @override
  _GrowthMilestonesScreenState createState() => _GrowthMilestonesScreenState();
}

class _GrowthMilestonesScreenState extends State<GrowthMilestonesScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _roadmapData;

  @override
  void initState() {
    super.initState();
    _loadGrowthRoadmap();
  }

  String _formatAge(String ageString) {
    try {
      final ageInYears = int.tryParse(ageString) ?? 0;
      
      if (ageInYears == 0) {
        return 'Newborn';
      } else if (ageInYears == 1) {
        return '1 year old';
      } else if (ageInYears < 2) {
        // For children under 2, show in months (approximate)
        final months = ageInYears * 12;
        return '$months months old';
      } else {
        return '$ageInYears years old';
      }
    } catch (e) {
      return ageString; // Fallback to original string
    }
  }

  Future<void> _loadGrowthRoadmap() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await ApiService.getGrowthMilestonesRoadmap(widget.childId);
      setState(() {
        _roadmapData = data;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load growth roadmap: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF4EA),
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: const Text(
          'Growth & Development',
          style: TextStyle(
            color: Color(0xFF717070),
            fontSize: 20,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
            Expanded(
              child: _isLoading ? _buildLoadingState() : _error != null ? _buildErrorState() : _buildRoadmap(),
            ),
            // Persistent bottom navigation
            PersistentBottomNav(
              currentChildId: widget.childId,
              currentChildName: widget.childName,
              selectedIndex: 1, // Home is selected (since this is accessed from home)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBED9B0)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading growth roadmap...',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              color: Color(0xFF717070),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load growth roadmap',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF717070),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadGrowthRoadmap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBED9B0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Fredoka'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmap() {
    if (_roadmapData == null) return Container();

    final data = _roadmapData!['data'] as Map<String, dynamic>? ?? {};
    final childName = data['child_name'] ?? widget.childName;
    final currentAgeRaw = data['current_age'] ?? 'Unknown';
    final currentAge = currentAgeRaw.toString(); // Convert int to String safely
    final roadmap = data['roadmap'] as List<dynamic>? ?? [];

    if (roadmap.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Growth Roadmap Available',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF717070),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No Growth & Development genetic traits found for this child.',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildWindingPathRoadmap(childName, currentAge, roadmap);
  }

  // 🛤️ FOCUSED ROADMAP UI - Current Age Focus
  Widget _buildWindingPathRoadmap(String childName, String currentAge, List<dynamic> roadmap) {
    // Find current milestone
    Map<String, dynamic>? currentMilestone;
    Map<String, dynamic>? nextMilestone;
    List<Map<String, dynamic>> otherMilestones = [];
    
    for (var milestone in roadmap) {
      final milestoneMap = milestone as Map<String, dynamic>;
      if (milestoneMap['is_current'] == true) {
        currentMilestone = milestoneMap;
      } else if (currentMilestone != null && nextMilestone == null) {
        nextMilestone = milestoneMap; // First milestone after current
      } else {
        otherMilestones.add(milestoneMap);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 👶 CHILD STATUS HEADER
          _buildChildStatusHeader(childName, currentAge, currentMilestone),
          
          const SizedBox(height: 30),

          // 🎯 CURRENT FOCUS SECTION
          if (currentMilestone != null) ...[
            _buildCurrentFocusSection(currentMilestone, childName),
            const SizedBox(height: 25),
          ],

          // 📈 COMING UP NEXT SECTION  
          if (nextMilestone != null) ...[
            _buildNextMilestoneSection(nextMilestone),
          ],
        ],
      ),
    );
  }

  // 👶 CHILD STATUS HEADER
  Widget _buildChildStatusHeader(String childName, String currentAge, Map<String, dynamic>? currentMilestone) {
    final currentAgeRange = currentMilestone != null 
        ? 'Ages ${(currentMilestone['age_start'] ?? 0).toString()}-${(currentMilestone['age_end'] ?? 0).toString()}'
        : 'Age $currentAge months';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBED9B0), Color(0xFFBED9B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBED9B0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Large child avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Text(
                childName.isNotEmpty ? childName[0].toUpperCase() : '👶',
                style: const TextStyle(
                  color: Color(0xFFBED9B0),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$childName is currently',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAge(currentAge),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🎯 Focus: $currentAgeRange',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 CURRENT FOCUS SECTION - Detailed View
  Widget _buildCurrentFocusSection(Map<String, dynamic> currentMilestone, String childName) {
    final ageStart = (currentMilestone['age_start'] ?? 0).toString();
    final ageEnd = (currentMilestone['age_end'] ?? 0).toString();
    final milestones = currentMilestone['milestones'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFBED9B0), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBED9B0).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFBED9B0), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Current Focus: Ages $ageStart-$ageEnd',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBED9B0),
                      ),
                    ),
                    Text(
                      'Personalized recommendations for $childName right now',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Current milestones - full detail view
          ...milestones.map((milestone) => _buildDetailedMilestoneItem(milestone)),
        ],
      ),
    );
  }

  // 📈 NEXT MILESTONE SECTION - Preview
  Widget _buildNextMilestoneSection(Map<String, dynamic> nextMilestone) {
    final ageStart = (nextMilestone['age_start'] ?? 0).toString();
    final ageEnd = (nextMilestone['age_end'] ?? 0).toString();
    final milestones = nextMilestone['milestones'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFF9800), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFFFF9800), size: 24),
              const SizedBox(width: 8),
              Text(
                '📈 Coming Up: Ages $ageStart-$ageEnd',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${milestones.length} new recommendations will unlock',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          
          // Preview of next milestones (first 2)
          ...milestones.take(2).map((milestone) => _buildPreviewMilestoneItem(milestone)),
          
          if (milestones.length > 2) ...[
            const SizedBox(height: 8),
            Text(
              '+ ${milestones.length - 2} more coming soon...',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 11,
                color: Color(0xFFFF9800),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🗺️ ROADMAP OVERVIEW - Compact Timeline
  Widget _buildRoadmapOverview(List<dynamic> roadmap, String childName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map, color: Color(0xFF666666), size: 20),
              SizedBox(width: 8),
              Text(
                '🗺️ Complete Growth Journey',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Compact timeline view
          Row(
            children: [
              ...roadmap.asMap().entries.map((entry) {
                final index = entry.key;
                final ageGroup = entry.value as Map<String, dynamic>;
                final isCurrent = ageGroup['is_current'] ?? false;
                final isPast = ageGroup['is_past'] ?? false;
                final isLast = index == roadmap.length - 1;
                
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildTimelineDot(ageGroup, isCurrent, isPast)),
                      if (!isLast) 
                        Container(
                          height: 2,
                          color: isPast ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Tap any milestone above to jump to that age range',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 10,
                color: Color(0xFF999999),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👶 CHILD AVATAR
  Widget _buildChildAvatar(String childName) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBED9B0), Color(0xFFBED9B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBED9B0).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          childName.isNotEmpty ? childName[0].toUpperCase() : '👶',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
          ),
        ),
      ),
    );
  }

  // 🛤️ WINDING PATH STOP (Milestone Card on Path)
  Widget _buildWindingPathStop(Map<String, dynamic> ageGroup, int index, bool isLast, bool isCurrent, String childName) {
    final ageStart = (ageGroup['age_start'] ?? 0).toString();
    final ageEnd = (ageGroup['age_end'] ?? 0).toString(); 
    final isPast = ageGroup['is_past'] ?? false;
    final milestones = ageGroup['milestones'] as List<dynamic>? ?? [];

    // Determine status styling
    Color statusColor;
    String statusIcon;
    String statusText;
    
    if (isPast) {
      statusColor = const Color(0xFF2196F3);
      statusIcon = '✅';
      statusText = 'Completed';
    } else if (isCurrent) {
      statusColor = const Color(0xFFBED9B0);
      statusIcon = '🎯';
      statusText = 'Current Focus';
    } else {
      statusColor = const Color(0xFFFF9800);
      statusIcon = '⏳';
      statusText = 'Upcoming';
    }

    // Create winding path effect by alternating left/right
    final isLeftSide = index % 2 == 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 50),
      child: Column(
        children: [
          // Path Row with Avatar and Milestone Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side content or spacer
              if (isLeftSide) ...[
                Expanded(child: _buildMilestoneCard(ageGroup, statusColor, statusIcon, statusText, milestones)),
                const SizedBox(width: 12),
              ] else ...[
                const Expanded(child: SizedBox()),
                const SizedBox(width: 12),
              ],
              
              // Center Path with Avatar (for current) or Dot
              Column(
                children: [
                  if (isCurrent) 
                    _buildChildAvatarOnPath(childName, statusColor)
                  else
                    _buildPathDot(statusColor),
                  
                  // Winding path line
                  if (!isLast) _buildWindingPathLine(isLeftSide, index),
                ],
              ),
              
              // Right side content or spacer
              if (!isLeftSide) ...[
                const SizedBox(width: 12),
                Expanded(child: _buildMilestoneCard(ageGroup, statusColor, statusIcon, statusText, milestones)),
              ] else ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 👶 CHILD AVATAR ON PATH (Current Milestone)
  Widget _buildChildAvatarOnPath(String childName, Color statusColor) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          childName.isNotEmpty ? childName[0].toUpperCase() : '👶',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
          ),
        ),
      ),
    );
  }

  // 🔘 PATH DOT
  Widget _buildPathDot(Color statusColor) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // 🛤️ WINDING PATH LINE
  Widget _buildWindingPathLine(bool isLeftSide, int index) {
    return CustomPaint(
      size: const Size(40, 80),
      painter: WindingPathPainter(
        isLeftSide: isLeftSide,
        pathColor: const Color(0xFFE0E0E0),
      ),
    );
  }

  // 📋 MILESTONE CARD
  Widget _buildMilestoneCard(Map<String, dynamic> ageGroup, Color statusColor, String statusIcon, String statusText, List<dynamic> milestones) {
    final ageStart = (ageGroup['age_start'] ?? 0).toString();
    final ageEnd = (ageGroup['age_end'] ?? 0).toString();
    final isCurrent = ageGroup['is_current'] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: statusColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age range header
          Row(
            children: [
              Expanded(
                child: Text(
                  '$statusIcon Ages $ageStart-$ageEnd',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Milestone count
          Text(
            '${milestones.length} trait-based recommendation${milestones.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          
          // Milestones (show first 2, then expandable)
          ...milestones.take(2).map((milestone) => _buildCompactMilestoneItem(milestone, statusColor)),
          
          if (milestones.length > 2) ...[
            const SizedBox(height: 8),
            Text(
              '+${milestones.length - 2} more recommendations',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 📝 COMPACT MILESTONE ITEM (for cards)
  Widget _buildCompactMilestoneItem(dynamic milestone, Color statusColor) {
    final milestoneMap = milestone as Map<String, dynamic>? ?? {};
    final traitName = milestoneMap['trait_name'] ?? 'Unknown Trait';
    final geneId = milestoneMap['gene_id'] ?? '';
    final focusDescription = milestoneMap['focus_description'] ?? 'No description available';
    final foodExamples = milestoneMap['food_examples'] as List<dynamic>? ?? [];
    final graphicIconId = milestoneMap['graphic_icon_id'] ?? '';

    // Map icon IDs to emojis
    final iconMap = {
      'brain_icon': '🧠',
      'tummy_icon': '🤱',
      'energy_icon': '⚡',
      'shield_icon': '🛡️',
      'health_icon': '💪',
      'idea_icon': '💡',
      'school_icon': '🎒',
      'choices_icon': '🤔',
      'balance_icon': '⚖️',
      'battery_icon': '🔋',
    };
    final icon = iconMap[graphicIconId] ?? '📈';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$traitName${geneId.isNotEmpty ? ' ($geneId)' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  focusDescription,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 10,
                    color: Color(0xFF666666),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (foodExamples.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: foodExamples.take(3).map((food) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        food.toString().replaceAll('_', ' '),
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 8,
                          color: Colors.white,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(dynamic milestone, Color statusColor) {
    final milestoneMap = milestone as Map<String, dynamic>? ?? {};
    final traitName = milestoneMap['trait_name'] ?? 'Unknown Trait';
    final geneId = milestoneMap['gene_id'] ?? '';
    final focusDescription = milestoneMap['focus_description'] ?? 'No description available';
    final foodExamples = milestoneMap['food_examples'] as List<dynamic>? ?? [];
    final graphicIconId = milestoneMap['graphic_icon_id'] ?? '';

    // Map icon IDs to emojis
    final iconMap = {
      'brain_icon': '🧠',
      'tummy_icon': '🤱',
      'energy_icon': '⚡',
      'shield_icon': '🛡️',
      'health_icon': '💪',
      'idea_icon': '💡',
      'school_icon': '🎒',
      'choices_icon': '🤔',
      'balance_icon': '⚖️',
      'battery_icon': '🔋',
    };
    final icon = iconMap[graphicIconId] ?? '📈';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$traitName${geneId.isNotEmpty ? ' ($geneId)' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  focusDescription,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                
                if (foodExamples.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...foodExamples.take(4).map((food) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          food.toString().replaceAll('_', ' '),
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      )),
                      if (foodExamples.length > 4)
                        Text(
                          '+${foodExamples.length - 4} more',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 10,
                            color: Color(0xFF999999),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📋 DETAILED MILESTONE ITEM - Full Information
  Widget _buildDetailedMilestoneItem(dynamic milestone) {
    final milestoneMap = milestone as Map<String, dynamic>? ?? {};
    final traitName = milestoneMap['trait_name'] ?? 'Unknown Trait';
    final geneId = milestoneMap['gene_id'] ?? '';
    final focusDescription = milestoneMap['focus_description'] ?? 'No description available';
    final foodExamples = milestoneMap['food_examples'] as List<dynamic>? ?? [];
    final graphicIconId = milestoneMap['graphic_icon_id'] ?? '';

    // Map icon IDs to emojis
    final iconMap = {
      'brain_icon': '🧠',
      'tummy_icon': '🤱',
      'energy_icon': '⚡',
      'shield_icon': '🛡️',
      'health_icon': '💪',
      'idea_icon': '💡',
      'school_icon': '🎒',
      'choices_icon': '🤔',
      'balance_icon': '⚖️',
      'battery_icon': '🔋',
    };
    final icon = iconMap[graphicIconId] ?? '📈';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: const Color(0xFFBED9B0), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$traitName${geneId.isNotEmpty ? ' ($geneId)' : ''}',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      focusDescription,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (foodExamples.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '🍎 Recommended Foods:',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBED9B0),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: foodExamples.map((food) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBED9B0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  food.toString().replaceAll('_', ' '),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // 👀 PREVIEW MILESTONE ITEM - Coming Soon
  Widget _buildPreviewMilestoneItem(dynamic milestone) {
    final milestoneMap = milestone as Map<String, dynamic>? ?? {};
    final traitName = milestoneMap['trait_name'] ?? 'Unknown Trait';
    final geneId = milestoneMap['gene_id'] ?? '';
    final graphicIconId = milestoneMap['graphic_icon_id'] ?? '';

    final iconMap = {
      'brain_icon': '🧠',
      'tummy_icon': '🤱',
      'energy_icon': '⚡',
      'shield_icon': '🛡️',
      'health_icon': '💪',
      'idea_icon': '💡',
      'school_icon': '🎒',
      'choices_icon': '🤔',
      'balance_icon': '⚖️',
      'battery_icon': '🔋',
    };
    final icon = iconMap[graphicIconId] ?? '📈';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: const Color(0xFFFF9800), width: 3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$traitName${geneId.isNotEmpty ? ' ($geneId)' : ''}',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ⚪ TIMELINE DOT - For overview
  Widget _buildTimelineDot(Map<String, dynamic> ageGroup, bool isCurrent, bool isPast) {
    final ageStart = (ageGroup['age_start'] ?? 0).toString();
    final ageEnd = (ageGroup['age_end'] ?? 0).toString();
    
    Color dotColor;
    if (isPast) {
      dotColor = const Color(0xFF2196F3);
    } else if (isCurrent) {
      dotColor = const Color(0xFFBED9B0);
    } else {
      dotColor = const Color(0xFFE0E0E0);
    }

    return Column(
      children: [
        Container(
          width: isCurrent ? 16 : 12,
          height: isCurrent ? 16 : 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: isCurrent ? [
              BoxShadow(
                color: dotColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$ageStart-$ageEnd',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 8,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: isCurrent ? const Color(0xFFBED9B0) : const Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}

// 🎨 CUSTOM PAINTER FOR WINDING PATH
class WindingPathPainter extends CustomPainter {
  final bool isLeftSide;
  final Color pathColor;

  WindingPathPainter({
    required this.isLeftSide,
    required this.pathColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pathColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Start from center top
    path.moveTo(size.width / 2, 0);
    
    if (isLeftSide) {
      // Curve to the left, then back to center
      path.quadraticBezierTo(
        size.width * 0.2, // Control point X (left)
        size.height * 0.3, // Control point Y
        size.width * 0.1, // End point X (far left)
        size.height * 0.5, // End point Y (middle)
      );
      path.quadraticBezierTo(
        size.width * 0.2, // Control point X
        size.height * 0.7, // Control point Y
        size.width / 2, // End point X (center)
        size.height, // End point Y (bottom)
      );
    } else {
      // Curve to the right, then back to center
      path.quadraticBezierTo(
        size.width * 0.8, // Control point X (right)
        size.height * 0.3, // Control point Y
        size.width * 0.9, // End point X (far right)
        size.height * 0.5, // End point Y (middle)
      );
      path.quadraticBezierTo(
        size.width * 0.8, // Control point X
        size.height * 0.7, // Control point Y
        size.width / 2, // End point X (center)
        size.height, // End point Y (bottom)
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}