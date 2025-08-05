import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/chat_message_model.dart';
import '../core/utils/logger.dart';

class AppStateProvider extends ChangeNotifier {
  // User state
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  
  // Chat state
  List<ChatMessageModel> _chatMessages = [];
  bool _isTyping = false;
  
  // Questionnaire state
  Map<String, dynamic> _questionnaireAnswers = {};
  int _currentQuestionIndex = 0;
  
  // Loading states
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  List<ChatMessageModel> get chatMessages => _chatMessages;
  bool get isTyping => _isTyping;
  Map<String, dynamic> get questionnaireAnswers => _questionnaireAnswers;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Authentication methods
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      _currentUser = UserModel(
        id: '1',
        email: email,
        phone: '+1234567890',
        babyName: 'Child',
      );
      _isAuthenticated = true;
      
      _isLoading = false;
      notifyListeners();
      
      AppLogger.info('User logged in successfully');
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Login failed', error: e);
    }
  }
  
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _chatMessages.clear();
    _questionnaireAnswers.clear();
    notifyListeners();
    AppLogger.info('User logged out');
  }
  
  // Chat methods
  void addChatMessage(String text, {bool isBot = false}) {
    final message = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isBot: isBot,
      timestamp: DateTime.now(),
    );
    
    _chatMessages.add(message);
    notifyListeners();
  }
  
  void setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }
  
  // Questionnaire methods
  void saveQuestionnaireAnswer(String questionId, dynamic answer) {
    _questionnaireAnswers[questionId] = answer;
    notifyListeners();
  }
  
  void nextQuestion() {
    _currentQuestionIndex++;
    notifyListeners();
  }
  
  void resetQuestionnaire() {
    _questionnaireAnswers.clear();
    _currentQuestionIndex = 0;
    notifyListeners();
  }
  
  // Error handling
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}