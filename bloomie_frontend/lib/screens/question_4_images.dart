import 'package:flutter/material.dart';
import 'question_5_text.dart';

class Question4Images extends StatefulWidget {
  const Question4Images({super.key});

  @override
  State<Question4Images> createState() => _Question4ImagesState();
}

class _Question4ImagesState extends State<Question4Images> {
  int? selectedImageIndex;

  final List<String> imagePaths = [
    'assets/images/baby-rash.jpg',
    'assets/images/dark-skin-baby-acne_4x3.jpg',
    'assets/images/Heat-Rash-Miliaria-on-Babies-722x406.jpg',
    'assets/images/seborrheic-eczema_4x3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'One more...',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF575757),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.8,
                backgroundColor: const Color(0xFFE0E0E0),
                color: const Color(0xFF385581),
              ),
              const SizedBox(height: 24),
              const Text(
                'Question 4 of 5',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF717070),
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Have you noticed any of the following on your baby’s skin before?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                  color: Color(0xFF575757),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: imagePaths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImageIndex = index;
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedImageIndex == index
                                    ? const Color(0xFFFFA304)
                                    : Colors.transparent,
                                width: 3,
                              ),
                              image: DecorationImage(
                                image: AssetImage(imagePaths[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (selectedImageIndex == index)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: Color(0xFFFFA304),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD792),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14.0,
                      horizontal: 32.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFFFFA304),
                        width: 2,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Question5TextInput(),
                      ),
                    );
                  },
                  child: const Text(
                    'Next  »',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
