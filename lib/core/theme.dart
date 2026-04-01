import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra Modern Palette
  static const Color primaryAccent = Color(0xFF8A2BE2); // Vibrant Purple
  static const Color secondaryAccent = Color(0xFF00FFCC); // Neon Teal
  
  // Backgrounds
  static const Color bgDark = Color(0xFF0B0F19); 
  static const Color surfaceDark = Color(0xFF151D2A); 
  static const Color surfaceDarkLighter = Color(0xFF1F2937); 
  
  // High Contrast Light Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  
  // Text
  static const Color textLight = Color(0xFF0F172A); // Darker for readability
  static const Color textDark = Color(0xFFF9FAFB);
  static const Color textMutedLight = Color(0xFF64748B); // Better contrast for light mode
  static const Color textMutedDark = Color(0xFF9CA3AF);

  // Status
  static const Color error = Color(0xFFFF4C4C);
  static const Color success = Color(0xFF22C55E); // Richer green
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryAccent,
        secondary: Color(0xFF0D9488), // More teal-ish for light mode
        surface: surfaceLight,
        onSurface: textLight,
        error: error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: _inputDecoration(isDark: false),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: false),
      cardTheme: _cardTheme(isDark: false),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: surfaceDark,
        onSurface: Colors.white,
        error: error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: _inputDecoration(isDark: true),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: true),
      cardTheme: _cardTheme(isDark: true),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: secondaryAccent,
        unselectedItemColor: textMutedDark,
      ),
    );
  }

  static InputDecorationTheme _inputDecoration({required bool isDark}) {
    final surfaceColor = isDark ? surfaceDark : Colors.white;
    final borderColor = isDark ? surfaceDarkLighter : borderLight;
    
    return InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(color: isDark ? textMutedDark : textMutedLight),
      hintStyle: TextStyle(color: isDark ? textMutedDark : textMutedLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({required bool isDark}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.white,
        elevation: isDark ? 8 : 2,
        shadowColor: primaryAccent.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  static CardThemeData _cardTheme({required bool isDark}) {
    return CardThemeData(
      color: isDark ? surfaceDark : Colors.white,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark ? const BorderSide(color: surfaceDarkLighter) : const BorderSide(color: borderLight),
      ),
      margin: EdgeInsets.all(isDark ? 0 : 8),
    );
  }
}
