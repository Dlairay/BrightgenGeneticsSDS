import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int currentStep = 1; // 1 = Initial, 2 = Particulars, 3 = OTP, 4 = Success
  bool _isHoveringButton = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  void _proceedToNextStep() {
    if (currentStep == 1) {
      // Initial sign up - go to particulars
      setState(() {
        currentStep = 2;
      });
    } else if (currentStep == 2) {
      // Validate sign up particulars
      if (nameController.text.isNotEmpty && 
          emailController.text.isNotEmpty && 
          phoneController.text.isNotEmpty && 
          passwordController.text.isNotEmpty) {
        setState(() {
          currentStep = 3; // Go to OTP
        });
      } else {
        _showValidationError('Please fill in all fields');
      }
    } else if (currentStep == 3) {
      // Verify OTP
      if (otpController.text.length == 6) {
        setState(() {
          currentStep = 4; // Success
        });
      } else {
        _showValidationError('Please enter a valid 6-digit OTP');
      }
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToLogin() {
    // Navigate back to login page
    Navigator.pop(context);
  }

  String _getSubtitle() {
    if (currentStep == 3) return 'OTP Verification';
    return 'Create and account with email to login from anywhere.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bloomie_background.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Center(
          child: SafeArea(
            child: Container(
              width: 280,
              height: 660,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Title
                  SizedBox(
                    height: 40,
                    child: Text(
                      'Let\'s Get Started',
                      style: TextStyle(
                        color: Color(0xFF717070),
                        fontSize: 25,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Bloomie logo
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    width: 248,
                    height: 62,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/bloomie_icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Subtitle
                  Text(
                    _getSubtitle(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF717070),
                      fontSize: 15,
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Conditional content based on current step
                  if (currentStep == 1) ..._buildInitialStep(),
                  if (currentStep == 2) ..._buildParticularsStep(),
                  if (currentStep == 3) ..._buildOTPStep(),
                  if (currentStep == 4) ..._buildSuccessStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInitialStep() {
    return [
      // Name field
      _buildInputField('Name', Color(0xFFFDE5BE), false, nameController, Icons.person),
      
      // Email field
      _buildInputField('Email Address', Color(0xFFFDE6BE), false, emailController, Icons.email),
      
      // Phone field
      _buildInputField('Handphone Number', Color(0xFFFDE6BE), false, phoneController, Icons.phone),
      
      // Password field
      _buildInputField('Password', Color(0xFFFDE6BE), true, passwordController, Icons.lock),
      
      const SizedBox(height: 30),
      
      // Create account button
      _buildActionButton('Create account', _proceedToNextStep),
      
      const SizedBox(height: 40),
      
      // Login text
      Text(
        "Already have an account?",
        style: const TextStyle(
          color: Color(0xFF727272),
          fontSize: 10,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w400,
        ),
      ),
      GestureDetector(
        onTap: _navigateToLogin,
        child: Text(
          'Click here to log in.',
          style: const TextStyle(
            color: Color(0xFF727272),
            fontSize: 10,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF727272),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildParticularsStep() {
    return [
      // Pre-filled Name field
      _buildInputField('Name', Color(0xFFFDE5BE), false, nameController, Icons.person),
      
      // Pre-filled Email field
      _buildInputField('Email Address', Color(0xFFFDE6BE), false, emailController, Icons.email),
      
      // Pre-filled Phone field
      _buildInputField('Handphone Number', Color(0xFFFDE6BE), false, phoneController, Icons.phone),
      
      // Password field with dots (obscured)
      _buildInputField('Password', Color(0xFFFDE6BE), true, passwordController, Icons.lock),
      
      const SizedBox(height: 30),
      
      // Create account button
      _buildActionButton('Create account', _proceedToNextStep),
      
      const SizedBox(height: 40),
      
      // Login text
      Text(
        "Already have an account?",
        style: const TextStyle(
          color: Color(0xFF727272),
          fontSize: 10,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w400,
        ),
      ),
      GestureDetector(
        onTap: _navigateToLogin,
        child: Text(
          'Click here to log in.',
          style: const TextStyle(
            color: Color(0xFF727272),
            fontSize: 10,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF727272),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildOTPStep() {
    return [
      // Phone number display (filled from previous step)
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 280,
        height: 50,
        child: TextField(
          controller: phoneController,
          enabled: false,
          style: TextStyle(
            color: Color(0xFF828282),
            fontSize: 15,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFFFDE6BE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          ),
        ),
      ),
      
      const SizedBox(height: 10),
      
      // OTP instruction text
      const Text(
        'Type in 6 digit OTP sent to number',
        style: TextStyle(
          color: Color(0xFF727272),
          fontSize: 12,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w400,
        ),
      ),
      
      const SizedBox(height: 20),
      
      // OTP input field with dot placeholders
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 254,
        height: 50,
        child: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF828282),
            fontSize: 18,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFFFDE6BE),
            hintText: '••••••',
            hintStyle: TextStyle(
              color: Color(0xFF939393),
              fontSize: 18,
              letterSpacing: 8,
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          ),
        ),
      ),
      
      const SizedBox(height: 10),
      
      // Resend OTP text
      const Text(
        'Did not receive OTP? Send again.',
        style: TextStyle(
          color: Color(0xFF727272),
          fontSize: 10,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w400,
        ),
      ),
      GestureDetector(
        onTap: () {
          print("Handle no access to registered number");
        },
        child: const Text(
          'No more access to registered number?',
          style: TextStyle(
            color: Color(0xFF727272),
            fontSize: 10,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF727272),
          ),
        ),
      ),
      
      const SizedBox(height: 30),
      
      // Continue button
      _buildActionButton('Continue', _proceedToNextStep),
    ];
  }

  List<Widget> _buildSuccessStep() {
    return [
      const SizedBox(height: 50),
      
      // Success message
      Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            'Account Created Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green,
              fontSize: 24,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome to Bloomie',
            style: TextStyle(
              color: Color(0xFF717070),
              fontSize: 16,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 50),
      
      // Continue to app button
      GestureDetector(
        onTap: () {
          // Navigate to main app or dashboard
          print("Navigate to main app");
        },
        child: Container(
          width: 200,
          height: 55,
          decoration: ShapeDecoration(
            color: Color(0xFFFAB494),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Center(
            child: Text(
              'Continue to App',
              style: TextStyle(
                color: Color(0xFF995444),
                fontSize: 18,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringButton = true),
      onExit: (_) => setState(() => _isHoveringButton = false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 159,
          height: 55,
          decoration: ShapeDecoration(
            color: _isHoveringButton ? Color(0xFFE09975) : Color(0xFFFAB494),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFF995444),
                fontSize: 20,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, Color color, bool obscure, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 280,
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textAlign: TextAlign.left,
        style: TextStyle(
          color: Color(0xFF828282),
          fontSize: 15,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: color,
          hintText: hint,
          hintStyle: TextStyle(
            color: Color(0xFF939393),
            fontSize: 15,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF939393),
            size: 20,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}