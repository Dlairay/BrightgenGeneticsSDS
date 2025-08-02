class QuestionnaireQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String? category;
  
  QuestionnaireQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.category,
  });
  
  factory QuestionnaireQuestion.fromJson(Map<String, dynamic> json) {
    return QuestionnaireQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      category: json['category'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'category': category,
    };
  }
}

class QuestionnaireAnswer {
  final String questionId;
  final String question;
  final String answer;
  final int selectedIndex;
  
  QuestionnaireAnswer({
    required this.questionId,
    required this.question,
    required this.answer,
    required this.selectedIndex,
  });
  
  factory QuestionnaireAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionnaireAnswer(
      questionId: json['question_id'] ?? json['questionId'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      selectedIndex: json['selected_index'] ?? json['selectedIndex'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question': question,
      'answer': answer,
      'selected_index': selectedIndex,
    };
  }
}

class QuestionnaireResult {
  final String summary;
  final List<QuestionnaireRecommendation> recommendations;
  final DateTime timestamp;
  
  QuestionnaireResult({
    required this.summary,
    required this.recommendations,
    required this.timestamp,
  });
  
  factory QuestionnaireResult.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResult(
      summary: json['summary'] ?? '',
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .map((rec) => QuestionnaireRecommendation.fromJson(rec))
          .toList(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'recommendations': recommendations.map((rec) => rec.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class QuestionnaireRecommendation {
  final String trait;
  final String goal;
  final String activity;
  
  QuestionnaireRecommendation({
    required this.trait,
    required this.goal,
    required this.activity,
  });
  
  factory QuestionnaireRecommendation.fromJson(Map<String, dynamic> json) {
    return QuestionnaireRecommendation(
      trait: json['trait'] ?? '',
      goal: json['goal'] ?? '',
      activity: json['activity'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'trait': trait,
      'goal': goal,
      'activity': activity,
    };
  }
}

class QuestionnaireSession {
  final String childId;
  final List<QuestionnaireQuestion> questions;
  final List<QuestionnaireAnswer> answers;
  final int currentQuestionIndex;
  final bool isCompleted;
  final QuestionnaireResult? result;
  
  QuestionnaireSession({
    required this.childId,
    required this.questions,
    required this.answers,
    this.currentQuestionIndex = 0,
    this.isCompleted = false,
    this.result,
  });
  
  double get progress {
    if (questions.isEmpty) return 0.0;
    return (currentQuestionIndex + 1) / questions.length;
  }
  
  bool get canGoNext {
    return currentQuestionIndex < answers.length;
  }
  
  bool get canGoPrevious {
    return currentQuestionIndex > 0;
  }
  
  bool get isLastQuestion {
    return currentQuestionIndex == questions.length - 1;
  }
  
  QuestionnaireQuestion? get currentQuestion {
    if (currentQuestionIndex >= 0 && currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }
  
  QuestionnaireAnswer? getAnswerForCurrentQuestion() {
    if (currentQuestionIndex < answers.length) {
      return answers[currentQuestionIndex];
    }
    return null;
  }
}