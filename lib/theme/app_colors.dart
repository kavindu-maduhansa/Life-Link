import 'package:flutter/material.dart';

/// Centralised colour tokens for LifeLink's Light and Dark themes.
///
/// This is a [ThemeExtension] so any widget can reach the exact palette
/// via `Theme.of(context).extension<AppColors>()` (or the `context.colors`
/// shortcut below) instead of hard-coding hex values inside screens.
///
/// Semantic usage (kept consistent across the whole Doctor module):
///   critical -> blood-related / emergency / destructive actions
///   primary  -> brand identity, primary CTA, blood-group identity
///   accent   -> verification, operational links, selected navigation,
///               focus rings, secondary actions
///   success  -> verified / completed
///   warning  -> pending / low stock / needs attention
///   analytics-> a fourth chart series and non-critical analytics accents
///   textSecondary / border / disabled -> non-critical, informational
///
/// SOFT CONTAINERS
/// ---------------
/// Each status colour has a matching low-saturation `*Container` tone.
/// Status is shown as a tinted container + a saturated icon/border/text,
/// never as a large saturated fill - which is what keeps a screen full of
/// critical requests readable instead of a wall of red.
///
/// LIGHT vs DARK
/// -------------
/// The Dark palette is the one this module shipped with and is preserved
/// as-is. The Light palette was re-specified for this milestone to read
/// as a warm clinical surface rather than harsh white.
///
/// BACKWARD COMPATIBILITY
/// ----------------------
/// Every colour name that existed before this change still exists with
/// the same meaning, so any teammate's widget reading `context.colors.x`
/// keeps compiling and keeps getting a sensible colour. The new names are
/// additive.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.primary,
    required this.primaryContainer,
    required this.accent,
    required this.accentContainer,
    required this.champagne,
    required this.critical,
    required this.criticalContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.analytics,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.disabled,
    required this.chartPalette,
  });

  final Color background;
  final Color surface;

  /// A second surface tone, one step off [surface]. Used for input
  /// fills, inset rows and subtle grouping - not for cards.
  final Color elevatedSurface;

  /// Deep burgundy - the Doctor / Blood Bank module's identity colour.
  /// Used for the primary CTA, selected critical commands, blood-group
  /// identity badges and the brand mark.
  final Color primary;

  /// A soft burgundy wash for a selected row or an identity chip's
  /// background. Never used as a page background.
  final Color primaryContainer;

  /// Clinical teal - verification actions, operational links, selected
  /// navigation, focus indicators and secondary buttons. Having a second
  /// action colour is what stops every button being red.
  final Color accent;

  /// Pale teal container for an operational / healthy status block.
  final Color accentContainer;

  /// Champagne - the premium accent. Used sparingly for highlights
  /// (a "best match" ribbon, a subtle icon tint) - never as a large
  /// fill, per the "avoid excessive gold" visual direction.
  final Color champagne;

  /// Reserved for genuine critical and destructive meaning only. Not for
  /// ordinary navigation, neutral statistics or decoration.
  final Color critical;

  /// Pale rose container for a critical request block.
  final Color criticalContainer;

  final Color success;

  /// Soft sage container for a verified / success block.
  final Color successContainer;

  final Color warning;

  /// Light amber container for a low-stock / warning block.
  final Color warningContainer;

  /// Muted plum - a fourth analytics series, and the accent for
  /// non-urgent analytics sections.
  final Color analytics;

  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  /// Disabled controls and disabled text. A distinct token so a disabled
  /// control is never rendered as merely "faded secondary text".
  final Color disabled;

  /// #33 - Distinct hues for multi-series charts (pie/donut, stacked
  /// bars) so categories (e.g. the 8 blood groups) read apart at a
  /// glance. Kept muted/sophisticated rather than neon. Order is stable
  /// so the same category always gets the same colour, and the first
  /// four are the primary series (burgundy, teal, amber, plum).
  ///
  /// Charts also carry labels, legends or icons - colour is never the
  /// only channel.
  final List<Color> chartPalette;

  /// Light theme - warm porcelain surfaces, deep burgundy identity,
  /// clinical teal for operational states. Specified for the Milestone 02
  /// blood-bank UI pass.
  static const light = AppColors(
    background: Color(0xFFFAF7F6), // warm porcelain
    surface: Color(0xFFFFFFFF), // primary card
    elevatedSurface: Color(0xFFF5ECEE), // soft blush neutral
    primary: Color(0xFF8F1838), // deep burgundy
    primaryContainer: Color(0xFFF9DFE5), // soft burgundy tint
    accent: Color(0xFF087F8C), // clinical teal
    accentContainer: Color(0xFFDDF3F3), // pale teal
    champagne: Color(0xFFA98248),
    critical: Color(0xFFC62845), // critical red
    criticalContainer: Color(0xFFFCE8EC), // pale rose
    success: Color(0xFF267A5E), // clinical green
    successContainer: Color(0xFFE2F2EB), // soft sage
    warning: Color(0xFFC47A14), // warm amber
    warningContainer: Color(0xFFFBEFDC), // light amber tint
    analytics: Color(0xFF76556F), // muted plum
    textPrimary: Color(0xFF211A1D), // warm obsidian
    textSecondary: Color(0xFF6B6064), // muted taupe
    border: Color(0xFFE6DADD), // soft rose grey
    disabled: Color(0xFFB9AFB2), // muted grey
    chartPalette: [
      Color(0xFF8F1838), // burgundy
      Color(0xFF087F8C), // clinical teal
      Color(0xFFC47A14), // warm amber
      Color(0xFF76556F), // muted plum
      Color(0xFF267A5E), // clinical green
      Color(0xFFA98248), // champagne
      Color(0xFFC62845), // critical red
      Color(0xFF4E6E8C), // slate blue
    ],
  );

  /// Dark theme - "premium healthcare command center": near-black
  /// obsidian background/surfaces, a brighter champagne accent for
  /// legibility, burgundy still carrying the module identity.
  ///
  /// These values are unchanged from the build that shipped before this
  /// milestone; only the additive container/accent tokens are new.
  static const dark = AppColors(
    background: Color(0xFF0F0C0D),
    surface: Color(0xFF181315),
    elevatedSurface: Color(0xFF221B1E),
    primary: Color(0xFF6E1F3A),
    primaryContainer: Color(0xFF2E1720),
    accent: Color(0xFF4FA8B5),
    accentContainer: Color(0xFF122A2E),
    champagne: Color(0xFFD2B278),
    critical: Color(0xFFB83D52),
    criticalContainer: Color(0xFF2C171C),
    success: Color(0xFF3E8065),
    successContainer: Color(0xFF14231D),
    warning: Color(0xFFC98F3D),
    warningContainer: Color(0xFF2A2014),
    analytics: Color(0xFF9089B8),
    textPrimary: Color(0xFFF5EEE5),
    textSecondary: Color(0xFF9E9295),
    border: Color(0xFF332A2E),
    disabled: Color(0xFF6A5F63),
    chartPalette: [
      Color(0xFFD2B278), // champagne
      Color(0xFFB0577A), // brightened burgundy
      Color(0xFF5CA98A), // sage/success green
      Color(0xFF5C9AAD), // muted teal
      Color(0xFFC98860), // terracotta
      Color(0xFF9089B8), // dusty plum
      Color(0xFFC98F3D), // warm amber
      Color(0xFFB83D52), // muted red
    ],
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? elevatedSurface,
    Color? primary,
    Color? primaryContainer,
    Color? accent,
    Color? accentContainer,
    Color? champagne,
    Color? critical,
    Color? criticalContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? analytics,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? disabled,
    List<Color>? chartPalette,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      champagne: champagne ?? this.champagne,
      critical: critical ?? this.critical,
      criticalContainer: criticalContainer ?? this.criticalContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      analytics: analytics ?? this.analytics,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      disabled: disabled ?? this.disabled,
      chartPalette: chartPalette ?? this.chartPalette,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    final palette = <Color>[
      for (var i = 0; i < chartPalette.length; i++)
        Color.lerp(chartPalette[i], i < other.chartPalette.length ? other.chartPalette[i] : chartPalette[i], t)!,
    ];
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      champagne: Color.lerp(champagne, other.champagne, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      criticalContainer: Color.lerp(criticalContainer, other.criticalContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      analytics: Color.lerp(analytics, other.analytics, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      chartPalette: palette,
    );
  }
}

/// Shortcut so screens can write `context.colors.critical` instead of the
/// longer `Theme.of(context).extension<AppColors>()!` call everywhere.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
