import 'question_4_images.dart';
import 'package:flutter/material.dart';

class Question3Buttons extends StatefulWidget {
  const Question3Buttons({super.key});

  @override
  State<Question3Buttons> createState() => _Question3ButtonsState();
}

class _Question3ButtonsState extends State<Question3Buttons> {
  String selected = "";

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
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE6BE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/profile.png',
                    width: 28,
                    height: 28,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                "Nice!",
                style: TextStyle(fontSize: 20, color: Color(0xFF575757)),
              ),
              const SizedBox(height: 12),

              // Progress bar (60%)
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF385581),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Question 3 of 5',
                style: TextStyle(fontSize: 14, color: Color(0xFF717070)),
              ),
              const SizedBox(height: 8),

              const Text(
                'Does your baby show engagement?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              Column(
                children: [
                  radioButton('A', 'Yes'),
                  const SizedBox(height: 16),
                  radioButton('B', 'No'),
                ],
              ),

              const Spacer(),

              Center(
                child: GestureDetector(
                  onTap: selected.isNotEmpty
    ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Question4Images()),
        );
      }
    : null,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected.isNotEmpty
                          ? const Color(0xFFFFD792)
                          : Colors.grey[400],
                      border: Border.all(
                        color: const Color(0xFFFFA304),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
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

  Widget radioButton(String label, String value) {
    bool isSelected = selected == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selected = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A6DCD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected
                  ? Colors.white
                  : const Color(0xFF6A6DCD),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF6A6DCD) : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
