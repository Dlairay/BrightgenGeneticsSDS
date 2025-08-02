import '../core/utils/logger.dart';

class MockApiService {
  // Mock user data
  static const Map<String, dynamic> _mockUser = {
    'id': 'user_001',
    'name': 'Sarah Johnson',
    'email': 'sarah.johnson@example.com',
    'children': [
      {
        'id': 'amy_001',
        'name': 'Amy',
        'gender': 'female',
        'birthday': '2023-06-15',
        'created_at': '2023-06-15T10:00:00Z'
      }
    ],
    'created_at': '2023-05-01T10:00:00Z'
  };
  
  // Mock authentication endpoints
  static Future<Map<String, dynamic>> login(Map<String, dynamic> loginData) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final email = loginData['email'];
    final password = loginData['password'];
    
    AppLogger.info('Mock login attempt: $email');
    
    // Simple mock validation
    if (email == 'sarah.johnson@example.com' && password == 'password123') {
      return {
        'access_token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': _mockUser,
        'refresh_token': 'mock_refresh_token'
      };
    } else {
      throw Exception('Invalid email or password');
    }
  }
  
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final name = userData['name'];
    final email = userData['email'];
    
    AppLogger.info('Mock registration: $email');
    
    // Mock check for existing email
    if (email == 'sarah.johnson@example.com') {
      throw Exception('An account with this email already exists');
    }
    
    // Return mock user data for new registration
    final mockNewUser = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'email': email,
      'children': [],
      'created_at': DateTime.now().toIso8601String()
    };
    
    return {
      'access_token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': mockNewUser,
      'refresh_token': 'mock_refresh_token'
    };
  }
  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    AppLogger.info('Mock getCurrentUser');
    
    return _mockUser;
  }
  
  static Future<List<dynamic>> getChildren() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    AppLogger.info('Mock getChildren');
    
    return _mockUser['children'] as List<dynamic>;
  }
  // Mock questionnaire questions (similar to what frontend.html expects)
  static Future<Map<String, dynamic>> getQuestionnaireQuestions(String childId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    AppLogger.info('Mock API: Getting questions for child $childId');
    
    return {
      'questions': [
        {
          'id': 'sleep_quality',
          'question': 'How well has your baby been sleeping this week?',
          'options': [
            'Excellent - sleeps through the night consistently',
            'Good - occasional wake-ups but settles quickly',
            'Fair - wakes up multiple times but goes back to sleep',
            'Poor - frequent wake-ups and difficulty settling',
            'Very poor - barely sleeping, constant disruptions'
          ],
          'category': 'sleep'
        },
        {
          'id': 'feeding_habits',
          'question': 'How has your baby\'s appetite and feeding been?',
          'options': [
            'Excellent - eating well and gaining weight',
            'Good - generally eating well with minor issues',
            'Fair - some feeding challenges but manageable',
            'Poor - significant feeding difficulties',
            'Very concerning - refusing to eat or major issues'
          ],
          'category': 'nutrition'
        },
        {
          'id': 'mood_behavior',
          'question': 'How would you describe your baby\'s mood and behavior?',
          'options': [
            'Very happy and content most of the time',
            'Generally happy with normal fussiness',
            'Mixed - good and bad moments throughout the day',
            'Often fussy or difficult to soothe',
            'Extremely fussy, crying frequently'
          ],
          'category': 'behavior'
        },
        {
          'id': 'development_milestones',
          'question': 'Have you noticed any new developmental milestones this week?',
          'options': [
            'Yes - significant new skills or behaviors',
            'Yes - some small improvements or changes',
            'Maybe - not sure if changes are significant',
            'No - no noticeable changes',
            'Concerned - seems to be regressing'
          ],
          'category': 'development'
        },
        {
          'id': 'health_concerns',
          'question': 'Do you have any health concerns about your baby this week?',
          'options': [
            'No concerns - baby seems very healthy',
            'Minor concerns but nothing serious',
            'Some concerns worth monitoring',
            'Moderate concerns - might need checkup',
            'Serious concerns - need medical attention'
          ],
          'category': 'health'
        }
      ]
    };
  }
  
  // Mock questionnaire submission (similar to what frontend.html expects)
  static Future<Map<String, dynamic>> submitQuestionnaire(String childId, List<dynamic> answers) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
    
    AppLogger.info('Mock API: Submitting questionnaire for child $childId with ${answers.length} answers');
    
    // Analyze answers to generate mock recommendations
    final recommendations = _generateMockRecommendations(answers);
    final summary = _generateMockSummary(answers);
    
    return {
      'summary': summary,
      'recommendations': recommendations,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  static String _generateMockSummary(List<dynamic> answers) {
    // Simple mock summary based on answers
    final hasGoodSleep = answers.any((a) => a['answer']?.toString().contains('Excellent') == true);
    final hasHealthConcerns = answers.any((a) => a['answer']?.toString().contains('Serious') == true);
    
    if (hasHealthConcerns) {
      return 'Based on your responses, there are some health concerns that may need attention. Your baby shows some challenging patterns that would benefit from monitoring and possibly professional guidance.';
    } else if (hasGoodSleep) {
      return 'Great news! Your baby seems to be doing well overall. There are some areas where we can provide guidance to support continued healthy development.';
    } else {
      return 'Your baby is showing typical development patterns with some areas that could benefit from targeted support and activities.';
    }
  }
  
  static List<Map<String, dynamic>> _generateMockRecommendations(List<dynamic> answers) {
    final recommendations = <Map<String, dynamic>>[];
    
    // Check each answer and generate relevant recommendations
    for (final answer in answers) {
      final answerText = answer['answer']?.toString() ?? '';
      final question = answer['question']?.toString() ?? '';
      
      if (question.contains('sleeping')) {
        if (answerText.contains('Poor') || answerText.contains('Very poor')) {
          recommendations.add({
            'trait': 'Sleep Quality',
            'goal': 'Improve sleep patterns and nighttime routine',
            'activity': 'Establish a consistent bedtime routine with dimmed lights, gentle music, and avoid stimulating activities 1 hour before bed.'
          });
        } else if (answerText.contains('Excellent') || answerText.contains('Good')) {
          recommendations.add({
            'trait': 'Sleep Optimization',
            'goal': 'Maintain healthy sleep habits',
            'activity': 'Continue current sleep routine and consider tracking sleep patterns to identify what works best.'
          });
        }
      }
      
      if (question.contains('appetite') || question.contains('feeding')) {
        if (answerText.contains('Poor') || answerText.contains('concerning')) {
          recommendations.add({
            'trait': 'Nutrition Support',
            'goal': 'Address feeding challenges',
            'activity': 'Try offering smaller, more frequent meals and create a calm feeding environment. Consider consulting a pediatrician if concerns persist.'
          });
        }
      }
      
      if (question.contains('mood') || question.contains('behavior')) {
        if (answerText.contains('fussy') || answerText.contains('difficult')) {
          recommendations.add({
            'trait': 'Emotional Regulation',
            'goal': 'Support emotional development and reduce fussiness',
            'activity': 'Practice calming techniques like gentle massage, white noise, or skin-to-skin contact. Maintain consistent daily routines.'
          });
        }
      }
      
      if (question.contains('developmental') || question.contains('milestones')) {
        if (answerText.contains('significant new skills')) {
          recommendations.add({
            'trait': 'Developmental Growth',
            'goal': 'Support continued development',
            'activity': 'Encourage new skills through interactive play, reading together, and providing safe exploration opportunities.'
          });
        } else if (answerText.contains('regressing')) {
          recommendations.add({
            'trait': 'Development Support',
            'goal': 'Address developmental concerns',
            'activity': 'Continue current activities and consider discussing any concerns with your pediatrician during the next visit.'
          });
        }
      }
      
      if (question.contains('health concerns')) {
        if (answerText.contains('Serious') || answerText.contains('medical attention')) {
          recommendations.add({
            'trait': 'Health Monitoring',
            'goal': 'Address health concerns promptly',
            'activity': 'Schedule an appointment with your pediatrician to discuss your concerns and get professional guidance.'
          });
        }
      }
    }
    
    // Add a general recommendation if no specific ones were generated
    if (recommendations.isEmpty) {
      recommendations.add({
        'trait': 'General Wellness',
        'goal': 'Continue supporting healthy development',
        'activity': 'Maintain regular routines, provide plenty of interaction and play time, and continue monitoring your baby\'s progress.'
      });
    }
    
    return recommendations;
  }
  
  // Mock recommendations history
  static Future<List<dynamic>> getRecommendationsHistory(String childId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    AppLogger.info('Mock API: Getting recommendations history for child $childId');
    
    return [
      {
        'timestamp': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
        'entry_type': 'check_in',
        'summary': 'Previous check-in showed good progress in sleep patterns and feeding habits.',
        'recommendations': [
          {
            'trait': 'Sleep Quality',
            'goal': 'Maintain good sleep routine',
            'activity': 'Continue current bedtime routine and monitor for any changes.'
          }
        ]
      },
      {
        'timestamp': DateTime.now().subtract(const Duration(days: 28)).toIso8601String(),
        'entry_type': 'initial',
        'summary': 'Initial assessment completed. Baby showing typical development patterns.',
        'recommendations': [
          {
            'trait': 'Overall Development',
            'goal': 'Support healthy growth',
            'activity': 'Establish consistent daily routines and provide plenty of interaction.'
          }
        ]
      }
    ];
  }
}