import 'package:flutter/material.dart';
import 'question_2_choices.dart';
import '../main.dart';

class Question1Slider extends StatefulWidget {
  const Question1Slider({super.key});

  @override
  State<Question1Slider> createState() => _Question1SliderState();
}

class _Question1SliderState extends State<Question1Slider> {
  double sleepHours = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topBar(context),
              const SizedBox(height: 24),
              progressBar(0.2),
              const SizedBox(height: 16),
              const Text(
                'Question 1 of 5',
                style: TextStyle(color: Color(0xFF717070)),
              ),
              const SizedBox(height: 8),
              const Text(
                'How well does your baby sleep at night?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              Slider(
                value: sleepHours,
                min: 0,
                max: 10,
                divisions: 10,
                label: "${sleepHours.round()} hrs",
                activeColor: const Color(0xFF6A6DCD),
                onChanged: (value) {
                  setState(() => sleepHours = value);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [Text('< 4 hours'), Text('10–15 hours')],
              ),
              const Spacer(),
              nextButton(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Question2Choices(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget topBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE6BE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/images/footstep.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
        Image.asset(
          'assets/images/profile.png',
          width: 28,
          height: 28,
        ),
      ],
    );
  }

  Widget progressBar(double progress) {
    return Container(
      height: 10,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF385581),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }

  Widget nextButton(VoidCallback onTap) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD792),
            border: Border.all(color: const Color(0xFFFFA304), width: 2),
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
              Icon(Icons.chevron_right, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
