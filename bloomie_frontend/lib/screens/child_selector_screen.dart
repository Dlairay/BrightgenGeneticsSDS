import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/auth_models.dart';
import 'upload_genetic_report_screen.dart';
import '../main.dart';
import 'auth/login_screen.dart';
import '../core/utils/no_animation_route.dart';

class ChildSelectorScreen extends StatelessWidget {
  final bool showWelcomeBack;
  
  const ChildSelectorScreen({
    super.key, 
    this.showWelcomeBack = false,
  });

  void _selectChild(BuildContext context, Child child) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.selectChild(child);
    
    // Navigate back to dashboard with selected child
    Navigator.of(context).pushReplacement(
      NoAnimationPageRoute(builder: (context) => const Dashboard()),
    );
  }

  void _addNewChild(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isFirstChild = authProvider.children.isEmpty;
    
    Navigator.push(
      context,
      NoAnimationPageRoute(
        builder: (context) => UploadGeneticReportScreen(isFirstChild: isFirstChild),
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bloomie_background3.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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
                      if (showWelcomeBack) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back, ${user.name}',
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Children List (Netflix-style with + button)
                  Expanded(
                    child: authProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : authProvider.children.isEmpty
                            ? _buildNoChildrenView(context)
                            : _buildChildrenGridWithAddButton(context, authProvider.children, selectedChild),
                  ),
                  
                  // Bottom buttons (Settings and Logout)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Settings button
                        GestureDetector(
                          onTap: () {
                            // Settings functionality to be implemented later
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/images/setting_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 30),
                        
                        // Logout button
                        GestureDetector(
                          onTap: () => _logout(context),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.logout,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          ),
        ),
      ),
    );
  }

  Widget _buildNoChildrenView(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Only auto-redirect if we truly have no children AND no selected child
    // If we have a selected child but empty children list, it's a data loading issue
    if (authProvider.selectedChild == null && authProvider.children.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          NoAnimationPageRoute(builder: (context) => const UploadGeneticReportScreen(isFirstChild: true)),
        );
      });
      
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // We have a selected child but children list is empty - data loading issue
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Loading children data...',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await authProvider.forceRefresh();
              },
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                NoAnimationPageRoute(builder: (context) => const Dashboard()),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      );
    }
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
              color: AppColors.withOpacity(Colors.black, 0.05),
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
          color: isSelected ? AppColors.withOpacity(AppColors.primary, 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.withOpacity(Colors.black, 0.05),
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

}