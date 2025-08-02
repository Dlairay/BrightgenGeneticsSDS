import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/trait_models.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/logger.dart';
import 'single_child_dashboard.dart';

class TraitsScreen extends StatefulWidget {
  final String childId;
  
  const TraitsScreen({
    super.key,
    required this.childId,
  });

  @override
  State<TraitsScreen> createState() => _TraitsScreenState();
}

class _TraitsScreenState extends State<TraitsScreen> {
  List<GeneticTrait> _traits = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _childName = '';
  
  @override
  void initState() {
    super.initState();
    _loadChildName();
    _loadTraits();
  }
  
  void _loadChildName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final child = authProvider.getChildById(widget.childId);
    _childName = child?.name ?? 'Child';
  }
  
  Future<void> _loadTraits() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      AppLogger.info('Loading traits for child: ${widget.childId}');
      final traitsData = await ApiService.getChildTraits(widget.childId);
      
      setState(() {
        _traits = traitsData.map((trait) => GeneticTrait.fromJson(trait)).toList();
        _isLoading = false;
      });
      
      AppLogger.info('Loaded ${_traits.length} traits');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      AppLogger.error('Failed to load traits', error: e);
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
                          'Genetic Traits Report',
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
            Text('Loading genetic traits...'),
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
              'Failed to load traits',
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
              onPressed: _loadTraits,
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
    
    if (_traits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No genetic traits found',
              style: AppTextStyles.h2.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a genetic report to see trait analysis for $_childName.',
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
        // Traits count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_traits.length} genetic traits found',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Traits list
        Expanded(
          child: ListView.builder(
            itemCount: _traits.length,
            itemBuilder: (context, index) {
              final trait = _traits[index];
              return _buildTraitCard(trait);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTraitCard(GeneticTrait trait) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
          // Trait name (header)
          Text(
            trait.traitName,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Gene info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Gene: ${trait.gene}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Confidence as progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Confidence',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          trait.confidence,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _parseConfidenceValue(trait.confidence),
                      backgroundColor: Colors.green.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConfidenceColor(trait.confidence),
                      ),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            trait.description,
            style: AppTextStyles.body.copyWith(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to parse confidence value to a double (0.0 to 1.0)
  double _parseConfidenceValue(String confidence) {
    // Handle different confidence formats
    final cleanedConfidence = confidence.toLowerCase().replaceAll('%', '').trim();
    
    // Try to parse as percentage (e.g., "85%" -> 0.85)
    if (confidence.contains('%')) {
      try {
        final percentage = double.parse(cleanedConfidence);
        return percentage / 100.0;
      } catch (e) {
        // If parsing fails, try other formats
      }
    }
    
    // Try to parse as decimal (e.g., "0.85" -> 0.85)
    try {
      final decimal = double.parse(cleanedConfidence);
      if (decimal <= 1.0) {
        return decimal;
      } else if (decimal <= 100.0) {
        // Assume it's a percentage without % symbol
        return decimal / 100.0;
      }
    } catch (e) {
      // If parsing fails, try text-based confidence
    }
    
    // Handle text-based confidence levels
    switch (cleanedConfidence) {
      case 'very high':
      case 'high':
        return 0.9;
      case 'medium-high':
        return 0.75;
      case 'medium':
        return 0.6;
      case 'medium-low':
        return 0.45;
      case 'low':
        return 0.3;
      case 'very low':
        return 0.15;
      default:
        return 0.5; // Default to 50% if unable to parse
    }
  }
  
  // Helper method to get color based on confidence level
  Color _getConfidenceColor(String confidence) {
    final value = _parseConfidenceValue(confidence);
    
    if (value >= 0.8) {
      return Colors.green; // High confidence - green
    } else if (value >= 0.6) {
      return Colors.lightGreen; // Medium-high confidence - light green
    } else if (value >= 0.4) {
      return Colors.orange; // Medium confidence - orange
    } else {
      return Colors.red; // Low confidence - red
    }
  }
}