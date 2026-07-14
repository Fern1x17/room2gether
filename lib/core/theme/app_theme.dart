import 'package:flutter/material.dart';

/// Paleta oficial de Room2gether (identidad visual 2026-07).
///
/// Los valores del modo claro son la fuente de verdad de la marca.
/// Los del modo oscuro son una derivación: mismos tonos de la paleta,
/// ajustados en luminosidad para mantener contraste sobre fondos oscuros.
abstract final class AppColors {
  // --- Modo claro (paleta oficial) ---
  static const primary = Color(0xFFFF6B5B); // CTA, acento
  static const secondary = Color(0xFF1B3A5C);
  static const background = Color(0xFFFFF8F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5F7A94);
  static const textMuted = Color(0xFF8A7A74);
  static const border = Color(0xFFE3D5CF);
  static const accent = Color(0xFFFFB84D); // destacados

  // --- Modo oscuro (derivada) ---
  static const darkBackground = Color(0xFF1A1512);
  static const darkSurface = Color(0xFF241D19);
  static const darkSurfaceHigh = Color(0xFF2E2620);
  static const darkSecondary = Color(0xFF92B4D7);
  static const darkTextPrimary = Color(0xFFF2EDEA);
  static const darkTextSecondary = Color(0xFF9FB6CB);
  static const darkTextMuted = Color(0xFFA6968D);
  static const darkBorder = Color(0xFF4A403A);
}

class AppTheme {
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFDAD5),
    onPrimaryContainer: Color(0xFF40100A),
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD7E4F2),
    onSecondaryContainer: Color(0xFF12293F),
    tertiary: AppColors.accent,
    onTertiary: AppColors.textPrimary,
    tertiaryContainer: Color(0xFFFFE3BC),
    onTertiaryContainer: Color(0xFF2A1800),
    // Rojo estándar de Material 3: la paleta no define un rojo de error propio.
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFFFBF9),
    surfaceContainer: AppColors.background,
    surfaceContainerHigh: Color(0xFFFBF1EC),
    surfaceContainerHighest: Color(0xFFF6EAE4),
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    inverseSurface: Color(0xFF322A25),
    onInverseSurface: Color(0xFFF6EAE4),
    inversePrimary: Color(0xFFFFB4A8),
    surfaceTint: AppColors.primary,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF7A2318),
    onPrimaryContainer: Color(0xFFFFDAD5),
    secondary: AppColors.darkSecondary,
    onSecondary: Color(0xFF0F2740),
    secondaryContainer: Color(0xFF2E4866),
    onSecondaryContainer: Color(0xFFD7E4F2),
    tertiary: AppColors.accent,
    onTertiary: Color(0xFF2A1800),
    tertiaryContainer: Color(0xFF5C3D00),
    onTertiaryContainer: Color(0xFFFFE3BC),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    surfaceContainerLowest: Color(0xFF14100D),
    surfaceContainerLow: Color(0xFF201A16),
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceHigh,
    surfaceContainerHighest: Color(0xFF392F28),
    outline: AppColors.darkBorder,
    outlineVariant: Color(0xFF382F29),
    inverseSurface: AppColors.darkTextPrimary,
    onInverseSurface: Color(0xFF322A25),
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  );

  static final light = _buildTheme(
    _lightScheme,
    scaffoldBackground: AppColors.background,
    mutedText: AppColors.textMuted,
  );

  static final dark = _buildTheme(
    _darkScheme,
    scaffoldBackground: AppColors.darkBackground,
    mutedText: AppColors.darkTextMuted,
  );

  static ThemeData _buildTheme(
    ColorScheme scheme, {
    required Color scaffoldBackground,
    required Color mutedText,
  }) {
    final radius8 = BorderRadius.circular(8);

    OutlineInputBorder inputBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: radius8,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: radius8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: radius8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.secondary,
          side: BorderSide(color: scheme.secondary),
          shape: RoundedRectangleBorder(borderRadius: radius8),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: mutedText),
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        disabledBorder: inputBorder(scheme.outline),
        focusedBorder: inputBorder(scheme.primary, width: 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, width: 2),
      ),
    );
  }
}
