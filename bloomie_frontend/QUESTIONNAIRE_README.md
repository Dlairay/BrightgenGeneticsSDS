# Dynamic Questionnaire Implementation

## Overview

The bi-weekly questionnaire widget has been completely refactored to use dynamic data and follow the exact same flow and patterns as the `frontend.html` weekly check-in feature. This replaces the hardcoded questionnaire with a flexible, API-driven system.

## Key Features Implemented

### 1. **Dynamic Question Loading**
- Questions are fetched from API endpoint: `/children/{childId}/check-in/questions`
- Supports multiple choice questions with customizable options
- Questions can be categorized (sleep, nutrition, behavior, development, health)

### 2. **Exact Frontend.html Flow Replication**
- **Progress Bar**: Visual progress indicator showing current question position
- **Question Navigation**: Forward/backward navigation with answer persistence
- **Option Selection**: Interactive option cards that highlight when selected
- **Answer Validation**: Submit/Next button only enabled when question is answered
- **Results Display**: Shows summary and personalized recommendations after completion

### 3. **State Management with Provider**
- `QuestionnaireProvider`: Manages entire questionnaire session state
- Persistent answer storage during navigation
- Loading states and error handling
- Session management and cleanup

### 4. **API Integration with Mock Support**
- Real API endpoints ready for backend integration
- Mock data service for testing and development
- Easy toggle between mock and real API (`ApiService.useMockData`)

## File Structure

```
lib/
├── models/
│   └── questionnaire_models.dart          # Data models for questions, answers, results
├── providers/
│   └── questionnaire_provider.dart        # State management for questionnaire flow
├── screens/
│   └── dynamic_questionnaire_screen.dart  # Main questionnaire UI
├── services/
│   ├── api_service.dart                   # API integration (updated)
│   └── mock_api_service.dart              # Mock data for testing
```

## Usage

### Starting a Questionnaire

```dart
// From the home page "Dynamic Check-in" card
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DynamicQuestionnaireScreen(
      childId: 'amy_001', // Child identifier
    ),
  ),
);
```

### API Endpoints Used

1. **Get Questions**: `GET /children/{childId}/check-in/questions`
2. **Submit Answers**: `POST /children/{childId}/check-in/submit`
3. **Get History**: `GET /children/{childId}/recommendations-history`

### Expected API Response Format

#### Questions Response
```json
{
  "questions": [
    {
      "id": "sleep_quality",
      "question": "How well has your baby been sleeping this week?",
      "options": [
        "Excellent - sleeps through the night consistently",
        "Good - occasional wake-ups but settles quickly",
        "Fair - wakes up multiple times but goes back to sleep",
        "Poor - frequent wake-ups and difficulty settling"
      ],
      "category": "sleep"
    }
  ]
}
```

#### Submission Response
```json
{
  "summary": "Your baby is showing typical development patterns...",
  "recommendations": [
    {
      "trait": "Sleep Quality",
      "goal": "Improve sleep patterns and nighttime routine",
      "activity": "Establish a consistent bedtime routine with dimmed lights..."
    }
  ],
  "timestamp": "2025-08-01T10:30:00Z"
}
```

## Mock Data

The implementation includes comprehensive mock data that simulates realistic questionnaire scenarios:

- **5 Sample Questions**: Covering sleep, feeding, mood, development, and health
- **Dynamic Recommendations**: Generated based on user answers
- **Realistic Summaries**: Contextual feedback based on response patterns

## UI/UX Features

### Matching Frontend.html Design
- **Progress Bar**: 6px height with rounded corners, same color scheme
- **Question Cards**: Light grey background with rounded corners
- **Option Selection**: White cards with hover states and selection highlighting
- **Navigation Buttons**: Styled to match the original with proper state management
- **Results Screen**: Green success styling with organized recommendation cards

### Accessibility
- Proper button states (enabled/disabled)
- Clear visual feedback for selections
- Loading states with progress indicators
- Error handling with retry options

## Integration with Main App

### Provider Registration
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppStateProvider()),
    ChangeNotifierProvider(create: (_) => QuestionnaireProvider()),
  ],
  child: FigmaToCodeApp(),
)
```

### Home Page Integration
The "Bi-weekly Questionnaire" card in `main.dart` has been updated to use the new dynamic screen:

```dart
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DynamicQuestionnaireScreen(
          childId: 'amy_001',
        ),
      ),
    );
  },
  child: _buildQuestionnaireCard(),
),
```

## Testing

### Mock Data Toggle
Set `ApiService.useMockData = true` to use mock data for testing without a backend.

### Sample Flow
1. Tap "Dynamic Check-in" card on home page
2. Answer 5 sample questions about baby's development
3. Submit questionnaire
4. View personalized recommendations
5. Return to dashboard

## Future Enhancements

1. **Child ID Integration**: Connect with user authentication to get actual child IDs
2. **Offline Support**: Cache questions and queue submissions
3. **Progress Persistence**: Save partial progress across app sessions
4. **Push Notifications**: Remind users about bi-weekly check-ins
5. **Analytics**: Track completion rates and common answers
6. **Question Branching**: Conditional questions based on previous answers

## Backend Requirements

When implementing the real API, ensure:

1. **Authentication**: Endpoints require valid user tokens
2. **Child Association**: Questions should be personalized per child
3. **Data Persistence**: Store answers for history and trend analysis
4. **Recommendation Engine**: Generate contextual recommendations based on answers
5. **Rate Limiting**: Prevent abuse of questionnaire endpoints

The implementation is fully ready for backend integration - simply set `ApiService.useMockData = false` and update the API base URL.