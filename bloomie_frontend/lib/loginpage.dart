import 'package:flutter/material.dart';
import 'package:bloomie_frontend/signuppage.dart';
import 'main.dart';
import 'core/utils/logger.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginFlowPage(),
    );
  }
}

class LoginFlowPage extends StatefulWidget {
  const LoginFlowPage({super.key});
  @override
  _LoginFlowPageState createState() => _LoginFlowPageState();
}

class _LoginFlowPageState extends State<LoginFlowPage> {
  int currentStep = 1; // 1 = Login, 2 = OTP, 3 = Success
  bool _isHoveringButton = false;

  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  void _proceedToOTP() {
    // Validate fields before proceeding
    if (emailController.text.isNotEmpty && 
        phoneController.text.isNotEmpty && 
        passwordController.text.isNotEmpty) {
      setState(() {
        currentStep = 2;
      });
    } else {
      // Show validation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _verifyOTP() {
    if (otpController.text.length == 6) {
      setState(() {
        currentStep = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
            child: SizedBox(
              width: 280,
              height: 660,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Welcome Back title
                  SizedBox(
                    height: 40,
                    child: Text(
                      'Welcome Back',
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
                    currentStep == 2 ? 'OTP Verification' : 'Excited to have you here',
                    style: TextStyle(
                      color: Color(0xFF717070),
                      fontSize: 15,
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Conditional content based on current step
                  if (currentStep == 1) ..._buildLoginStep(),
                  if (currentStep == 2) ..._buildOTPStep(),
                  if (currentStep == 3) ..._buildSuccessStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginStep() {
    return [
      // Email field
      _buildInputField('Email Address', Color(0xFFFDE5BE), false, emailController, Icons.email),
      
      // Phone field
      _buildInputField('Handphone number', Color(0xFFFDE6BE), false, phoneController, Icons.phone),
      
      // Password field
      _buildInputField('Password', Color(0xFFFDE6BE), true, passwordController, Icons.lock),
      
      // Forgot password
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            // Navigate to forgot password
            AppLogger.info('Navigate to forgot password');
          },
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w400,
              color: Color(0xFF727272),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF727272),
            ),
          ),
        ),
      ),
      
      const SizedBox(height: 30),
      
      // Interactive Log In button
      MouseRegion(
        onEnter: (_) => setState(() => _isHoveringButton = true),
        onExit: (_) => setState(() => _isHoveringButton = false),
        child: GestureDetector(
          onTap: _proceedToOTP,
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
                'Log In',
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
      ),
      
      const SizedBox(height: 40),
      
      // Sign up text
      Text(
        "Don't have an account?",
        style: const TextStyle(
          color: Color(0xFF727272),
          fontSize: 10,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w400,
        ),
      ),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignUpPage()),
          );
        },
        child: Text(
          'Click here to sign up.',
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

      const SizedBox(height: 20),
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
      
      // OTP input field
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
          // Handle no access to registered number
          AppLogger.info('Handle no access to registered number');
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
      MouseRegion(
        onEnter: (_) => setState(() => _isHoveringButton = true),
        onExit: (_) => setState(() => _isHoveringButton = false),
        child: GestureDetector(
          onTap: _verifyOTP,
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
                'Continue',
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
      ),
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
            'Login Successful!',
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
          // Navigate to main home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePageQuestionnaireReminder()),
          );
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