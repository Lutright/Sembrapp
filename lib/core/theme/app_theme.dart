import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema de Sembrapp: Diseñado para ser ultra-legible en el campo.
/// Prioriza botones grandes, colores tierra y tipografía clara.
final class AppTheme {
  AppTheme._();

  // Identidad visual de Sembrapp
  static const Color _primaryRed = Color(0xFFD34836); // Rojo manta
  static const Color _mountainBlue = Color(0xFF1A4463); // Azul montaña
  static const Color _earthOcre = Color(0xFF6D5E00); // Tono tierra
  static const Color _backgroundCrema = Color(0xFFFBF9F1); // Fondo orgánico

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: _mountainBlue,
      brightness: Brightness.light,
      primary: _mountainBlue,
      onPrimary: Colors.white,
      secondary: _primaryRed,
      onSecondary: Colors.white,
      tertiary: _earthOcre,
      surface: _backgroundCrema,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: base.surface,

      // Tipografía global Montserrat
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        displayLarge: TextStyle(
            fontSize: 40, fontWeight: FontWeight.bold, color: base.onSurface),
        headlineSmall: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: base.onSurface),
        titleLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: base.onSurface),
        bodyLarge: TextStyle(fontSize: 18, color: base.onSurface),
        bodyMedium: TextStyle(fontSize: 16, color: base.onSurface),
      ),

      // Barra superior limpia
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: base.surface,
        foregroundColor: base.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0, // Evita que cambie de color al hacer scroll
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: base.onSurface,
        ),
      ),

      // Botones "gigantes" para fácil acceso
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(_primaryRed),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(60)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),

      // Inputs con contraste para uso bajo el sol
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _mountainBlue, width: 2.5),
        ),
      ),

      // CardTheme
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
