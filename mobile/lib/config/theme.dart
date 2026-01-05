import 'package:flutter/material.dart';

// Light Theme Colors
class AppColors {
  // Primary Colors - Modern Teal Blue
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0D5A52);
  
  // Secondary Colors - Warm Orange
  static const Color secondary = Color(0xFFF97316);
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFEA580C);
  
  // Background Colors - Eggshell White & Clean
  static const Color background = Color(0xFFFAFAFA); // Eggshell white
  static const Color surface = Color(0xFFFDFCFB); // Eggshell white for cards
  static const Color eggshellWhite = Color(0xFFFDFCFB); // Pure eggshell
  static const Color surfaceDark = Color(0xFF121212);
  
  // Text Colors - High Contrast
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Status Colors - Refined
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
  
  // Income/Expense Colors
  static const Color income = Color(0xFF16A34A);
  static const Color expense = Color(0xFFDC2626);
  static const Color balance = Color(0xFF0F766E);
  
  // Category Colors - Minimal Earth Tones
  static const Map<String, Color> categoryColors = {
    'clothes': Color(0xFF8B5CF6),
    'drinks': Color(0xFFF97316),
    'education': Color(0xFF0EA5E9),
    'food': Color(0xFF16A34A),
    'fuel': Color(0xFF78716C),
    'fun': Color(0xFFEC4899),
    'health': Color(0xFF06B6D4),
    'hotel': Color(0xFF3B82F6),
    'personal': Color(0xFF64748B),
    'pets': Color(0xFF84CC16),
    'restaurants': Color(0xFFEA580C),
    'tips': Color(0xFFFCD34D),
    'transport': Color(0xFF14B8A6),
    'others': Color(0xFFA3A3A3),
  };
  
  // Chart Colors - Cohesive Minimal Palette
  static const List<Color> chartColors = [
    Color(0xFF0F766E),
    Color(0xFFF97316),
    Color(0xFF0EA5E9),
    Color(0xFF16A34A),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFFCD34D),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFF78716C),
    Color(0xFFDC2626),
    Color(0xFF8B5CF6),
  ];
}

// Dark Theme Colors - Mirror of light theme but with darkest palette
class AppColorsDark {
  // Primary Colors - Bright teal for high contrast on dark backgrounds
  static const Color primary = Color(0xFF14B8A6);      // Bright teal
  static const Color primaryLight = Color(0xFF2DD4BF);  // Light cyan for hover
  static const Color primaryDark = Color(0xFF0D9488);   // Darker teal for subtle
  
  // Secondary Colors - Bright orange for high contrast
  static const Color secondary = Color(0xFFFB923C);    // Bright orange
  static const Color secondaryLight = Color(0xFFFFBD71); // Light orange for hover
  static const Color secondaryDark = Color(0xFFF97316);  // Darker orange
  
  // Background Colors - Darkest palette (near black)
  static const Color background = Color(0xFF0A0E27);   // Darkest blue-black (almost black)
  static const Color surface = Color(0xFF16213E);      // Very dark blue for surfaces
  static const Color surfaceLight = Color(0xFF1F3A52); // Dark blue for cards
  
  // Text Colors - High contrast without pure whites
  static const Color textPrimary = Color(0xFFD1D5DB);  // Light gray (no white)
  static const Color textSecondary = Color(0xFF9CA3AF); // Medium gray for secondary
  static const Color textLight = Color(0xFFE5E7EB);    // Off-white (not pure white)
  
  // Status Colors - Optimized for dark backgrounds
  static const Color success = Color(0xFF10B981);      // Emerald green
  static const Color warning = Color(0xFFFDE047);      // Bright yellow
  static const Color error = Color(0xFFF87171);        // Coral red
  static const Color info = Color(0xFF06B6D4);         // Cyan blue
  
  // Accent Colors - Income/Expense tracking
  static const Color income = Color(0xFF10B981);       // Emerald green
  static const Color expense = Color(0xFFFB7185);      // Rose pink
  static const Color debt = Color(0xFF60A5FA);         // Bright blue
  static const Color balance = Color(0xFF14B8A6);      // Teal
  
  // Category Colors - Adjusted for dark theme with high saturation
  static const Map<String, Color> categoryColors = {
    'clothes': Color(0xFFC084FC),
    'drinks': Color(0xFFFB923C),
    'education': Color(0xFF38BDF8),
    'food': Color(0xFF22C55E),
    'fuel': Color(0xFFA78BFA),
    'fun': Color(0xFFF472B6),
    'health': Color(0xFF06B6D4),
    'hotel': Color(0xFF60A5FA),
    'personal': Color(0xFF94A3B8),
    'pets': Color(0xFFA3E635),
    'restaurants': Color(0xFFFB7185),
    'tips': Color(0xFFFDE047),
    'transport': Color(0xFF2DD4BF),
    'others': Color(0xFF9CA3AF),
  };
  
  // Chart Colors - High contrast for dark backgrounds
  static const List<Color> chartColors = [
    Color(0xFF14B8A6),  // Teal
    Color(0xFFFB923C),  // Orange
    Color(0xFF06B6D4),  // Cyan
    Color(0xFF10B981),  // Green
    Color(0xFFF472B6),  // Pink
    Color(0xFF2DD4BF),  // Light teal
    Color(0xFFFDE047),  // Yellow
    Color(0xFFFB7185),  // Rose
    Color(0xFF60A5FA),  // Blue
    Color(0xFF34D399),  // Emerald
    Color(0xFFC084FC),  // Purple
    Color(0xFFA78BFA),  // Violet
    Color(0xFFFF9999),  // Light red
    Color(0xFFFFBD71),  // Light orange
  ];
}

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
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.3,
  );
}

class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
    border: Border.all(
      color: Colors.grey.shade200,
      width: 1,
    ),
  );
  
  static BoxDecoration cardDecorationDark = BoxDecoration(
    color: AppColorsDark.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
    border: Border.all(
      color: Colors.grey.shade800,
      width: 1,
    ),
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
      colors: [AppColorsDark.primary, AppColorsDark.primaryLight],
    ),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  
  static BoxDecoration buttonDecoration = BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration buttonDecorationDark = BoxDecoration(
    color: AppColorsDark.primary,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: AppColorsDark.primary.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// Theme Data Builders
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFDFCFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
      labelStyle: const TextStyle(color: AppColors.primary),
      deleteIconColor: AppColors.primary,
    ),
    dividerColor: Colors.grey.shade200,
    cardColor: AppColors.surface,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsDark.background,
      foregroundColor: AppColorsDark.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColorsDark.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsDark.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColorsDark.primary.withOpacity(0.2),
      labelStyle: const TextStyle(color: AppColorsDark.primary),
      deleteIconColor: AppColorsDark.primary,
    ),
    dividerColor: Colors.grey.shade800,
    cardColor: AppColorsDark.surface,
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primary,
      secondary: AppColorsDark.secondary,
      surface: AppColorsDark.surface,
      error: AppColorsDark.error,
    ),
  );
}
