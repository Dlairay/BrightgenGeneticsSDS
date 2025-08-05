import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/dr_bloom_chat_screen.dart';
import '../../screens/child_selector_screen.dart';
import '../../main.dart';
import '../constants/app_colors.dart';
import '../utils/no_animation_route.dart';

class PersistentBottomNav extends StatelessWidget {
  final String? currentChildId;
  final String? currentChildName;
  final int selectedIndex;

  const PersistentBottomNav({
    super.key,
    this.currentChildId,
    this.currentChildName,
    this.selectedIndex = 1, // Default to home
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final selectedChild = authProvider.selectedChild;
        final childId = currentChildId ?? selectedChild?.id ?? 'default_child';
        final childName = currentChildName ?? selectedChild?.name ?? 'Child';

        return Container(
          height: 70 + MediaQuery.of(context).padding.bottom,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4E3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 6,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(
                  context: context,
                  iconPath: 'assets/images/drbloom.png',
                  label: 'Dr. Bloom',
                  color: const Color(0xFF4CAF50),
                  isSelected: selectedIndex == 0,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    NoAnimationPageRoute(
                      builder: (context) => DrBloomChatScreen(
                        childId: childId,
                        childName: childName,
                      ),
                    ),
                  ),
                ),
                _buildNavButton(
                  context: context,
                  iconPath: 'assets/images/home.png',
                  label: 'Home',
                  color: const Color(0xFF667eea),
                  isSelected: selectedIndex == 1,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    NoAnimationPageRoute(
                      builder: (context) => const Dashboard(),
                    ),
                  ),
                ),
                _buildNavButton(
                  context: context,
                  iconPath: 'assets/images/profile.png',
                  label: 'Profile',
                  color: const Color(0xFFFFB74D),
                  isSelected: selectedIndex == 2,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    NoAnimationPageRoute(
                      builder: (context) => const ChildSelectorScreen(
                        showWelcomeBack: false, // Don't show welcome when coming from navbar
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required String iconPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Image.asset(
              iconPath,
              width: 32,
              height: 32,
              color: AppColors.withOpacity(color, 0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.withOpacity(color, 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}