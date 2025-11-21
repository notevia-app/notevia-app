import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2D9CDB);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightCard = Colors.white;
  static const Color lightText = Colors.black87;
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground, primaryColor: primaryColor, cardColor: lightCard,
      colorScheme: const ColorScheme.light(primary: primaryColor, surface: lightCard, onSurface: lightText),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: lightText), titleTextStyle: TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.bold)),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: lightCard, modalBackgroundColor: lightCard),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground, primaryColor: primaryColor, cardColor: darkCard,
      colorScheme: const ColorScheme.dark(primary: primaryColor, surface: darkCard, onSurface: darkText),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: darkText), titleTextStyle: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold)),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: darkCard, modalBackgroundColor: darkCard),
    );
  }
}