import 'package:flutter/material.dart';
import 'theme_extensions.dart';

/// App Theme Configuration - Modern Cattle Monitoring Theme
class AppTheme {
  // Primary Colors - Teal Theme from Images
  static const Color primaryTeal = Color(0xFF2E7D7D); // Main teal color
  static const Color darkTeal = Color(0xFF1E5555);
  static const Color lightTeal = Color(0xFF3E9D9D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF5F8FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Dashboard Card Colors (from images)
  static const Color greenCard = Color(0xFF00D9A3); // Total Cows - bright green
  static const Color limeCard = Color(0xFFCEFF00); // Milking Cows - lime yellow
  static const Color blueCard = Color(0xFF4169E1); // Lameness - royal blue
  
  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Chart Colors (from Monthly Cattle Health Report in images)
  static const Color chartPink = Color(0xFFFF6B9D); // Fat Cattle
  static const Color chartCyan = Color(0xFF00D9A3); // Thin Cattle  
  static const Color chartBlue = Color(0xFF4169E1); // Lameness Cattle
  
  // Lameness Severity Colors
  static const Color normalColor = Color(0xFF4CAF50);
  static const Color mildLamenessColor = Color(0xFFFFB74D);
  static const Color severeLamenessColor = Color(0xFFE57373);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Additional Colors for backward compatibility
  static const Color lightGray = lightBackground;
  static const Color mediumGray = Color(0xFFE0E0E0);
  static const Color mutedBlue = primaryTeal;
  static const Color accentBlue = lightTeal;
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  
  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  
  // Elevation
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  
  // Dark palette
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryTeal,
      secondary: lightTeal,
      surface: white,
      error: errorRed,
      onPrimary: white,
      onSecondary: white,
      onSurface: textPrimary,
      onError: white,
    ),
    scaffoldBackgroundColor: lightBackground,
    extensions: [AppThemeExtras.light],

    // App Bar Theme - Teal header like in images
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryTeal,
      foregroundColor: white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: white),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: white,
      elevation: elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingSm,
      ),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textPrimary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textSecondary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textHint,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: primaryTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      hintStyle: const TextStyle(color: textHint),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: white,
        elevation: elevationSm,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryTeal,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: textPrimary,
      size: 24,
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      color: mediumGray,
      thickness: 1,
      space: spacingMd,
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primaryTeal,
      unselectedItemColor: textHint,
      type: BottomNavigationBarType.fixed,
      elevation: elevationMd,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: lightTeal,
      secondary: primaryTeal,
      surface: darkSurface,
      error: errorRed,
      onPrimary: white,
      onSecondary: white,
      onSurface: darkTextPrimary,
      onError: white,
    ),
    scaffoldBackgroundColor: darkBackground,
    extensions: [AppThemeExtras.dark],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkTextPrimary),
      bodyMedium: TextStyle(color: darkTextPrimary),
      bodySmall: TextStyle(color: darkTextSecondary),
      titleLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
      labelLarge: TextStyle(color: darkTextPrimary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkTeal,
      foregroundColor: white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: white),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: lightTeal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      hintStyle: const TextStyle(color: darkTextSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightTeal,
        foregroundColor: white,
        elevation: elevationSm,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: lightTeal),
    ),
    iconTheme: const IconThemeData(color: darkTextPrimary, size: 24),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A3A3A),
      thickness: 1,
      space: spacingMd,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: lightTeal,
      unselectedItemColor: darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: elevationMd,
    ),
  );
  
  // Box Decoration for Glass Effect
  static BoxDecoration glassDecoration({
    Color? color,
    double blur = 10,
    double opacity = 0.8,
  }) {
    return BoxDecoration(
      color: (color ?? white).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: white.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Shadow for Cards
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  // Shadow for Floating Elements
  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
