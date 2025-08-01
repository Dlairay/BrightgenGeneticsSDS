# Bloomie Frontend - Flutter Application

## Project Overview
Bloomie is a Flutter-based parenting application designed to help parents track their child's development through questionnaires, chat with an AI assistant (Dr. Bloom), and manage parenting-related documents and insights.

## Project Structure
```
bloomie_frontend/
├── lib/
│   ├── main.dart                    # Main application entry point & home page
│   ├── loginpage.dart              # Multi-step login flow with OTP
│   ├── signuppage.dart             # Sign-up functionality (minimal)
│   ├── chatbot.dart                # Standalone chatbot interface
│   ├── gensum.dart                 # Document generation summary (minimal)
│   ├── uploaddocs.dart             # Document upload with loading animation
│   ├── lch.dart                    # (empty file)
│   └── screens/
│       ├── question_1_slider.dart  # Questionnaire: Sleep tracking slider
│       ├── question_2_choices.dart # Questionnaire: Multiple choice questions
│       ├── question_3_buttons.dart # Questionnaire: Button-based responses
│       ├── question_4_images.dart  # Questionnaire: Image-based selections
│       └── question_5_text.dart    # Questionnaire: Text input responses
├── assets/
│   └── images/                     # Application images and icons
├── android/                        # Android platform files
├── ios/                           # iOS platform files
├── web/                           # Web platform files
├── windows/                       # Windows platform files
├── linux/                         # Linux platform files
├── macos/                         # macOS platform files
├── pubspec.yaml                   # Flutter dependencies
└── analysis_options.yaml         # Dart analyzer configuration
```

## Key Dependencies
- **Flutter SDK**: >=3.8.0 <4.0.0
- **image_picker**: ^1.0.4 - For camera and photo selection
- **cupertino_icons**: ^1.0.8 - iOS-style icons
- **flutter_lints**: ^5.0.0 - Code quality and style enforcement

## Core Features

### 1. Home Dashboard (`main.dart`)
- **Welcome screen** with user profile (Baby Amy)
- **Scrollable cards** for different features:
  - Bi-weekly Questionnaire
  - Today's Parenting Focus
  - Additional Content
- **Bottom section** with Statistics, Records, and Dr. Bloom access
- **Navigation bar** with interactive buttons
- **Chat history management** with persistent storage

### 2. Authentication Flow (`loginpage.dart`)
- **Multi-step login process**:
  1. Email, phone, password input
  2. OTP verification (6-digit code)
  3. Success confirmation
- **Input validation** and error handling
- **Animated transitions** between steps
- **Interactive UI elements** with hover effects

### 3. AI Chatbot (`chatbot.dart`)
- **Dr. Bloom chat interface**
- **Message bubbles** with user/bot avatars
- **Attachment menu** (Camera, Photos, Files) - placeholders
- **Voice recording capability** - placeholder
- **Real-time typing indicators**

### 4. Questionnaire System (`screens/`)
- **5-question assessment flow**:
  - Q1: Sleep tracking with slider (0-10 hours)
  - Q2: Multiple choice responses
  - Q3: Button-based selections  
  - Q4: Image-based choices
  - Q5: Text input responses
- **Progress tracking** with visual progress bar
- **Navigation between questions**

### 5. Document Management
- **Upload interface** (`uploaddocs.dart`) with loading animation
- **Summary generation** (`gensum.dart`) - placeholder

## Design System

### Color Palette
- **Background**: `#FAF4EA` (cream/beige)
- **Cards**: 
  - `#FFE1DD` (light pink)
  - `#FFEFD3` (light yellow)
  - `#FDE5BE` (light orange)
  - `#E8F5E8` (light green)
- **Accent**: `#FFB366` (orange), `#98E4D6` (teal)
- **Text**: `#717070` (gray)

### Typography
- **Font Family**: Fredoka (primary), Poppins (secondary)
- **Consistent sizing** and weight hierarchy

### UI Components
- **Rounded corners** (10-21px border radius)
- **Soft shadows** for depth
- **Interactive elements** with hover/tap states
- **Consistent spacing** and padding

## Development Commands

### Setup & Installation
```bash
flutter pub get          # Install dependencies
flutter doctor           # Check development environment
```

### Development
```bash
flutter run              # Run on connected device/emulator
flutter run -d web       # Run web version
flutter run -d chrome    # Run in Chrome browser
```

### Build & Testing
```bash
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
flutter build web        # Build web version
flutter test             # Run unit tests
flutter analyze          # Run static analysis
```

## Key Files to Understand

### Main Application Flow
1. **`main.dart:4`** - App entry point with `FigmaToCodeApp`
2. **`main.dart:23`** - Home page with `HomePageQuestionnaireReminder`
3. **`main.dart:696`** - Chatbot functionality with `ChatBotPage`

### Authentication
- **`loginpage.dart:25`** - Login flow state management
- **`loginpage.dart:162`** - Login step UI components
- **`loginpage.dart:260`** - OTP verification step

### Questionnaire Components
- **`question_1_slider.dart:11`** - Sleep tracking slider implementation
- **Navigation flow** between questions using `MaterialPageRoute`

## Development Notes

### Current State
- **Home page**: Fully functional with navigation to questionnaire
- **Chat system**: Basic UI with message display, no backend integration
- **Login flow**: Complete UI flow, no backend authentication
- **Questionnaires**: Connected to home page, Q1 navigates to Q2-Q5 (full flow implemented)
- **File upload**: Loading animation only, no actual upload functionality

### Architecture Patterns
- **StatefulWidget** for interactive components
- **Navigator.push** for page transitions
- **Animation controllers** for loading states
- **Consistent styling** across components

### Development Environment
- **Flutter 3.32.0** (stable channel)
- **Dart SDK**: Compatible with >=3.8.0
- **Target platforms**: iOS, Android, Web, Desktop
- **No backend integration** currently implemented

### Next Development Steps
1. **Backend integration** for chat and authentication
2. **Complete questionnaire screens** (Q2-Q5)
3. **File upload functionality**
4. **Database integration** for user data
5. **Push notifications** for questionnaire reminders
6. **User profile management**

## Asset Management
- **Images stored** in `assets/images/`
- **Configured in** `pubspec.yaml:61-75`
- **Key assets**: Bloomie logo, background, baby photos, icons
- **Questionnaire images**: Baby rash conditions for Question 4 selection

This is a well-structured Flutter application with a comprehensive UI implementation ready for backend integration and feature completion.