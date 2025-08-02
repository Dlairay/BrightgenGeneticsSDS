import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/logger.dart';
import 'single_child_dashboard.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _childName = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendationsHistory();
  }

  void _loadChildName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final child = authProvider.selectedChild;
    _childName = child?.name ?? 'Child';
  }

  Future<void> _loadRecommendationsHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final selectedChild = authProvider.selectedChild;

      if (selectedChild == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No child selected';
        });
        return;
      }

      _childName = selectedChild.name;

      AppLogger.info('Loading recommendations history for child: ${selectedChild.id}');
      final historyData = await ApiService.getRecommendationsHistory(selectedChild.id);

      setState(() {
        _history = historyData.reversed.toList(); // Show newest first like frontend.html
        _isLoading = false;
      });

      AppLogger.info('Loaded ${_history.length} history entries');

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      AppLogger.error('Failed to load recommendations history', error: e);
    }
  }

  void _navigateBack() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SingleChildDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: _navigateBack,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cardOrange,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Development History',
                          style: AppTextStyles.h1,
                        ),
                        Text(
                          'For $_childName',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading history...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRecommendationsHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No history yet',
              style: AppTextStyles.h2.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete questionnaires and Dr. Bloom consultations to see development insights here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // History count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_history.length} entries found',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // History list
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final entry = _history[index];
              return _buildHistoryCard(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final isDrBloom = entry['entry_type'] == 'dr_bloom';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDrBloom ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isDrBloom ? 2 : 1,
        ),
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
          // Header row
          Row(
            children: [
              // Type icon and title
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isDrBloom ? Icons.medical_services : Icons.assignment,
                      color: isDrBloom ? Colors.blue.shade600 : Colors.orange.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isDrBloom ? '🩺 Dr. Bloom Consultation' : '📝 Weekly Check-in',
                        style: AppTextStyles.h3.copyWith(
                          color: isDrBloom ? Colors.blue.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Date
              Text(
                _formatDate(entry['created_at']),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content based on type
          if (isDrBloom) ...[
            _buildDrBloomContent(entry),
          ] else ...[
            _buildCheckInContent(entry),
          ],
        ],
      ),
    );
  }

  Widget _buildDrBloomContent(Map<String, dynamic> entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        if (entry['summary'] != null) ...[
          Text(
            'Summary',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry['summary'],
            style: AppTextStyles.body.copyWith(
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Recommendations
        if (entry['recommendations'] != null && (entry['recommendations'] as List).isNotEmpty) ...[
          Text(
            'Recommendations',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...(entry['recommendations'] as List).map((rec) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rec['trait'] != null) ...[
                  Text(
                    rec['trait'],
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (rec['goal'] != null) ...[
                  Text(
                    'Goal: ${rec['goal']}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                if (rec['activity'] != null) ...[
                  Text(
                    'Activity: ${rec['activity']}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildCheckInContent(Map<String, dynamic> entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommendations for check-in
        if (entry['recommendations'] != null && (entry['recommendations'] as List).isNotEmpty) ...[
          Text(
            'Developmental Recommendations',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...(entry['recommendations'] as List).map((rec) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rec['trait'] != null) ...[
                  Text(
                    rec['trait'],
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (rec['goal'] != null) ...[
                  Text(
                    'Goal: ${rec['goal']}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                if (rec['activity'] != null) ...[
                  Text(
                    'Activity: ${rec['activity']}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          )),
        ],
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}