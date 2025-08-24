import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/utils/logger.dart';

class LatestRecommendationsDetailScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const LatestRecommendationsDetailScreen({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);

  @override
  _LatestRecommendationsDetailScreenState createState() => _LatestRecommendationsDetailScreenState();
}

class _LatestRecommendationsDetailScreenState extends State<LatestRecommendationsDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _loadLatestRecommendationsDetail();
  }

  Future<void> _loadLatestRecommendationsDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await ApiService.getLatestRecommendationsDetail(widget.childId);
      
      // Debug logging to see the actual data structure
      AppLogger.info('Latest recommendations detail data: ${data.toString()}');
      if (data['recommendations'] != null && (data['recommendations'] as List).isNotEmpty) {
        AppLogger.info('First recommendation structure: ${data['recommendations'][0]}');
      }
      
      setState(() {
        _detailData = data;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load latest recommendations detail: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF4EA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF717070)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '📋 Latest Recommendations',
          style: TextStyle(
            color: Color(0xFF717070),
            fontSize: 20,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoadingState() : _error != null ? _buildErrorState() : _buildDetailView(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading latest recommendations...',
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
              'Failed to load recommendations',
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
              onPressed: _loadLatestRecommendationsDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
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

  Widget _buildDetailView() {
    if (_detailData == null) return Container();

    final recommendations = _detailData!['recommendations'] as List<dynamic>? ?? [];
    final childName = _detailData!['child_name'] ?? widget.childName;
    final lastCheckInDate = _detailData!['last_check_in_date'] != null 
        ? DateTime.tryParse(_detailData!['last_check_in_date'])?.toLocal().toString().split(' ')[0] ?? 'N/A'
        : 'N/A';
    final entryType = _detailData!['entry_type'] ?? 'checkin';

    if (recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Recent Recommendations',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF717070),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete a weekly check-in to get personalized recommendations for $childName.',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  color: Color(0xFF999999),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              border: Border.all(color: const Color(0xFF667eea), width: 2),
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
              children: [
                Text(
                  '$childName\'s Latest Recommendations',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667eea),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entryType == 'initial' ? Icons.star : Icons.update,
                      color: const Color(0xFF999999),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entryType == 'initial' 
                          ? 'Initial Assessment • $lastCheckInDate'
                          : 'Weekly Check-in • $lastCheckInDate',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Recommendations List
          const Text(
            '🎯 Personalized Activities',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF717070),
            ),
          ),
          const SizedBox(height: 15),
          
          ...recommendations.map((rec) => _buildRecommendationCard(rec)),
          
          const SizedBox(height: 30),
          
          // Call to action
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  '💡 Keep tracking progress!',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete weekly check-ins to get updated recommendations based on your child\'s development.',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    color: Color(0xFF6B4423),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to dashboard
                    // TODO: Navigate to check-in from dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Start Weekly Check-in',
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
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(dynamic recommendation) {
    final recMap = recommendation as Map<String, dynamic>? ?? {};
    // Handle both 'trait_name' and 'trait' field names for compatibility
    final traitName = recMap['trait_name'] ?? recMap['trait'] ?? 'Unknown Trait';
    final geneId = recMap['gene_id'] ?? '';
    final goal = recMap['goal'] ?? '';
    final activity = recMap['activity'] ?? '';
    // Handle both 'tldr' and 'action' field names
    final tldr = recMap['tldr'] ?? recMap['action'] ?? 'No summary available';
    final frequency = recMap['frequency'] ?? '';
    final duration = recMap['duration'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5E9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trait header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  traitName,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (geneId.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '($geneId)',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // TLDR Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🎯 $tldr',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Goal
          if (goal.isNotEmpty) ...[
            const Text(
              'Goal:',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              goal,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Activity
          if (activity.isNotEmpty) ...[
            const Text(
              'Recommended Activity:',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activity,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Frequency and Duration
          if (frequency.isNotEmpty || duration.isNotEmpty) ...[
            Row(
              children: [
                if (frequency.isNotEmpty) ...[
                  const Icon(Icons.schedule, size: 16, color: Color(0xFF999999)),
                  const SizedBox(width: 4),
                  Text(
                    frequency,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
                if (frequency.isNotEmpty && duration.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Text('•', style: TextStyle(color: Color(0xFF999999))),
                  const SizedBox(width: 16),
                ],
                if (duration.isNotEmpty) ...[
                  const Icon(Icons.timer, size: 16, color: Color(0xFF999999)),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}