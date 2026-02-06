import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Theme definitions for TTRPG Session Tracker.
/// Light and dark themes per FRONTEND_GUIDELINES.md.
abstract final class AppTheme {
  /// Light theme for the app.
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      secondary: AppColors.lightPrimary,
      onSecondary: AppColors.lightOnPrimary,
      error: AppColors.lightError,
      onError: AppColors.lightOnPrimary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      outline: AppColors.lightOutline,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  /// Dark theme for the app.
  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      secondary: AppColors.darkPrimary,
      onSecondary: AppColors.darkOnPrimary,
      error: AppColors.darkError,
      onError: AppColors.darkOnPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      outline: AppColors.darkOutline,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final backgroundColor =
        isLight ? AppColors.lightBackground : AppColors.darkBackground;
    final onBackgroundColor =
        isLight ? AppColors.lightOnBackground : AppColors.darkOnBackground;
    final onSurfaceVariantColor = isLight
        ? AppColors.lightOnSurfaceVariant
        : AppColors.darkOnSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: onBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.xl.copyWith(color: onBackgroundColor),
      ),

      // Text
      textTheme: TextTheme(
        displayLarge: AppTypography.xxl.copyWith(color: onBackgroundColor),
        displayMedium: AppTypography.xl.copyWith(color: onBackgroundColor),
        displaySmall: AppTypography.lg.copyWith(color: onBackgroundColor),
        headlineLarge: AppTypography.xxl.copyWith(color: onBackgroundColor),
        headlineMedium: AppTypography.xl.copyWith(color: onBackgroundColor),
        headlineSmall: AppTypography.lg.copyWith(color: onBackgroundColor),
        titleLarge: AppTypography.lg.copyWith(color: onBackgroundColor),
        titleMedium: AppTypography.base.copyWith(
          color: onBackgroundColor,
          fontWeight: AppTypography.weightSemiBold,
        ),
        titleSmall: AppTypography.sm.copyWith(
          color: onBackgroundColor,
          fontWeight: AppTypography.weightSemiBold,
        ),
        bodyLarge: AppTypography.base.copyWith(color: onBackgroundColor),
        bodyMedium: AppTypography.sm.copyWith(color: colorScheme.onSurface),
        bodySmall: AppTypography.xs.copyWith(color: onSurfaceVariantColor),
        labelLarge: AppTypography.button.copyWith(color: onBackgroundColor),
        labelMedium: AppTypography.label.copyWith(color: onBackgroundColor),
        labelSmall: AppTypography.xs.copyWith(color: onSurfaceVariantColor),
      ),

      // Card
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
          side: BorderSide(color: colorScheme.outline),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, Spacing.buttonHeight),
          padding:
              const EdgeInsets.symmetric(horizontal: Spacing.buttonPaddingHorizontal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.buttonRadius),
          ),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),

      // Outlined Button (Secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, Spacing.buttonHeight),
          padding:
              const EdgeInsets.symmetric(horizontal: Spacing.buttonPaddingHorizontal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.buttonRadius),
          ),
          side: BorderSide(color: colorScheme.primary),
          textStyle: AppTypography.button,
        ),
      ),

      // Text Button (Tertiary)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, Spacing.buttonHeight),
          padding:
              const EdgeInsets.symmetric(horizontal: Spacing.buttonPaddingHorizontal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: AppTypography.label.copyWith(color: onSurfaceVariantColor),
        hintStyle: AppTypography.base.copyWith(color: onSurfaceVariantColor),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: IconThemeData(
        color: onBackgroundColor,
        size: Spacing.iconSize,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.listItemPaddingHorizontal,
          vertical: Spacing.listItemPaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }
}
