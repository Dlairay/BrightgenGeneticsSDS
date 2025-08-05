import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/utils/logger.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/persistent_bottom_nav.dart';

class ImmunityDashboardScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ImmunityDashboardScreen({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);

  @override
  _ImmunityDashboardScreenState createState() => _ImmunityDashboardScreenState();
}

class _ImmunityDashboardScreenState extends State<ImmunityDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  Set<String> _expandedRationales = {}; // Track which rationales are expanded
  Set<String> _expandedMedicalLogs = {}; // Track which medical logs are expanded

  @override
  void initState() {
    super.initState();
    _loadImmunityDashboard();
  }

  Future<void> _loadImmunityDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await ApiService.getImmunityDashboard(widget.childId);
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load immunity dashboard: $e');
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
          '🛡️ Immunity & Resilience',
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
            image: AssetImage('assets/images/bloomie_background2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading ? _buildLoadingState() : _error != null ? _buildErrorState() : _buildDashboard(),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF98E4D6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading immunity dashboard...',
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
              'Failed to load immunity dashboard',
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
              onPressed: _loadImmunityDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF98E4D6),
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

  Widget _buildDashboard() {
    if (_dashboardData == null) return Container();

    final suggestions = _dashboardData!['suggestions'] as Map<String, dynamic>? ?? {};
    final medicalLogs = _dashboardData!['medical_logs'] as Map<String, dynamic>? ?? {};
    
    final childName = suggestions['child_name'] ?? widget.childName;
    final suggestionsByTrait = suggestions['suggestions_by_trait'] as Map<String, dynamic>? ?? {};
    final immunityTraits = suggestions['immunity_traits'] as List<dynamic>? ?? [];
    final logs = medicalLogs['logs'] as List<dynamic>? ?? [];
    final hasEmergencyIndicators = medicalLogs['has_emergency_indicators'] as bool? ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        // Reload immunity dashboard data
        await _loadImmunityDashboard();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personalized Suggestions Section
            _buildSuggestionsSection(suggestionsByTrait),
            const SizedBox(height: 30),

            // Medical Visit Logs Section
            _buildMedicalLogsSection(logs, hasEmergencyIndicators),
          ],
        ),
      ),
    );
  }



  Widget _buildSuggestionsSection(Map<String, dynamic> suggestionsByTrait) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Personalized Suggestions',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF717070),
          ),
        ),
        const SizedBox(height: 15),
        
        if (suggestionsByTrait.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No immunity & resilience traits found for this child.',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...suggestionsByTrait.entries.map((entry) => _buildTraitSuggestions(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildTraitSuggestions(String traitName, dynamic suggestions) {
    final suggestionsList = suggestions as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            traitName,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 12),
          
          ...suggestionsList.map((suggestion) => _buildSuggestionItem(suggestion)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(dynamic suggestion) {
    final suggestionMap = suggestion as Map<String, dynamic>? ?? {};
    final suggestionType = suggestionMap['suggestion_type'] ?? suggestionMap['type'] ?? 'Unknown';
    final suggestionText = suggestionMap['suggestion'] ?? suggestionMap['text'] ?? 'No suggestion available';
    final rationale = suggestionMap['rationale'] ?? suggestionMap['reason'] ?? 'No rationale provided';
    
    final isProvide = suggestionType == 'Provide';
    final icon = isProvide ? '✅' : '❌';
    final borderColor = isProvide ? Colors.green : Colors.red;
    
    // Create unique key for this suggestion
    final suggestionKey = '${suggestionType}_${suggestionText.hashCode}';
    final isExpanded = _expandedRationales.contains(suggestionKey);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$suggestionType: $suggestionText',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Expandable dropdown button
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedRationales.remove(suggestionKey);
                    } else {
                      _expandedRationales.add(suggestionKey);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Why?',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: borderColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: borderColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Expandable rationale section
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: borderColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: borderColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Why This Matters',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rationale,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalLogsSection(List<dynamic> logs, bool hasEmergencyIndicators) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏥 Medical Visit Logs',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF717070),
          ),
        ),
        const SizedBox(height: 15),

        // Emergency warning banner if needed
        if (hasEmergencyIndicators)
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚠️ Emergency indicators found in recent logs. Please consult your doctor.',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Medical logs list
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No medical logs yet. Logs are created when Dr. Bloom discussions involve immunity-related topics.',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...logs.map((log) => _buildMedicalLogCard(log)).toList(),
      ],
    );
  }

  Widget _buildMedicalLogCard(dynamic logData) {
    final log = logData as Map<String, dynamic>? ?? {};
    final logId = log['id'] as String? ?? '';
    
    // Extract log data following the HTML pattern
    final logDate = log['date'] != null ? DateTime.parse(log['date']).toLocal() : DateTime.now();
    final conversationDate = log['conversation_date'] != null 
        ? DateTime.parse(log['conversation_date']).toLocal() 
        : logDate;
    
    // Try to get raw fields first, then fall back to transformed fields
    final rawProblemDiscussed = log['raw_problem_discussed'] as String? ?? '';
    final rawImmediateRecommendations = log['raw_immediate_recommendations'] as List<dynamic>? ?? [];
    final rawFollowUpQuestions = log['raw_follow_up_questions'] as List<dynamic>? ?? [];
    final rawDisclaimer = log['raw_disclaimer'] as String? ?? '';
    
    // Use raw fields if available, otherwise use transformed fields
    final primaryConcerns = log['primary_concerns'] as List<dynamic>? ?? [];
    final summary = rawProblemDiscussed.isNotEmpty ? rawProblemDiscussed : (log['summary'] as String? ?? 'No summary available');
    final traitsDiscussed = log['traits_discussed'] as List<dynamic>? ?? [];
    final questionsForDoctor = rawFollowUpQuestions.isNotEmpty ? rawFollowUpQuestions : (log['questions_for_doctor'] as List<dynamic>? ?? []);
    final emergencyIndicators = log['emergency_indicators'] as List<dynamic>? ?? [];
    final immediateRecommendations = rawImmediateRecommendations;
    
    // Format dates
    final conversationDateStr = '${conversationDate.day}/${conversationDate.month}/${conversationDate.year}';
    final logDateStr = '${logDate.day}/${logDate.month}/${logDate.year}';
    
    // Check if this log is expanded
    final isExpanded = _expandedMedicalLogs.contains(logId);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedMedicalLogs.remove(logId);
          } else {
            _expandedMedicalLogs.add(logId);
          }
        });
      },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FD), // Light blue background like HTML
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: Color(0xFF007BFF), width: 4), // Blue left border
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Always visible
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Log - $conversationDateStr',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Summary preview in collapsed state
                        Text(
                          summary.isEmpty ? 'No summary available' : summary,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            color: summary.isEmpty ? Colors.grey[600] : const Color(0xFF555555),
                            fontStyle: summary.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF007BFF),
                    size: 24,
                  ),
                ],
              ),

              // Expanded content - only visible when expanded
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  'Generated: $logDateStr',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                // Immunity Traits Discussed (moved to top)
                if (traitsDiscussed.isNotEmpty) ...[
                  _buildLogSection(
                    title: 'Immunity Traits Discussed:',
                    content: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: traitsDiscussed
                          .map((trait) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF98E4D6).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF98E4D6), width: 1),
                                ),
                                child: Text(
                                  trait.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Primary Concerns
                if (primaryConcerns.isNotEmpty) ...[
                  _buildLogSection(
                    title: 'Primary Concerns:',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: primaryConcerns
                          .map((concern) => Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(
                                        concern.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: 14,
                                          color: Color(0xFF555555),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  _buildLogSection(
                    title: 'Primary Concerns:',
                    content: Text(
                      'No primary concerns were extracted from the conversation.',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: Colors.orange[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Immediate Recommendations (from raw field)
                if (immediateRecommendations.isNotEmpty) ...[
                  _buildLogSection(
                    title: '✅ What You Can Do Right Now:',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: immediateRecommendations
                          .map((rec) => Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(
                                        rec.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: 14,
                                          color: Color(0xFF555555),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Questions for Doctor
                if (questionsForDoctor.isNotEmpty) ...[
                  _buildLogSection(
                    title: 'Questions for Doctor:',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: questionsForDoctor
                          .map((question) => Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(
                                        question.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: 14,
                                          color: Color(0xFF555555),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  _buildLogSection(
                    title: 'Questions for Doctor:',
                    content: Text(
                      'No questions for doctor were generated from the conversation.',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: Colors.orange[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Emergency Indicators
                if (emergencyIndicators.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '⚠️ Emergency Indicators:',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...emergencyIndicators
                            .map((indicator) => Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16, color: Colors.red[800])),
                                      Expanded(
                                        child: Text(
                                          indicator.toString(),
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 14,
                                            color: Colors.red[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                ],
              ], // End of expanded content
            ],
          ),
        ),
    );
  }

  Widget _buildLogSection({required String title, required Widget content}) {
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
        content,
      ],
    );
  }

}