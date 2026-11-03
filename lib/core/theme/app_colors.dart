import 'package:flutter/material.dart';

/// Palette taken from the Kayflix web frontend so both clients match.
class AppColors {
  AppColors._();

  static const Color red = Color(0xFFE50914);
  static const Color redDark = Color(0xFFB20710);
  static const Color background = Color(0xFF0B0B0B);
  static const Color surface = Color(0xFF141414);
  static const Color card = Color(0xFF181818);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF808080);
  static const Color green = Color(0xFF46D369);
  static const Color border = Color(0xFF2A2A2A);
  static const Color danger = Color(0xFFE87C03);

  static const List<List<Color>> _posterPalettes = [
    [Color(0xFF7F1D1D), Color(0xFF1C1917)],
    [Color(0xFF0E7490), Color(0xFF082F49)],
    [Color(0xFF4C1D95), Color(0xFF1E1B4B)],
    [Color(0xFF9A3412), Color(0xFF1C1917)],
    [Color(0xFF065F46), Color(0xFF022C22)],
    [Color(0xFF831843), Color(0xFF1F0A1E)],
    [Color(0xFF1E3A8A), Color(0xFF0B1120)],
    [Color(0xFF713F12), Color(0xFF1C1208)],
  ];

  /// Deterministic gradient so a movie always looks the same.
  static List<Color> posterGradient(int seed) {
    final index = seed.abs() % _posterPalettes.length;
    return _posterPalettes[index];
  }

  static LinearGradient posterGradientFor(int seed) {
    final colors = posterGradient(seed);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}
