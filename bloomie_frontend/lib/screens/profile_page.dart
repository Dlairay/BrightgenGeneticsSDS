import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/widgets/persistent_bottom_nav.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFFFB366),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bloomie_background3.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(_getChildProfileImage(authProvider.selectedChild?.name)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${authProvider.selectedChild?.name ?? 'Child'}\'s Profile',
                          style: const TextStyle(fontSize: 24, fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Manage profile settings',
                          style: TextStyle(fontSize: 16, fontFamily: 'Fredoka'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Persistent bottom navigation
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return PersistentBottomNav(
                  currentChildId: authProvider.selectedChild?.id ?? 'default_child',
                  currentChildName: authProvider.selectedChild?.name ?? 'Child',
                  selectedIndex: 2, // Profile is selected
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to map child names to profile images
  String _getChildProfileImage(String? childName) {
    if (childName == null) return 'assets/images/default_child.png';
    
    // Hard-coded mapping for now - can be extended later
    switch (childName.toLowerCase()) {
      case 'amy':
        return 'assets/images/babyamy.jpg';
      case 'emma':
        return 'assets/images/babyemma.jpg';
      case 'lucas':
        return 'assets/images/babylucas.jpg';
      case 'sophia':
        return 'assets/images/babysophia.jpg';
      case 'noah':
        return 'assets/images/babynoah.jpg';
      case 'olivia':
        return 'assets/images/babyolivia.jpg';
      case 'nigolas':
        return 'assets/images/babyamy.jpg'; // Using Amy's image for Nigolas for now
      default:
        return 'assets/images/babyamy.jpg'; // Default to Amy's image
    }
  }
}