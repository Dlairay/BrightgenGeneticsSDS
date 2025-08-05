import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';
import '../core/utils/logger.dart';
import '../core/utils/no_animation_route.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'traits_screen.dart';

class UploadGeneticReportScreen extends StatefulWidget {
  final bool isFirstChild;
  
  const UploadGeneticReportScreen({
    super.key,
    this.isFirstChild = false,
  });

  @override
  State<UploadGeneticReportScreen> createState() => _UploadGeneticReportScreenState();
}

class _UploadGeneticReportScreenState extends State<UploadGeneticReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childNameController = TextEditingController();
  
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;
  
  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }
  
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'json'],
        withData: false, // We'll use the path
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = result.files.single;
          _errorMessage = null;
        });
        AppLogger.info('File selected: ${_selectedFile!.name}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: ${e.toString()}';
      });
      AppLogger.error('File picker error', error: e);
    }
  }
  
  Future<void> _uploadReport() async {
    AppLogger.info('Upload attempt started');
    AppLogger.info('Form valid: ${_formKey.currentState!.validate()}');
    AppLogger.info('Selected file path: ${_selectedFile?.path}');
    AppLogger.info('Child name: ${_childNameController.text.trim()}');
    
    if (!_formKey.currentState!.validate() || _selectedFile?.path == null) {
      setState(() {
        _errorMessage = 'Please provide child name and select a file';
      });
      AppLogger.error('Upload validation failed');
      return;
    }
    
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      AppLogger.info('Uploading genetic report: ${_selectedFile!.name}');
      
      final result = await ApiService.uploadGeneticReport(
        _selectedFile!.path!,
        _childNameController.text.trim(),
      );
      
      setState(() {
        _isUploading = false;
        _successMessage = 'Child added successfully!';
      });
      
      AppLogger.info('Upload successful: ${result.toString()}');
      
      // Refresh children list and select the newly created child
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserData();
      
      // Find and select the newly created child by ID from the upload response
      if (result['child_id'] != null) {
        final newChildId = result['child_id'];
        final newChild = authProvider.children.firstWhere(
          (child) => child.id == newChildId,
          orElse: () => authProvider.children.isNotEmpty ? authProvider.children.first : throw Exception('No child found'),
        );
        authProvider.selectChild(newChild);
        AppLogger.info('Selected new child: ${newChild.name} (${newChild.id})');
      }
      
      // Show success and navigate after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        if (widget.isFirstChild) {
          // Navigate to traits screen for first child
          final childId = result['child_id'] ?? '';
          Navigator.of(context).pushReplacement(
            NoAnimationPageRoute(builder: (context) => TraitsScreen(childId: childId)),
          );
        } else {
          // Navigate back to dashboard for additional children
          Navigator.of(context).pushReplacement(
            NoAnimationPageRoute(builder: (context) => const Dashboard()),
          );
        }
      }
      
    } catch (e) {
      setState(() {
        _isUploading = false;
        // Show the actual server error message instead of generic message
        _errorMessage = e.toString();
      });
      AppLogger.error('Upload failed', error: e);
    }
  }
  
  void _navigateBack() {
    Navigator.of(context).pushReplacement(
      NoAnimationPageRoute(builder: (context) => const Dashboard()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
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
                      child: Text(
                        '➕ Add New Child',
                        style: AppTextStyles.h1,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Child Name Field
                Text(
                  'Child\'s Name',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: 'Enter child\'s name',
                  controller: _childNameController,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.child_care,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter child\'s name';
                    }
                    return null;
                  },
                  enabled: !_isUploading,
                ),
                
                const SizedBox(height: 24),
                
                // File Upload Section (matching frontend.html design)
                Text(
                  'Genetic Report (JSON or PDF)',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _selectedFile != null 
                          ? AppColors.withOpacity(AppColors.primary, 0.1)
                          : Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        _selectedFile != null 
                            ? Icon(
                                Icons.check_circle,
                                size: 48,
                                color: Colors.green,
                              )
                            : Image.asset(
                                'assets/images/uploadfiles.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFile != null 
                              ? 'Selected: ${_selectedFile!.name}'
                              : 'Click to upload genetic report (JSON or PDF)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedFile != null ? Colors.green : AppColors.textGray,
                            fontWeight: _selectedFile != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Size: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Error/Success Messages
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (_successMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const Spacer(),
                
                // Action Buttons
                Column(
                  children: [
                    CustomButton(
                      text: 'Add Child',
                      onPressed: (_isUploading || _selectedFile == null) ? null : _uploadReport,
                      width: double.infinity,
                      isLoading: _isUploading,
                      backgroundColor: AppColors.primary,
                    ),
                    
                    // Only show back button if this is not the first child
                    if (!widget.isFirstChild) ...[
                      const SizedBox(height: 16),
                      
                      CustomButton(
                        text: 'Back to Dashboard',
                        onPressed: _isUploading ? null : _navigateBack,
                        width: double.infinity,
                        backgroundColor: Colors.grey.shade400,
                        textColor: Colors.white,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}