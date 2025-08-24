import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questionnaire_provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/widgets/custom_button.dart';
import '../main.dart';

class DynamicQuestionnaireScreen extends StatefulWidget {
  final String childId;
  
  const DynamicQuestionnaireScreen({
    super.key,
    required this.childId,
  });

  @override
  State<DynamicQuestionnaireScreen> createState() => _DynamicQuestionnaireScreenState();
}

class _DynamicQuestionnaireScreenState extends State<DynamicQuestionnaireScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuestionnaire();
    });
  }
  
  Future<void> _startQuestionnaire() async {
    final provider = Provider.of<QuestionnaireProvider>(context, listen: false);
    await provider.startQuestionnaire(widget.childId);
  }
  
  void _selectOption(int optionIndex) {
    final provider = Provider.of<QuestionnaireProvider>(context, listen: false);
    provider.answerCurrentQuestion(optionIndex);
  }
  
  void _nextQuestion() {
    final provider = Provider.of<QuestionnaireProvider>(context, listen: false);
    
    if (provider.currentSession?.isLastQuestion == true) {
      _submitQuestionnaire();
    } else {
      provider.nextQuestion();
    }
  }
  
  void _previousQuestion() {
    final provider = Provider.of<QuestionnaireProvider>(context, listen: false);
    provider.previousQuestion();
  }
  
  Future<void> _submitQuestionnaire() async {
    final provider = Provider.of<QuestionnaireProvider>(context, listen: false);
    final success = await provider.submitQuestionnaire();
    
    if (success && mounted) {
      _showResults();
    }
  }
  
  void _showResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionnaireResultsScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<QuestionnaireProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading questions...'),
                  ],
                ),
              );
            }
            
            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/sp2.png', // Using error/warning icon
                      width: 64,
                      height: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Retry',
                      onPressed: _startQuestionnaire,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Back to Home',
                      backgroundColor: Colors.grey,
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const Dashboard(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final session = provider.currentSession;
            if (session == null) {
              return const Center(child: Text('No questionnaire session'));
            }
            
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar (matching frontend.html pattern)
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  
                  // Progress bar (matching frontend.html pattern)
                  _buildProgressBar(session.progress),
                  const SizedBox(height: 16),
                  
                  // Question counter
                  Text(
                    'Question ${session.currentQuestionIndex + 1} of ${session.questions.length}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  
                  // Question (matching frontend.html pattern)
                  _buildQuestionCard(session, provider),
                  
                  const Spacer(),
                  
                  // Back button
                  CustomButton(
                    text: 'Back to Dashboard',
                    backgroundColor: Colors.grey,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const Dashboard(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildTopBar(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final child = authProvider.getChildById(widget.childId);
        final childName = child?.name ?? 'Child';
        
        return Center(
          child: Column(
            children: [
              Text(
                '📝 Check-in',
                style: AppTextStyles.h3.copyWith(
                  color: const Color(0xFF667eea), // Same as home icon color
                ),
              ),
              Text(
                childName,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildProgressBar(double progress) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.progressBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF667eea), // Same as home icon
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuestionCard(session, QuestionnaireProvider provider) {
    final question = session.currentQuestion;
    if (question == null) return const SizedBox();
    
    final selectedIndex = provider.getSelectedOptionIndex();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            question.question,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 20),
          
          // Options (matching frontend.html pattern)
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedIndex == index;
            
            return GestureDetector(
              onTap: () => _selectOption(index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF667eea) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF667eea) : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 20),
          
          // Navigation buttons (matching frontend.html pattern)
          if (session.canGoPrevious) 
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Previous',
                    onPressed: _previousQuestion,
                    backgroundColor: const Color(0xFFFFE1DD), // Pastel red/pink
                    textColor: const Color(0xFF6B4545), // Darker text for contrast
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: session.isLastQuestion ? 'Submit' : 'Next',
                    onPressed: provider.isCurrentQuestionAnswered ? () => _nextQuestion() : null,
                    backgroundColor: provider.isCurrentQuestionAnswered 
                        ? const Color(0xFFE8F5E8) // Pastel green
                        : Colors.grey,
                    textColor: provider.isCurrentQuestionAnswered 
                        ? const Color(0xFF2A5A3C) // Darker text for contrast
                        : Colors.white,
                  ),
                ),
              ],
            )
          else
            CustomButton(
              text: session.isLastQuestion ? 'Submit' : 'Next',
              onPressed: provider.isCurrentQuestionAnswered ? () => _nextQuestion() : null,
              backgroundColor: provider.isCurrentQuestionAnswered 
                  ? const Color(0xFFE8F5E8) // Pastel green
                  : Colors.grey,
              textColor: provider.isCurrentQuestionAnswered 
                  ? const Color(0xFF2A5A3C) // Darker text for contrast
                  : Colors.white,
              width: double.infinity,
            ),
        ],
      ),
    );
  }
}

class QuestionnaireResultsScreen extends StatelessWidget {
  const QuestionnaireResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<QuestionnaireProvider>(
          builder: (context, provider, child) {
            final session = provider.currentSession;
            final result = session?.result;
            
            if (result == null) {
              return const Center(child: Text('No results available'));
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/sp1.png', // Using success icon
                          width: 64,
                          height: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '✅ Check-in Complete!',
                          style: AppTextStyles.h1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Summary (matching frontend.html pattern)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E9FF), // Light tint of 0xFF667eea
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF667eea)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: AppTextStyles.h3.copyWith(color: const Color(0xFF667eea)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.summary,
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recommendations (matching frontend.html pattern)
                  if (result.recommendations.isNotEmpty) ...[
                    Text(
                      'Recommendations',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    // Replace Expanded + ListView with direct Column
                    ...result.recommendations.map((rec) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.trait,
                            style: AppTextStyles.label.copyWith(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Goal: ${rec.goal}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Activity: ${rec.activity}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    )),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Back button
                  CustomButton(
                    text: 'Back to Dashboard',
                    onPressed: () {
                      provider.resetSession();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const Dashboard(),
                        ),
                      );
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}