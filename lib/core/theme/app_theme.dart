import 'package:flutter/material.dart';

import 'appearance.dart';
import 'telega_tokens.dart';

/// Design token system for the Telegram Flutter client.
/// Dark theme only.
class AppTheme {
  AppTheme._();

  // Avatar color palette
  static const List<Color> avatarColors = [
    Color(0xFFE57373), // Red
    Color(0xFF81C784), // Green
    Color(0xFF64B5F6), // Blue
    Color(0xFFFFB74D), // Orange
    Color(0xFFBA68C8), // Purple
    Color(0xFF4DB6AC), // Teal
    Color(0xFFF06292), // Pink
    Color(0xFF9575CD), // Deep purple
  ];

  /// Dark theme parameterized by user appearance settings.
  static ThemeData dark(AppearanceSettings settings) {
    final accent = settings.accent.color;
    final accentHsl = HSLColor.fromColor(accent);

    // Darken accent for primaryContainer (used as a recessive accent surface).
    final primaryContainer = accentHsl
        .withLightness((accentHsl.lightness * 0.45).clamp(0.0, 1.0))
        .toColor();

    // Lighten accent for inversePrimary (used on inverse surfaces).
    final inversePrimary = accentHsl
        .withLightness((accentHsl.lightness * 1.6).clamp(0.0, 1.0))
        .toColor();

    // Tinted light shade for onPrimaryContainer (text on dark accent surface).
    final onPrimaryContainer = accentHsl.withLightness(0.92).toColor();

    // Pick onPrimary by accent luminance so filled buttons remain readable.
    final onPrimary = accent.computeLuminance() > 0.5
        ? const Color(0xFF1C1C1E)
        : Colors.white;

    final colorScheme = ColorScheme.dark(
      // Primary
      primary: accent,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,

      // Secondary
      secondary: const Color(0xFF8E8E93),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF3A3A3C),
      onSecondaryContainer: const Color(0xFFE5E5EA),

      // Surface (backgrounds)
      surface: const Color(0xFF1C1C1E),
      onSurface: const Color(0xFFE5E5EA),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF1C1C1E),
      surfaceContainer: const Color(0xFF2C2C2E),
      surfaceContainerHigh: const Color(0xFF3A3A3C),
      surfaceContainerHighest: const Color(0xFF48484A),

      // Outline (borders)
      outline: const Color(0xFF48484A),
      outlineVariant: const Color(0xFF3A3A3C),

      // Error
      error: const Color(0xFFFF453A),
      onError: Colors.white,
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),

      // Inverse
      inverseSurface: const Color(0xFFE5E5EA),
      onInverseSurface: const Color(0xFF1C1C1E),
      inversePrimary: inversePrimary,

      // Other
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[TelegaTokens.from(settings)],

      // Scaffold
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Divider
      dividerColor: colorScheme.outlineVariant,
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),

      // Card
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),

      // Icon
      iconTheme: IconThemeData(color: colorScheme.onSurface),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),

      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
