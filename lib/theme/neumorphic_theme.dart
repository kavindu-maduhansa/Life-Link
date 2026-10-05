import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'lifelink_design.dart';

/// Semantic elevation levels for LifeLink's Neumorphic / Soft UI system.
enum NeumorphicElevationLevel {
  /// Flat surface with no elevation (flush with background).
  flat,

  /// Subtle elevation for smaller elements: filter chips, segment controls, tags.
  low,

  /// Standard card elevation for dashboard tiles, list items, info panels.
  card,

  /// Raised tactile elevation for primary/secondary buttons and action pills.
  raised,

  /// Strong elevation for floating dialogs, alert sheets, command palette, FABs.
  high,

  /// Inset / recessed styling for form inputs, selected tabs, pressed buttons.
  inset,
}

/// Centralized Neumorphism tokens and decoration generators for LifeLink.
///
/// Combines soft directional highlights (top-left) with diffuse ambient shadows
/// (bottom-right) and crisp accessible borders to create a tactile, medical-grade
/// Soft UI that maintains clear boundary contrast on all screens.
class LLNeumorphism {
  const LLNeumorphism._();

  // ---------------------------------------------------------------------------
  // Shadow Tokens
  // ---------------------------------------------------------------------------

  /// Dual-shadow list for a given [elevation] and [brightness].
  static List<BoxShadow> shadows({
    required Brightness brightness,
    NeumorphicElevationLevel elevation = NeumorphicElevationLevel.card,
    Color? darkShadowColor,
    Color? highlightShadowColor,
  }) {
    if (elevation == NeumorphicElevationLevel.flat) {
      return const [];
    }

    final isDark = brightness == Brightness.dark;

    // Highlight (top-left light source)
    final lightColor =
        highlightShadowColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.92));

    // Dark shadow (bottom-right ambient occlusion)
    final shadowColor =
        darkShadowColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.65)
            : const Color(0xFF6B5860).withValues(alpha: 0.12));

    switch (elevation) {
      case NeumorphicElevationLevel.flat:
        return const [];

      case NeumorphicElevationLevel.low:
        return [
          BoxShadow(
            color: lightColor,
            offset: const Offset(-2, -2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: shadowColor,
            offset: const Offset(2, 2.5),
            blurRadius: 5,
            spreadRadius: 0,
          ),
        ];

      case NeumorphicElevationLevel.card:
        return [
          BoxShadow(
            color: lightColor,
            offset: const Offset(-3, -3),
            blurRadius: 7,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: shadowColor,
            offset: const Offset(3, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ];

      case NeumorphicElevationLevel.raised:
        return [
          BoxShadow(
            color: lightColor,
            offset: const Offset(-3, -3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: isDark ? 0.75 : 0.16),
            offset: const Offset(3, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ];

      case NeumorphicElevationLevel.high:
        return [
          BoxShadow(
            color: lightColor,
            offset: const Offset(-4, -4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: isDark ? 0.85 : 0.22),
            offset: const Offset(5, 7),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ];

      case NeumorphicElevationLevel.inset:
        // Inset is rendered using inner shadow simulation in decoration.
        return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Gradient Tokens
  // ---------------------------------------------------------------------------

  /// Subtle convex gradient to give raised surfaces a gentle tactile curve.
  static LinearGradient convexGradient({
    required Brightness brightness,
    Color? baseColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final base =
        baseColor ??
        (isDark ? const Color(0xFF1E171A) : const Color(0xFFFFFFFF));

    final topHighlight = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.04), base)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.6), base);

    final bottomShadow = isDark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.12), base)
        : Color.alphaBlend(
            const Color(0xFF6B5860).withValues(alpha: 0.04),
            base,
          );

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [topHighlight, base, bottomShadow],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Subtle concave / recessed gradient for pressed states and inputs.
  static LinearGradient concaveGradient({
    required Brightness brightness,
    Color? baseColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final base =
        baseColor ??
        (isDark ? const Color(0xFF151012) : const Color(0xFFF3EBED));

    final topShadow = isDark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.20), base)
        : Color.alphaBlend(
            const Color(0xFF6B5860).withValues(alpha: 0.08),
            base,
          );

    final bottomHighlight = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.02), base)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.4), base);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [topShadow, base, bottomHighlight],
      stops: const [0.0, 0.45, 1.0],
    );
  }

  // ---------------------------------------------------------------------------
  // Full Decorations
  // ---------------------------------------------------------------------------

  /// Standard Neumorphic Card decoration.
  static BoxDecoration cardDecoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? color,
    Color? borderColor,
    NeumorphicElevationLevel elevation = NeumorphicElevationLevel.card,
    bool isPressed = false,
  }) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final radius = borderRadius ?? BorderRadius.circular(LLRadius.card);
    final borderCol = borderColor ?? colors.border;

    if (isPressed) {
      return BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: radius,
        border: Border.all(color: borderCol.withValues(alpha: 0.8)),
        gradient: concaveGradient(
          brightness: brightness,
          baseColor: colors.elevatedSurface,
        ),
      );
    }

    return BoxDecoration(
      color: color ?? colors.surface,
      borderRadius: radius,
      border: Border.all(color: borderCol),
      boxShadow: shadows(brightness: brightness, elevation: elevation),
      gradient: convexGradient(
        brightness: brightness,
        baseColor: color ?? colors.surface,
      ),
    );
  }

  /// Neumorphic Button decoration (handles primary, secondary, and pressed states).
  static BoxDecoration buttonDecoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? color,
    Color? borderColor,
    bool isPressed = false,
    bool isOutlined = false,
    bool isPrimary = true,
  }) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final radius = borderRadius ?? BorderRadius.circular(LLRadius.control);

    if (isOutlined) {
      final baseColor = isPressed ? colors.accentContainer : colors.surface;
      return BoxDecoration(
        color: baseColor,
        borderRadius: radius,
        border: Border.all(
          color: isPressed
              ? colors.accent
              : colors.accent.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: isPressed
            ? const []
            : shadows(
                brightness: brightness,
                elevation: NeumorphicElevationLevel.low,
                darkShadowColor: colors.accent.withValues(alpha: 0.12),
              ),
      );
    }

    final buttonBase = color ?? (isPrimary ? colors.primary : colors.surface);

    if (isPressed) {
      return BoxDecoration(
        color: buttonBase,
        borderRadius: radius,
        border: Border.all(
          color: (borderColor ?? buttonBase).withValues(alpha: 0.8),
          width: 1.2,
        ),
        gradient: concaveGradient(
          brightness: brightness,
          baseColor: buttonBase,
        ),
      );
    }

    final elevation = isPrimary
        ? NeumorphicElevationLevel.raised
        : NeumorphicElevationLevel.low;

    return BoxDecoration(
      color: buttonBase,
      borderRadius: radius,
      border: Border.all(
        color: borderColor ?? (isPrimary ? colors.primary : colors.border),
        width: 1.0,
      ),
      boxShadow: shadows(
        brightness: brightness,
        elevation: elevation,
        darkShadowColor: isPrimary
            ? colors.primary.withValues(
                alpha: brightness == Brightness.dark ? 0.6 : 0.28,
              )
            : null,
      ),
      gradient: isPrimary
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.15),
                  buttonBase,
                ),
                buttonBase,
                Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.18),
                  buttonBase,
                ),
              ],
            )
          : convexGradient(brightness: brightness, baseColor: buttonBase),
    );
  }

  /// Neumorphic recessed input decoration for TextFormFields and Search inputs.
  static BoxDecoration inputDecoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    bool isFocused = false,
    bool hasError = false,
  }) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final radius = borderRadius ?? BorderRadius.circular(LLRadius.control);

    Color borderCol;
    double borderWidth;

    if (hasError) {
      borderCol = colors.critical;
      borderWidth = 1.8;
    } else if (isFocused) {
      borderCol = colors.accent;
      borderWidth = 1.8;
    } else {
      borderCol = colors.border;
      borderWidth = 1.0;
    }

    return BoxDecoration(
      color: colors.elevatedSurface,
      borderRadius: radius,
      border: Border.all(color: borderCol, width: borderWidth),
      gradient: concaveGradient(
        brightness: brightness,
        baseColor: colors.elevatedSurface,
      ),
    );
  }

  /// Generates raised shadows using the application's [colors] palette.
  static List<BoxShadow> raisedShadows(
    AppColors colors, {
    NeumorphicElevationLevel elevation = NeumorphicElevationLevel.card,
  }) {
    return [
      BoxShadow(
        color: colors.highlightShadow,
        offset: const Offset(-2, -2),
        blurRadius: 4,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: colors.darkShadow,
        offset: const Offset(2, 3),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
  }
}

/// Alias for [LLNeumorphism] providing intuitive access to Neumorphic tokens.
typedef NeumorphicTokens = LLNeumorphism;
