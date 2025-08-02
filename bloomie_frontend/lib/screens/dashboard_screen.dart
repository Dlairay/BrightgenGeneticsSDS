import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/widgets/custom_button.dart';
import '../models/auth_models.dart';
import 'dynamic_questionnaire_screen.dart';
import 'upload_genetic_report_screen.dart';
import 'auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Don't automatically refresh - just show the dashboard
  }

  Future<void> _refreshUserData() async {
    // Only refresh when user explicitly requests it
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserData();
  }

  void _startCheckIn(String childId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicQuestionnaireScreen(childId: childId),
      ),
    );
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
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
            if (authProvider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your dashboard...'),
                  ],
                ),
              );
            }

            final user = authProvider.currentUser;
            if (user == null) {
              return const Center(child: Text('No user data available'));
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user info and logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👶 Your Children',
                            style: AppTextStyles.h1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back, ${user.name}!',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Children List
                  Expanded(
                    child: _buildChildrenList(user.children),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChildrenList(List<Child> children) {
    if (children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No children added yet',
              style: AppTextStyles.h3.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first child to get started with personalized recommendations!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Add New Child',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadGeneticReportScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        return _buildChildCard(child);
      },
    );
  }

  Widget _buildChildCard(Child child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardPink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
          // Child Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name.isEmpty ? 'Child ${child.id}' : child.name,
                      style: AppTextStyles.h3,
                    ),
                    if (child.gender != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Gender: ${child.gender}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                    if (child.birthday != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Birthday: ${child.birthday}',
                        style: AppTextStyles.bodySmall,
                      ),
                      if (child.ageInMonths != null) ...[
                        Text(
                          'Age: ${child.ageInMonths} months',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons (matching frontend.html dashboard)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                'Weekly Check-in',
                Icons.quiz,
                AppColors.primary,
                () => _startCheckIn(child.id),
              ),
              _buildActionButton(
                'Upload Genetic Report',
                Icons.upload_file,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadGeneticReportScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                'View Traits',
                Icons.psychology,
                Colors.blue,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Traits feature coming soon!'),
                    ),
                  );
                },
              ),
              _buildActionButton(
                'Consult Dr. Bloom',
                Icons.medical_services,
                Colors.green,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dr. Bloom consultation coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}