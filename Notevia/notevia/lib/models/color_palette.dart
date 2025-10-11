import 'package:flutter/material.dart';

class ColorPalette {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color error;
  final Color onError;
  
  const ColorPalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.error,
    required this.onError,
  });
  
  ColorScheme toColorScheme(Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: error,
      onError: onError,
      surface: surface,
      onSurface: onSurface,
    );
  }
}

class AppColorPalettes {
  static const List<ColorPalette> lightPalettes = [
    // Ocean Blue
    ColorPalette(
      name: 'Ocean Blue',
      primary: Color(0xFF0077BE),
      secondary: Color(0xFF4FC3F7),
      accent: Color(0xFF00BCD4),
      background: Color(0xFFF8FAFB),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onBackground: Color(0xFF1A1A1A),
      onSurface: Color(0xFF1A1A1A),
      error: Color(0xFFD32F2F),
      onError: Color(0xFFFFFFFF),
    ),
    
    // Forest Green
    ColorPalette(
      name: 'Forest Green',
      primary: Color(0xFF2E7D32),
      secondary: Color(0xFF66BB6A),
      accent: Color(0xFF4CAF50),
      background: Color(0xFFF1F8E9),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onBackground: Color(0xFF1B5E20),
      onSurface: Color(0xFF1B5E20),
      error: Color(0xFFD32F2F),
      onError: Color(0xFFFFFFFF),
    ),
    
    // Sunset Orange
    ColorPalette(
      name: 'Sunset Orange',
      primary: Color(0xFFFF6F00),
      secondary: Color(0xFFFFB74D),
      accent: Color(0xFFFF9800),
      background: Color(0xFFFFF8E1),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onBackground: Color(0xFFE65100),
      onSurface: Color(0xFFE65100),
      error: Color(0xFFD32F2F),
      onError: Color(0xFFFFFFFF),
    ),
    
    // Royal Purple
    ColorPalette(
      name: 'Royal Purple',
      primary: Color(0xFF6A1B9A),
      secondary: Color(0xFFBA68C8),
      accent: Color(0xFF9C27B0),
      background: Color(0xFFF3E5F5),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onBackground: Color(0xFF4A148C),
      onSurface: Color(0xFF4A148C),
      error: Color(0xFFD32F2F),
      onError: Color(0xFFFFFFFF),
    ),
    
    // Rose Pink
    ColorPalette(
      name: 'Rose Pink',
      primary: Color(0xFFE91E63),
      secondary: Color(0xFFF48FB1),
      accent: Color(0xFFFF4081),
      background: Color(0xFFFCE4EC),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onBackground: Color(0xFF880E4F),
      onSurface: Color(0xFF880E4F),
      error: Color(0xFFD32F2F),
      onError: Color(0xFFFFFFFF),
    ),
  ];
  
  static const List<ColorPalette> darkPalettes = [
    // Ocean Blue Dark
    ColorPalette(
      name: 'Ocean Blue',
      primary: Color(0xFF4FC3F7),
      secondary: Color(0xFF0277BD),
      accent: Color(0xFF00E5FF),
      background: Color(0xFF0A0E13),
      surface: Color(0xFF1A1F25),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFFFFFFFF),
      onBackground: Color(0xFFE1F5FE),
      onSurface: Color(0xFFE1F5FE),
      error: Color(0xFFEF5350),
      onError: Color(0xFF000000),
    ),
    
    // Forest Green Dark
    ColorPalette(
      name: 'Forest Green',
      primary: Color(0xFF66BB6A),
      secondary: Color(0xFF1B5E20),
      accent: Color(0xFF69F0AE),
      background: Color(0xFF0D1B0F),
      surface: Color(0xFF1B2E1F),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFFFFFFFF),
      onBackground: Color(0xFFE8F5E8),
      onSurface: Color(0xFFE8F5E8),
      error: Color(0xFFEF5350),
      onError: Color(0xFF000000),
    ),
    
    // Sunset Orange Dark
    ColorPalette(
      name: 'Sunset Orange',
      primary: Color(0xFFFFB74D),
      secondary: Color(0xFFE65100),
      accent: Color(0xFFFFAB40),
      background: Color(0xFF1A0F08),
      surface: Color(0xFF2E1B10),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFF3E0),
      onSurface: Color(0xFFFFF3E0),
      error: Color(0xFFEF5350),
      onError: Color(0xFF000000),
    ),
    
    // Royal Purple Dark
    ColorPalette(
      name: 'Royal Purple',
      primary: Color(0xFFBA68C8),
      secondary: Color(0xFF4A148C),
      accent: Color(0xFFE1BEE7),
      background: Color(0xFF1A0D1F),
      surface: Color(0xFF2E1B35),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFFFFFFFF),
      onBackground: Color(0xFFF3E5F5),
      onSurface: Color(0xFFF3E5F5),
      error: Color(0xFFEF5350),
      onError: Color(0xFF000000),
    ),
    
    // Rose Pink Dark
    ColorPalette(
      name: 'Rose Pink',
      primary: Color(0xFFF48FB1),
      secondary: Color(0xFF880E4F),
      accent: Color(0xFFFF80AB),
      background: Color(0xFF1F0A14),
      surface: Color(0xFF351A25),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFCE4EC),
      onSurface: Color(0xFFFCE4EC),
      error: Color(0xFFEF5350),
      onError: Color(0xFF000000),
    ),
  ];
}