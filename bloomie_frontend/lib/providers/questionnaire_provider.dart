import 'package:flutter/material.dart';
import '../models/questionnaire_models.dart';
import '../services/api_service.dart';
import '../core/utils/logger.dart';

class QuestionnaireProvider extends ChangeNotifier {
  QuestionnaireSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  QuestionnaireSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isCompleted;
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Start a new questionnaire session
  Future<bool> startQuestionnaire(String childId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      AppLogger.info('Starting questionnaire for child: $childId');
      
      // Fetch questions from API (matching frontend.html pattern)
      final response = await ApiService.getQuestionnaireQuestions(childId);
      final questions = (response['questions'] as List<dynamic>)
          .map((q) => QuestionnaireQuestion.fromJson(q))
          .toList();
      
      if (questions.isEmpty) {
        _errorMessage = 'No questions available for check-in';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _currentSession = QuestionnaireSession(
        childId: childId,
        questions: questions,
        answers: [],
        currentQuestionIndex: 0,
      );
      
      _isLoading = false;
      notifyListeners();
      
      AppLogger.info('Questionnaire started with ${questions.length} questions');
      return true;
      
    } catch (e) {
      _errorMessage = 'Failed to load questions: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Failed to start questionnaire', error: e);
      return false;
    }
  }
  
  // Answer current question
  void answerCurrentQuestion(int selectedIndex) {
    if (_currentSession == null) return;
    
    final question = _currentSession!.currentQuestion;
    if (question == null || selectedIndex >= question.options.length) return;
    
    final answer = QuestionnaireAnswer(
      questionId: question.id,
      question: question.question,
      answer: question.options[selectedIndex],
      selectedIndex: selectedIndex,
    );
    
    // Update or add answer for current question
    final answers = List<QuestionnaireAnswer>.from(_currentSession!.answers);
    
    if (_currentSession!.currentQuestionIndex < answers.length) {
      // Update existing answer
      answers[_currentSession!.currentQuestionIndex] = answer;
    } else {
      // Add new answer
      answers.add(answer);
    }
    
    _currentSession = QuestionnaireSession(
      childId: _currentSession!.childId,
      questions: _currentSession!.questions,
      answers: answers,
      currentQuestionIndex: _currentSession!.currentQuestionIndex,
      isCompleted: _currentSession!.isCompleted,
      result: _currentSession!.result,
    );
    
    notifyListeners();
    AppLogger.info('Answer saved for question ${_currentSession!.currentQuestionIndex + 1}');
  }
  
  // Go to next question
  void nextQuestion() {
    if (_currentSession == null || !_currentSession!.canGoNext) return;
    
    _currentSession = QuestionnaireSession(
      childId: _currentSession!.childId,
      questions: _currentSession!.questions,
      answers: _currentSession!.answers,
      currentQuestionIndex: _currentSession!.currentQuestionIndex + 1,
      isCompleted: _currentSession!.isCompleted,
      result: _currentSession!.result,
    );
    
    notifyListeners();
  }
  
  // Go to previous question
  void previousQuestion() {
    if (_currentSession == null || !_currentSession!.canGoPrevious) return;
    
    _currentSession = QuestionnaireSession(
      childId: _currentSession!.childId,
      questions: _currentSession!.questions,
      answers: _currentSession!.answers,
      currentQuestionIndex: _currentSession!.currentQuestionIndex - 1,
      isCompleted: _currentSession!.isCompleted,
      result: _currentSession!.result,
    );
    
    notifyListeners();
  }
  
  // Submit questionnaire
  Future<bool> submitQuestionnaire() async {
    if (_currentSession == null || _currentSession!.answers.length != _currentSession!.questions.length) {
      _errorMessage = 'Please answer all questions before submitting';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      AppLogger.info('Submitting questionnaire for child: ${_currentSession!.childId}');
      
      // Submit answers to API (matching frontend.html pattern)
      final response = await ApiService.submitQuestionnaire(
        _currentSession!.childId,
        _currentSession!.answers,
      );
      
      final result = QuestionnaireResult.fromJson(response);
      
      _currentSession = QuestionnaireSession(
        childId: _currentSession!.childId,
        questions: _currentSession!.questions,
        answers: _currentSession!.answers,
        currentQuestionIndex: _currentSession!.currentQuestionIndex,
        isCompleted: true,
        result: result,
      );
      
      _isLoading = false;
      notifyListeners();
      
      AppLogger.info('Questionnaire submitted successfully');
      return true;
      
    } catch (e) {
      _errorMessage = 'Failed to submit questionnaire: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Failed to submit questionnaire', error: e);
      return false;
    }
  }
  
  // Reset questionnaire session
  void resetSession() {
    _currentSession = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    AppLogger.info('Questionnaire session reset');
  }
  
  // Get selected option index for current question
  int? getSelectedOptionIndex() {
    if (_currentSession == null) return null;
    
    final answer = _currentSession!.getAnswerForCurrentQuestion();
    return answer?.selectedIndex;
  }
  
  // Check if current question is answered
  bool get isCurrentQuestionAnswered {
    return getSelectedOptionIndex() != null;
  }
}