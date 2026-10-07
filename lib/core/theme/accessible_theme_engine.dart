import 'dart:math';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Available accessibility theme presets
enum AccessibleThemeMode {
  system('System Default', Icons.brightness_auto_rounded),
  light('Stitch Clean Light', Icons.light_mode_rounded),
  dark('Obsidian Dark', Icons.dark_mode_rounded),
  highContrastDark('High Contrast (WCAG AAA)', Icons.contrast_rounded),
  highContrastLight('High Contrast Light', Icons.brightness_high_rounded);

  final String title;
  final IconData icon;
  const AccessibleThemeMode(this.title, this.icon);
}

/// Engine for generating WCAG 2.1 AA/AAA compliant theme data and measuring contrast ratios
class AccessibleThemeEngine {
  /// Calculate relative luminance of a color according to W3C WCAG 2.1 guidelines
  static double calculateRelativeLuminance(Color color) {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;

    r = (r <= 0.03928) ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = (g <= 0.03928) ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = (b <= 0.03928) ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate contrast ratio between two colors (ranging from 1.0 to 21.0)
  static double calculateContrastRatio(Color foreground, Color background) {
    final l1 = calculateRelativeLuminance(foreground);
    final l2 = calculateRelativeLuminance(background);

    final lighter = max(l1, l2);
    final darker = min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check whether contrast satisfies WCAG AA (>= 4.5:1)
  static bool satisfiesWcagAA(Color fg, Color bg) => calculateContrastRatio(fg, bg) >= 4.5;

  /// Check whether contrast satisfies WCAG AAA (>= 7.0:1)
  static bool satisfiesWcagAAA(Color fg, Color bg) => calculateContrastRatio(fg, bg) >= 7.0;

  /// Build standard light theme
  static ThemeData buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        error: AppColors.error,
        onError: AppColors.onError,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
    );
  }

  /// Build standard modern dark theme
  static ThemeData buildDarkTheme() {
    const darkBg = Color(0xFF111827); // Gray 900
    const darkSurface = Color(0xFF1F2937); // Gray 800
    const darkText = Color(0xFFF9FAFB); // Gray 50
    const darkPrimary = Color(0xFF3B82F6); // Blue 500

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Color(0xFF0F172A),
        surface: darkSurface,
        onSurface: darkText,
        secondary: Color(0xFF94A3B8),
        onSecondary: Color(0xFF0F172A),
        error: Color(0xFFF87171),
        onError: Color(0xFF000000),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF374151)),
        ),
      ),
    );
  }

  /// Build ultra-accessible High Contrast Dark theme (WCAG AAA >= 7:1)
  static ThemeData buildHighContrastDarkTheme() {
    const pureBlack = Color(0xFF000000);
    const elevatedBlack = Color(0xFF0A0A0A);
    const pureWhite = Color(0xFFFFFFFF);
    const vividYellow = Color(0xFFFFD700); // Maximum contrast for focus/accents

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      colorScheme: const ColorScheme.dark(
        primary: vividYellow,
        onPrimary: pureBlack,
        surface: elevatedBlack,
        onSurface: pureWhite,
        secondary: pureWhite,
        onSecondary: pureBlack,
        error: Color(0xFFFF4D4D),
        onError: pureBlack,
      ),
      cardTheme: CardThemeData(
        color: elevatedBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: pureWhite, width: 1.5),
        ),
      ),
    );
  }
}
