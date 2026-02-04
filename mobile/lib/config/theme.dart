import 'package:flutter/material.dart';

// ============================================================================
// FINZO MINIMAL FINTECH THEME
// Slate/Zinc neutrals + Emerald/Rose accents for a clean, professional look
// ============================================================================

// Light Theme Colors - Clean, minimal, high contrast
class AppColors {
  // Primary - Deep Slate (used for key actions)
  static const Color primary = Color(0xFF1E293B);
  static const Color primaryLight = Color(0xFF334155);
  static const Color primaryDark = Color(0xFF0F172A);
  
  // Secondary - Subtle accent
  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryLight = Color(0xFF94A3B8);
  static const Color secondaryDark = Color(0xFF475569);
  
  // Background - Off-white for reduced eye strain
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color eggshellWhite = Color(0xFFFAFAFA);
  
  // Text - High contrast
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Status Colors - Clear and distinct
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF43F5E);
  static const Color info = Color(0xFF3B82F6);
  
  // Financial Colors - Income/Expense
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFF43F5E);
  static const Color balance = Color(0xFF1E293B);
  
  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFCBD5E1);
  
  // Category Colors - Muted, professional
  static const Map<String, Color> categoryColors = {
    'clothes': Color(0xFF8B5CF6),
    'drinks': Color(0xFFF97316),
    'education': Color(0xFF3B82F6),
    'food': Color(0xFF10B981),
    'fuel': Color(0xFF71717A),
    'fun': Color(0xFFEC4899),
    'health': Color(0xFF06B6D4),
    'hotel': Color(0xFF6366F1),
    'personal': Color(0xFF64748B),
    'pets': Color(0xFF84CC16),
    'restaurants': Color(0xFFEF4444),
    'tips': Color(0xFFF59E0B),
    'transport': Color(0xFF0EA5E9),
    'others': Color(0xFF94A3B8),
  };
  
  // Chart Colors - Cohesive palette
  static const List<Color> chartColors = [
    Color(0xFF1E293B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF43F5E),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
    Color(0xFF6366F1),
  ];
}

// Dark Theme Colors - Deep blacks with bright accents
class AppColorsDark {
  // Primary - Bright for visibility on dark
  static const Color primary = Color(0xFFF8FAFC);
  static const Color primaryLight = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFFE2E8F0);
  
  // Secondary
  static const Color secondary = Color(0xFF94A3B8);
  static const Color secondaryLight = Color(0xFFCBD5E1);
  static const Color secondaryDark = Color(0xFF64748B);
  
  // Background - True dark mode
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);
  
  // Text - High contrast on dark
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textLight = Color(0xFFFAFAFA);
  
  // Status Colors - Brighter for dark backgrounds
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFB7185);
  static const Color info = Color(0xFF60A5FA);
  
  // Financial Colors
  static const Color income = Color(0xFF34D399);
  static const Color expense = Color(0xFFFB7185);
  static const Color debt = Color(0xFF60A5FA);
  static const Color balance = Color(0xFFF1F5F9);
  
  // Borders
  static const Color border = Color(0xFF27272A);
  static const Color borderLight = Color(0xFF3F3F46);
  
  // Category Colors - Brighter for dark theme
  static const Map<String, Color> categoryColors = {
    'clothes': Color(0xFFA78BFA),
    'drinks': Color(0xFFFB923C),
    'education': Color(0xFF60A5FA),
    'food': Color(0xFF34D399),
    'fuel': Color(0xFFA1A1AA),
    'fun': Color(0xFFF472B6),
    'health': Color(0xFF22D3EE),
    'hotel': Color(0xFF818CF8),
    'personal': Color(0xFF94A3B8),
    'pets': Color(0xFFA3E635),
    'restaurants': Color(0xFFFB7185),
    'tips': Color(0xFFFBBF24),
    'transport': Color(0xFF38BDF8),
    'others': Color(0xFFA1A1AA),
  };
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFFF8FAFC),
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFFB7185),
    Color(0xFFFBBF24),
    Color(0xFFA78BFA),
    Color(0xFF22D3EE),
    Color(0xFFF472B6),
    Color(0xFFA3E635),
    Color(0xFF818CF8),
  ];
}

// Color Helper - Dynamic color access based on theme
class ColorHelper {
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.primary
        : AppColors.primary;
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.secondary
        : AppColors.secondary;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.background
        : AppColors.background;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.surface
        : AppColors.surface;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
  }

  static Color getTextLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.textLight
        : AppColors.textLight;
  }

  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.success
        : AppColors.success;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.error
        : AppColors.error;
  }

  static Color getIncomeColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.income
        : AppColors.income;
  }

  static Color getExpenseColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.expense
        : AppColors.expense;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.border
        : AppColors.border;
  }
}

// Text Styles - Clean typography
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.2,
  );
}

// Decorations - Subtle, modern styling
class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration cardDecorationDark = BoxDecoration(
    color: AppColorsDark.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColorsDark.border, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration gradientDecoration = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryLight],
    ),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  
  static BoxDecoration gradientDecorationDark = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColorsDark.surface, AppColorsDark.surfaceLight],
    ),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  
  static BoxDecoration buttonDecoration = BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(8),
  );
  
  static BoxDecoration buttonDecorationDark = BoxDecoration(
    color: AppColorsDark.primary,
    borderRadius: BorderRadius.circular(8),
  );

  // Helper to get card decoration based on theme
  static BoxDecoration getCardDecoration(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardDecorationDark
        : cardDecoration;
  }
}

// Theme Data - Complete theme definitions
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    
    // Input Fields - Clear borders for visibility
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    
    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    // Dividers
    dividerColor: AppColors.border,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    
    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.background,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsDark.background,
      foregroundColor: AppColorsDark.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColorsDark.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    
    // Input Fields - Clear visibility on dark
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.surface,
      hintStyle: TextStyle(color: AppColorsDark.textSecondary.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColorsDark.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.background,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsDark.primary,
        side: const BorderSide(color: AppColorsDark.primary),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsDark.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: AppColorsDark.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColorsDark.border),
      ),
    ),
    
    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColorsDark.surface,
      labelStyle: const TextStyle(color: AppColorsDark.textPrimary),
      side: const BorderSide(color: AppColorsDark.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    // Dividers
    dividerColor: AppColorsDark.border,
    dividerTheme: const DividerThemeData(
      color: AppColorsDark.border,
      thickness: 1,
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColorsDark.surface,
      selectedItemColor: AppColorsDark.primary,
      unselectedItemColor: AppColorsDark.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    
    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColorsDark.primary,
      foregroundColor: AppColorsDark.background,
      elevation: 2,
    ),
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primary,
      secondary: AppColorsDark.secondary,
      surface: AppColorsDark.surface,
      error: AppColorsDark.error,
      onPrimary: AppColorsDark.background,
      onSecondary: AppColorsDark.background,
      onSurface: AppColorsDark.textPrimary,
      onError: Colors.white,
    ),
  );
}

