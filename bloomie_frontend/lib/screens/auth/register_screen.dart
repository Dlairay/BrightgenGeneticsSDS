import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/validators.dart';
import '../child_selector_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChildSelectorScreen()),
        );
      }
    }
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: _navigateBack,
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.cardOrange,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Bloomie Logo
                    Container(
                      width: 200,
                      height: 80,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/bloomie_icon.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Welcome Text
                    Text(
                      'Bloomie🌸',
                      style: AppTextStyles.h1.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create Account',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Name Field
                    CustomTextField(
                      hint: 'Enter your full name',
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      prefixIcon: Icons.person_outline,
                      validator: (value) => Validators.required(value, fieldName: 'Name'),
                      enabled: !authProvider.isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email Field
                    CustomTextField(
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: Validators.email,
                      enabled: !authProvider.isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password Field
                    CustomTextField(
                      hint: 'Create a password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      validator: Validators.password,
                      enabled: !authProvider.isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Error Message
                    if (authProvider.errorMessage != null) ...[
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
                                authProvider.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: authProvider.clearError,
                              icon: Icon(Icons.close, color: Colors.red.shade600, size: 16),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Register Button
                    CustomButton(
                      text: 'Create Account',
                      onPressed: authProvider.isLoading ? null : _handleRegister,
                      width: double.infinity,
                      isLoading: authProvider.isLoading,
                      backgroundColor: AppColors.primary,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Back to Login Button
                    CustomButton(
                      text: 'Back to Login',
                      onPressed: authProvider.isLoading ? null : _navigateBack,
                      width: double.infinity,
                      backgroundColor: Colors.grey.shade400,
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}