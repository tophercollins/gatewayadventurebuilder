import 'package:flutter/material.dart';

/// Color palette for TTRPG Session Tracker.
/// Defines light and dark mode colors per FRONTEND_GUIDELINES.md.
abstract final class AppColors {
  // ============================================
  // LIGHT MODE
  // ============================================

  /// Page background - #FFFFFF
  static const Color lightBackground = Color(0xFFFFFFFF);

  /// Cards, panels - #F7F7F7
  static const Color lightSurface = Color(0xFFF7F7F7);

  /// Hover states, secondary surfaces - #EEEEEE
  static const Color lightSurfaceVariant = Color(0xFFEEEEEE);

  /// Primary text - #1A1A1A
  static const Color lightOnBackground = Color(0xFF1A1A1A);

  /// Secondary text - #333333
  static const Color lightOnSurface = Color(0xFF333333);

  /// Tertiary text, placeholders - #666666
  static const Color lightOnSurfaceVariant = Color(0xFF666666);

  /// Buttons, links, active states - #2563EB
  static const Color lightPrimary = Color(0xFF2563EB);

  /// Text on primary - #FFFFFF
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  /// Borders, dividers - #D1D5DB
  static const Color lightOutline = Color(0xFFD1D5DB);

  /// Error states - #DC2626
  static const Color lightError = Color(0xFFDC2626);

  /// Success states - #16A34A
  static const Color lightSuccess = Color(0xFF16A34A);

  // ============================================
  // DARK MODE
  // ============================================

  /// Page background - #1A1A1A
  static const Color darkBackground = Color(0xFF1A1A1A);

  /// Cards, panels - #252525
  static const Color darkSurface = Color(0xFF252525);

  /// Hover states, secondary surfaces - #333333
  static const Color darkSurfaceVariant = Color(0xFF333333);

  /// Primary text - #E5E5E5
  static const Color darkOnBackground = Color(0xFFE5E5E5);

  /// Secondary text - #CCCCCC
  static const Color darkOnSurface = Color(0xFFCCCCCC);

  /// Tertiary text, placeholders - #999999
  static const Color darkOnSurfaceVariant = Color(0xFF999999);

  /// Buttons, links, active states - #3B82F6
  static const Color darkPrimary = Color(0xFF3B82F6);

  /// Text on primary - #FFFFFF
  static const Color darkOnPrimary = Color(0xFFFFFFFF);

  /// Borders, dividers - #404040
  static const Color darkOutline = Color(0xFF404040);

  /// Error states - #EF4444
  static const Color darkError = Color(0xFFEF4444);

  /// Success states - #22C55E
  static const Color darkSuccess = Color(0xFF22C55E);

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Recording indicator - light mode
  static const Color lightStatusRecording = Color(0xFFDC2626);

  /// Processing/transcribing - light mode
  static const Color lightStatusProcessing = Color(0xFFF59E0B);

  /// Ready to review - light mode
  static const Color lightStatusComplete = Color(0xFF16A34A);

  /// Waiting for connection - light mode
  static const Color lightStatusQueued = Color(0xFF6B7280);

  /// Recording indicator - dark mode
  static const Color darkStatusRecording = Color(0xFFEF4444);

  /// Processing/transcribing - dark mode
  static const Color darkStatusProcessing = Color(0xFFFBBF24);

  /// Ready to review - dark mode
  static const Color darkStatusComplete = Color(0xFF22C55E);

  /// Waiting for connection - dark mode
  static const Color darkStatusQueued = Color(0xFF9CA3AF);
}

/// Extension to get status colors based on brightness.
extension StatusColors on Brightness {
  Color get recording => this == Brightness.light
      ? AppColors.lightStatusRecording
      : AppColors.darkStatusRecording;

  Color get processing => this == Brightness.light
      ? AppColors.lightStatusProcessing
      : AppColors.darkStatusProcessing;

  Color get complete => this == Brightness.light
      ? AppColors.lightStatusComplete
      : AppColors.darkStatusComplete;

  Color get queued => this == Brightness.light
      ? AppColors.lightStatusQueued
      : AppColors.darkStatusQueued;

  Color get success =>
      this == Brightness.light ? AppColors.lightSuccess : AppColors.darkSuccess;
}
