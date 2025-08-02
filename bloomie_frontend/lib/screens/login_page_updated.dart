import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';
import '../core/utils/validators.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class LoginPageUpdated extends StatefulWidget {
  const LoginPageUpdated({super.key});

  @override
  State<LoginPageUpdated> createState() => _LoginPageUpdatedState();
}

class _LoginPageUpdatedState extends State<LoginPageUpdated> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      await provider.login(_emailController.text, _passwordController.text);
      
      if (provider.isAuthenticated && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AppStateProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome Back',
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 40),
                    
                    CustomTextField(
                      hint: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      hint: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: Icons.lock,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 24),
                    
                    if (provider.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    CustomButton(
                      text: 'Login',
                      onPressed: _handleLogin,
                      width: double.infinity,
                      isLoading: provider.isLoading,
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