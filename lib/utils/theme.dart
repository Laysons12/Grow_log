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

  static Color get darkBg => isDark ? const Color(0xFF000000) : creamBg;
  static Color get cardBg => isDark ? const Color(0xFF1C1C1E) : cardBgColor;
  static Color get textPrimary => isDark ? Colors.white : darkText;
  static Color get textSecondary => isDark ? const Color(0xFF8E8E93) : mutedText;
  static Color get borderColor => isDark ? const Color(0xFF2C2C2E) : cardBorderColor;

  static Color get accentBlue => isDark ? Colors.white : deepTeal;
  static Color get successGreen => isDark ? const Color(0xFFE5E5EA) : secondaryTeal;
  static const Color warningYellow = Color(0xFFD4AF37);

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
    return _buildTheme(true);
  }

  // Get the light theme (styled with Teal/Cream palette)
  static ThemeData lightTheme() {
    return _buildTheme(false);
  }

  static ThemeData _buildTheme(bool dark) {
    final bg = dark ? const Color(0xFF000000) : creamBg;
    final card = dark ? const Color(0xFF1C1C1E) : cardBgColor;
    final border = dark ? const Color(0xFF2C2C2E) : cardBorderColor;
    final txtPrimary = dark ? Colors.white : darkText;
    final txtSecondary = dark ? const Color(0xFF8E8E93) : mutedText;
    final primaryAccent = dark ? Colors.white : deepTeal;

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500, // medium weight
          color: txtPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w500, // medium weight
          color: txtPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: txtPrimary,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: txtPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: txtPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: txtPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: txtPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400, // regular weight
          color: txtPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: txtSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: txtSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryAccent, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: txtSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: dark ? Colors.black : Colors.white,
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
        backgroundColor: dark ? const Color(0xFF2C2C2E) : lightTeal,
        selectedColor: primaryAccent,
        labelStyle: TextStyle(color: txtPrimary),
        secondaryLabelStyle: TextStyle(color: dark ? Colors.black : Colors.white),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepTeal,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: primaryAccent,
        secondary: secondaryTeal,
        surface: card,
        error: const Color(0xFFD32F2F),
      ),
    );
  }
}

// Custom extensions for easier access
extension TextThemeExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
