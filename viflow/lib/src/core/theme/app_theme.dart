import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana Renkler
  static const Color primaryColor = Color(0xFF2D9CDB); // Su Mavisi

  // Light Mode Renkleri
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightCard = Colors.white;
  static const Color lightText = Colors.black87;

  // Dark Mode Renkleri
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE0E0E0);

  // --- AYDINLIK TEMA ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryColor,
      cardColor: lightCard,

      // Renk Şeması (Dialoglar rengini buradan alacak)
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        surface: lightCard, // Dialog arkaplanı
        onSurface: lightText, // Dialog yazısı
      ),

      fontFamily: GoogleFonts.inter().fontFamily,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: lightText),
        titleTextStyle: TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        modalBackgroundColor: lightCard,
      ),
    );
  }

  // --- KARANLIK TEMA ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryColor,
      cardColor: darkCard,

      // Renk Şeması
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: darkCard, // Dialog arkaplanı (Otomatik)
        onSurface: darkText, // Dialog yazısı (Otomatik)
      ),

      fontFamily: GoogleFonts.inter().fontFamily,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        modalBackgroundColor: darkCard,
      ),

      // Not: DialogTheme bloğunu kaldırdık.
      // ColorScheme.dark(surface: darkCard) sayesinde dialoglar zaten koyu gri olacak.
    );
  }
}