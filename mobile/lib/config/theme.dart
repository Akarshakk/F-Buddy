import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4A42E8);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00D9A5);
  static const Color secondaryLight = Color(0xFF33E1B8);
  static const Color secondaryDark = Color(0xFF00B88A);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9094A6);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Income/Expense Colors
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFE53935);
  static const Color balance = Color(0xFF6C63FF);
  
  // Category Colors
  static const Map<String, Color> categoryColors = {
    'clothes': Color(0xFF9C27B0),
    'drinks': Color(0xFFFF9800),
    'education': Color(0xFF2196F3),
    'food': Color(0xFF4CAF50),
    'fuel': Color(0xFF795548),
    'fun': Color(0xFFE91E63),
    'health': Color(0xFF00BCD4),
    'hotel': Color(0xFF3F51B5),
    'personal': Color(0xFF607D8B),
    'pets': Color(0xFF8BC34A),
    'restaurants': Color(0xFFFF5722),
    'tips': Color(0xFFFFC107),
    'transport': Color(0xFF009688),
    'others': Color(0xFF9E9E9E),
  };
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF6C63FF),
    Color(0xFF00D9A5),
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF922B),
    Color(0xFFE599F7),
    Color(0xFF20C997),
    Color(0xFFFF6B9D),
    Color(0xFF845EF7),
    Color(0xFF51CF66),
    Color(0xFFFF8787),
    Color(0xFF69DB7C),
  ];
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );
}

class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration gradientDecoration = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryDark],
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
}
