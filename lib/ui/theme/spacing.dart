/// Spacing scale for TTRPG Session Tracker.
/// Consistent 4px base unit per FRONTEND_GUIDELINES.md.
abstract final class Spacing {
  /// 2px - Tight gaps
  static const double xxs = 2;

  /// 4px - Icon padding, tight spacing
  static const double xs = 4;

  /// 8px - Compact element spacing
  static const double sm = 8;

  /// 16px - Default padding/margin
  static const double md = 16;

  /// 24px - Section spacing
  static const double lg = 24;

  /// 32px - Large section gaps
  static const double xl = 32;

  /// 48px - Page-level spacing
  static const double xxl = 48;

  /// 64px - Major section breaks
  static const double xxxl = 64;

  // ============================================
  // LAYOUT CONSTANTS
  // ============================================

  /// Maximum content width (like Notion/Obsidian)
  static const double maxContentWidth = 800;

  /// Side padding for desktop (> 1024px)
  static const double desktopSidePadding = 32;

  /// Side padding for tablet (600px - 1024px)
  static const double tabletSidePadding = 24;

  /// Side padding for mobile (< 600px)
  static const double mobileSidePadding = 16;

  // ============================================
  // COMPONENT CONSTANTS
  // ============================================

  /// Card border radius
  static const double cardRadius = 8;

  /// Card padding
  static const double cardPadding = 16;

  /// Button border radius
  static const double buttonRadius = 8;

  /// Button height (touch-friendly, 44px minimum)
  static const double buttonHeight = 44;

  /// Button horizontal padding
  static const double buttonPaddingHorizontal = 16;

  /// Form field height
  static const double fieldHeight = 48;

  /// Form field border radius
  static const double fieldRadius = 6;

  /// Spacing between form fields
  static const double fieldSpacing = 16;

  /// List item vertical padding
  static const double listItemPaddingVertical = 12;

  /// List item horizontal padding
  static const double listItemPaddingHorizontal = 16;

  /// Status badge border radius
  static const double badgeRadius = 12;

  /// Status badge horizontal padding
  static const double badgePaddingHorizontal = 8;

  /// Status badge vertical padding
  static const double badgePaddingVertical = 4;

  /// Default icon size
  static const double iconSize = 24;

  /// Compact icon size
  static const double iconSizeCompact = 20;

  /// Emphasized icon size
  static const double iconSizeLarge = 28;

  // ============================================
  // BREAKPOINTS
  // ============================================

  /// Mobile breakpoint (< 600px)
  static const double breakpointMobile = 600;

  /// Tablet breakpoint (600px - 1024px)
  static const double breakpointTablet = 1024;
}
