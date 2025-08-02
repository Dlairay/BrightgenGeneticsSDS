import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/auth_models.dart';
import 'upload_genetic_report_screen.dart';
import 'single_child_dashboard.dart';
import 'auth/login_screen.dart';

class ChildSelectorScreen extends StatelessWidget {
  const ChildSelectorScreen({super.key});

  void _selectChild(BuildContext context, Child child) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.selectChild(child);
    
    // Navigate back to dashboard with selected child
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SingleChildDashboard()),
    );
  }

  void _addNewChild(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadGeneticReportScreen(),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
            final selectedChild = authProvider.selectedChild;
            
            if (user == null) {
              return const Center(child: Text('No user data available'));
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Netflix-style)
                  Column(
                    children: [
                      // Bloomie Logo
                      Container(
                        width: 200,
                        height: 60,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/bloomie_icon.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        authProvider.children.isEmpty 
                            ? 'Welcome to Bloomie!'
                            : 'Who\'s using Bloomie?',
                        style: AppTextStyles.h1.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome back, ${user.name}',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Children List (Netflix-style with + button)
                  Expanded(
                    child: authProvider.children.isEmpty
                        ? _buildNoChildrenView(context)
                        : _buildChildrenGridWithAddButton(context, authProvider.children, selectedChild),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoChildrenView(BuildContext context) {
    // If no children, automatically redirect to add child screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UploadGeneticReportScreen()),
      );
    });
    
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildChildrenGridWithAddButton(BuildContext context, List<Child> children, Child? selectedChild) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Changed from 3 to 2 for more space
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0, // Changed from 0.8 to 1.0 for better proportions
      ),
      itemCount: children.length + 1, // +1 for the add button
      itemBuilder: (context, index) {
        // Last item is the + button
        if (index == children.length) {
          return _buildAddChildButton(context);
        }
        
        final child = children[index];
        final isSelected = selectedChild?.id == child.id;
        
        return _buildChildCard(context, child, isSelected);
      },
    );
  }

  Widget _buildAddChildButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _addNewChild(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, // Match child avatar size
              height: 60, // Match child avatar size
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 30, // Reduced from 40
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8), // Match child card spacing
            Text(
              'Add Child',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, Child child, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectChild(context, child),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Child Avatar
              Container(
                width: 60, // Reduced from 80
                height: 60, // Reduced from 80
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontSize: 24, // Reduced from 32
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8), // Reduced from 16
              
              // Child Name
              Text(
                child.name.isEmpty ? 'Child ${child.id}' : child.name,
                style: AppTextStyles.bodySmall.copyWith( // Changed from h3 to bodySmall
                  color: isSelected ? AppColors.primary : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Simplified info - only show age if available
              if (child.ageInMonths != null) ...[
                const SizedBox(height: 4), // Reduced spacing
                Text(
                  '${child.ageInMonths}mo',
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              if (isSelected) ...[
                const SizedBox(height: 6), // Reduced spacing
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SELECTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8, // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenGrid(BuildContext context, List<Child> children, Child? selectedChild) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        final isSelected = selectedChild?.id == child.id;
        
        return GestureDetector(
          onTap: () => _selectChild(context, child),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Child Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Child Name
                  Text(
                    child.name.isEmpty ? 'Child ${child.id}' : child.name,
                    style: AppTextStyles.h3.copyWith(
                      color: isSelected ? AppColors.primary : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Child Info
                  if (child.ageInMonths != null) ...[
                    Text(
                      '${child.ageInMonths} months old',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.primary : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (child.birthday != null) ...[
                    Text(
                      'Born: ${child.birthday}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  if (child.gender != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      child.gender!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  if (isSelected) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SELECTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}