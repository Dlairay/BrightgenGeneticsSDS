import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';
import '../core/utils/logger.dart';
import 'single_child_dashboard.dart';

class UploadGeneticReportScreen extends StatefulWidget {
  const UploadGeneticReportScreen({super.key});

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
    if (!_formKey.currentState!.validate() || _selectedFile?.path == null) {
      setState(() {
        _errorMessage = 'Please provide child name and select a file';
      });
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
      
      // Show success and navigate back after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SingleChildDashboard()),
        );
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
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                          size: 48,
                          color: _selectedFile != null ? Colors.green : AppColors.primary,
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
                    
                    const SizedBox(height: 16),
                    
                    CustomButton(
                      text: 'Back to Dashboard',
                      onPressed: _isUploading ? null : _navigateBack,
                      width: double.infinity,
                      backgroundColor: Colors.grey.shade400,
                      textColor: Colors.white,
                    ),
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