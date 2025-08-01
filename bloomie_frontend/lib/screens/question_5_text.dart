import 'package:flutter/material.dart';
import '../homepage_a_q.dart';

class Question5TextInput extends StatefulWidget {
  const Question5TextInput({super.key});

  @override
  State<Question5TextInput> createState() => _Question5TextInputState();
}

class _Question5TextInputState extends State<Question5TextInput> {
  final TextEditingController _controller = TextEditingController();

  void _onFinishPressed() {
    String response = _controller.text;
    // You can handle form submission here (save, send, navigate, etc.)
    print("User input: $response");
    
    // Navigate to updated homepage_a_q.dart
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const BloomieHomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top navigation row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Text(
                "...And we're done",
                style: TextStyle(
                  color: Color(0xFF575757),
                  fontSize: 18,
                  fontFamily: 'Roboto',
                ),
              ),

              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 1.0, // 100% progress
                backgroundColor: Colors.orange[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),

              const SizedBox(height: 24),
              const Text(
                "Question 5 of 5",
                style: TextStyle(
                  color: Color(0xFF717070),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "What new milestones has your baby reached since the previous check-in?",
                style: TextStyle(
                  color: Color(0xFF575757),
                  fontSize: 24,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Type anything",
                  fillColor: Colors.amber[100],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: _onFinishPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD792),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color(0xFFFFA304),
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Finish",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
