import 'package:flutter/material.dart';

/// Typography scale for TTRPG Session Tracker.
/// Uses system fonts only, per FRONTEND_GUIDELINES.md.
abstract final class AppTypography {
  // ============================================
  // TEXT SIZES
  // ============================================

  /// 12sp - Captions, timestamps, metadata
  static const double sizeXs = 12;

  /// 14sp - Secondary text, labels
  static const double sizeSm = 14;

  /// 16sp - Body text, default
  static const double sizeBase = 16;

  /// 18sp - Section headers
  static const double sizeLg = 18;

  /// 22sp - Page titles
  static const double sizeXl = 22;

  /// 28sp - Screen titles
  static const double size2xl = 28;

  // ============================================
  // LINE HEIGHTS
  // ============================================

  /// Line height for body text
  static const double lineHeightBody = 1.5;

  /// Line height for headings
  static const double lineHeightHeading = 1.2;

  // ============================================
  // FONT WEIGHTS
  // ============================================

  /// Regular weight for body text
  static const FontWeight weightRegular = FontWeight.w400;

  /// Semi-bold weight for headings
  static const FontWeight weightSemiBold = FontWeight.w600;

  // ============================================
  // TEXT STYLES
  // ============================================

  /// 12sp caption - timestamps, metadata
  static const TextStyle xs = TextStyle(
    fontSize: sizeXs,
    fontWeight: weightRegular,
    height: lineHeightBody,
  );

  /// 14sp small - secondary text, labels
  static const TextStyle sm = TextStyle(
    fontSize: sizeSm,
    fontWeight: weightRegular,
    height: lineHeightBody,
  );

  /// 16sp base - body text, default
  static const TextStyle base = TextStyle(
    fontSize: sizeBase,
    fontWeight: weightRegular,
    height: lineHeightBody,
  );

  /// 18sp large - section headers
  static const TextStyle lg = TextStyle(
    fontSize: sizeLg,
    fontWeight: weightSemiBold,
    height: lineHeightHeading,
  );

  /// 22sp extra large - page titles
  static const TextStyle xl = TextStyle(
    fontSize: sizeXl,
    fontWeight: weightSemiBold,
    height: lineHeightHeading,
  );

  /// 28sp 2x large - screen titles
  static const TextStyle xxl = TextStyle(
    fontSize: size2xl,
    fontWeight: weightSemiBold,
    height: lineHeightHeading,
  );

  // ============================================
  // LABEL STYLES
  // ============================================

  /// Label for form fields
  static const TextStyle label = TextStyle(
    fontSize: sizeSm,
    fontWeight: weightSemiBold,
    height: lineHeightBody,
  );

  /// Button text
  static const TextStyle button = TextStyle(
    fontSize: sizeBase,
    fontWeight: weightSemiBold,
    height: 1.0,
  );

  // ============================================
  // LAYOUT CONSTANTS
  // ============================================

  /// Maximum line width for reading comfort (72 characters)
  /// Approximate pixel width assuming average character width of ~8px
  static const double maxLineWidth = 576;
}
