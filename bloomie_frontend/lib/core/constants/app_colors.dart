import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color background = Color(0xFFFAF4EA);
  static const Color primary = Color(0xFFFFB366);
  static const Color secondary = Color(0xFF98E4D6);
  
  // Card colors
  static const Color cardPink = Color(0xFFFFE1DD);
  static const Color cardYellow = Color(0xFFFFF1D3);
  static const Color cardOrange = Color(0xFFFDE6BE);
  static const Color cardGreen = Color(0xFFE8F5E8);
  
  // Text colors
  static const Color textGray = Color(0xFF717070);
  static const Color textDark = Color(0xFF2C2C2C);
  
  // Button colors
  static const Color buttonOrange = Color(0xFFFFD792);
  static const Color buttonBorder = Color(0xFFFFA304);
  
  // Questionnaire colors
  static const Color sliderActive = Color(0xFF6A6DCD);
  static const Color progressBar = Color(0xFF385581);
  static const Color progressBackground = Color(0xFFE5E5E5);
  
  // Opacity helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}