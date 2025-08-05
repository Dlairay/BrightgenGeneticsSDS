import 'package:flutter/material.dart';
import 'question_3_buttons.dart';

class Question2Choices extends StatefulWidget {
  const Question2Choices({super.key});

  @override
  State<Question2Choices> createState() => _Question2ChoicesState();
}

class _Question2ChoicesState extends State<Question2Choices> {
  String selected = "";

  void handleSelect(String value) {
    setState(() {
      selected = value;
    });
  }

  Widget choiceCircle(String label) {
    bool isSelected = selected == label;
    return GestureDetector(
      onTap: () => handleSelect(label),
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A6DCD) : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                "Okay",
                style: TextStyle(fontSize: 20, color: Color(0xFF575757)),
              ),
              const SizedBox(height: 12),

              // Progress bar (40%)
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.4,
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
                'Question 2 of 5',
                style: TextStyle(fontSize: 14, color: Color(0xFF717070)),
              ),
              const SizedBox(height: 8),

              const Text(
                'Does your baby seem to be overly sensitive to light or noise?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  choiceCircle("Yes, to light"),
                  choiceCircle("Yes, to noise"),
                  choiceCircle("No"),
                ],
              ),
              const Spacer(),

              Center(
                child: GestureDetector(
                  onTap: selected.isNotEmpty
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Question3Buttons(),
                            ),
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
}
