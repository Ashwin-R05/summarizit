import 'package:flutter/material.dart';

/// Manages theme state (light/dark) across the app.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

/// App color palette that adapts to light / dark mode.
class AppColors {
  // ── Brand Accents ──
  static const Color primaryPurple = Color(0xFF7C5CFC);
  static const Color accentTeal = Color(0xFF3DD6D0);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentOrange = Color(0xFFFF9F43);

  static const List<Color> primaryGradient = [primaryPurple, accentTeal];
  static const List<Color> warmGradient = [accentPink, accentOrange];

  // ── Dark palette ──
  static const Color darkBg = Color(0xFF0A0A1A);
  static const Color darkSurface = Color(0xFF13132B);
  static const Color darkCard = Color(0xFF1C1C3A);
  static const Color darkBorder = Color(0xFF2A2A4A);
  static const Color darkText = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFF9898B8);

  // ── Light palette ──
  static const Color lightBg = Color(0xFFF5F3FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E5F0);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B8D);

  // ── Dynamic getters ──
  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color text(bool isDark) => isDark ? darkText : lightText;
  static Color textSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color cardOverlay(bool isDark) =>
      isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.85);
  static Color shadow(bool isDark) =>
      isDark
          ? Colors.black.withValues(alpha: 0.4)
          : const Color(0xFF7C5CFC).withValues(alpha: 0.08);
}
