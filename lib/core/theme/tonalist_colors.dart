import 'package:flutter/material.dart';

/// Paleta canónica Tonalist (ver `.cursorrules`).
abstract final class TonalistColors {
  static const azulHorizonte = Color(0xFF1A4463);
  static const crema = Color(0xFFFBF9F1);
  static const rojoManta = Color(0xFFD34836);
  static const ocrePremium = Color(0xFFE8D48B);

  /// Variante lección: degradado del header y fondo cálido.
  static const headerDeep = Color(0xFF0E3248);
  static const headerMid = azulHorizonte;
  static const headerLight = Color(0xFF2A6B7C);
  static const lessonFondoArriba = Color(0xFFE8E4DB);
  static const lessonFondoAbajo = Color(0xFFF7F4EC);

  /// Degradado canónico de todos los headers orgánicos (igual que lecciones).
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerDeep, headerMid, headerLight],
  );

  /// Rojo más oscuro para degradado de CTAs de acción.
  static const ctaRedDark = Color(0xFFB83A2A);

  /// Degradado para botones CTA principales (comprar, guardar, entrar…).
  static const ctaRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rojoManta, ctaRedDark],
  );
}
