import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/validators.dart';
import 'register_screen.dart';
import '../child_selector_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
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

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent entire UI from moving up
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bloomie_background2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside
              FocusScope.of(context).unfocus();
            },
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 24.0,
                            right: 24.0,
                            top: 24.0,
                            bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                                ? MediaQuery.of(context).viewInsets.bottom + 24 // Add padding when keyboard is open
                                : 24.0,
                          ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Bloomie Logo
                              Container(
                                width: MediaQuery.of(context).size.width * 0.6, // Responsive width
                                height: MediaQuery.of(context).size.height * 0.15, // Responsive height
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                  maxHeight: 160,
                                ),
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('assets/images/bloomie_icon.png'),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
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
                                hint: 'Enter your password',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline,
                                validator: (value) => Validators.required(value, fieldName: 'Password'),
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
                              
                              // Login Button
                              CustomButton(
                                text: 'Login',
                                onPressed: authProvider.isLoading ? null : _handleLogin,
                                width: double.infinity,
                                isLoading: authProvider.isLoading,
                                backgroundColor: AppColors.primary,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Register Button
                              CustomButton(
                                text: 'Create Account',
                                onPressed: authProvider.isLoading ? null : _navigateToRegister,
                                width: double.infinity,
                                backgroundColor: Colors.grey.shade400,
                                textColor: Colors.white,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Sample Account Info
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200.withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sample Account:',
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Email: ray@mail.com\nPassword: Password1',
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 13,
                                        color: Colors.blue.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            ),
          ),
        ),
      ),
    );
  }
}