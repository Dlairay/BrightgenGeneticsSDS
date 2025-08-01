import 'package:flutter/material.dart';
import 'gensumdetailed.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFFFAF4EA),
      ),
      home: Scaffold(
        body: ListView(children: [
          UploadDocs(),
        ]),
      ),
    );
  }
}

class UploadDocs extends StatefulWidget {
  @override
  _UploadDocsState createState() => _UploadDocsState();
}

class _UploadDocsState extends State<UploadDocs> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller for rotation
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000), // 1 second per rotation step
      vsync: this,
    );
    
    // Create rotation animation that rotates in steps (like footsteps)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // Quarter turn (90 degrees) per step
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start the repeating animation
    _startRotationAnimation();
    
    // Navigate to detailed summary after 5 seconds of loading
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GeneticsSummaryPage()),
        );
      }
    });
  }

  void _startRotationAnimation() {
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        _animationController.forward();
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
              
              // Rotating footstep loading animation
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 90, // Center horizontally on screen
                top: MediaQuery.of(context).size.height / 2 - 90, // Center vertically on screen
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/footstep.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // "Generating summary..." text overlay - centered
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height / 2 + 120, // Below the footsteps
                child: Text(
                  'Generating summary...',
                  style: TextStyle(
                    color: Color(0xFFFF8C42),
                    fontSize: 24,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}