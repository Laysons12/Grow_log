import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Global dark mode flag updated by main / theme changes
  static bool isDark = true;

  // Colors
  static const Color creamBg = Color(0xFFFAF7F0);
  static const Color deepTeal = Color(0xFF085041);
  static const Color secondaryTeal = Color(0xFF0F6E56);
  static const Color lightTeal = Color(0xFFE1F5EE);
  static const Color midTeal = Color(0xFF5DCAA5);
  static const Color darkText = Color(0xFF04342C);
  static const Color mutedText = Color(0xFF7C7567);
  static const Color cardBorderColor = Color(0xFFD9D2C2);
  static const Color cardBgColor = Color(0xFFFFFFFF);

  static Color get darkBg => creamBg;
  static Color get cardBg => cardBgColor;
  static const Color accentBlue = deepTeal;
  static const Color successGreen = secondaryTeal;
  static const Color warningYellow = Color(0xFFD4AF37);
  static Color get textPrimary => darkText;
  static Color get textSecondary => mutedText;
  static Color get borderColor => cardBorderColor;

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 12; // 10-12px radius as requested
  static const double radiusXl = 12;

  // Light mode constants for direct use
  static const Color lightBg = creamBg;
  static const Color lightCard = cardBgColor;
  static const Color lightBorder = cardBorderColor;
  static const Color lightTextPrimary = darkText;
  static const Color lightTextSecondary = mutedText;

  // Get the dark theme (styled with Teal/Cream palette)
  static ThemeData darkTheme() {
    return _buildTheme();
  }

  // Get the light theme (styled with Teal/Cream palette)
  static ThemeData lightTheme() {
    return _buildTheme();
  }

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // Set light brightness so text defaults correctly
      scaffoldBackgroundColor: creamBg,
      cardColor: cardBgColor,
      dividerColor: cardBorderColor,
      appBarTheme: AppBarTheme(
        backgroundColor: creamBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500, // medium weight
          color: darkText,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w500, // medium weight
          color: darkText,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400, // regular weight
          color: darkText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mutedText,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mutedText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: deepTeal, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: mutedText, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightTeal,
        selectedColor: deepTeal,
        labelStyle: const TextStyle(color: darkText),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: cardBorderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      cardTheme: CardTheme(
        color: cardBgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: cardBorderColor),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: deepTeal,
        secondary: secondaryTeal,
        surface: cardBgColor,
        error: Color(0xFFD32F2F),
      ),
    );
  }
}

// Custom extensions for easier access
extension TextThemeExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
