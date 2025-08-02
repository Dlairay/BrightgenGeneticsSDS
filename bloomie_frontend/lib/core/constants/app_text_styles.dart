import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fredokaFont = 'Fredoka';
  static const String poppinsFont = 'Poppins';
  
  // Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFamily: fredokaFont,
    color: AppColors.textDark,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontFamily: fredokaFont,
    color: AppColors.textDark,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: fredokaFont,
    color: AppColors.textDark,
  );
  
  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: poppinsFont,
    color: AppColors.textDark,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: poppinsFont,
    color: AppColors.textGray,
  );
  
  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: poppinsFont,
    color: Colors.white,
  );
  
  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: poppinsFont,
    color: AppColors.textGray,
  );
}