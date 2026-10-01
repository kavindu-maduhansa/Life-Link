import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the app's Light and Dark [ThemeData] from the centralised
/// [AppColors] tokens, so screens read colours from the active theme
/// instead of hard-coding hex values. System mode is handled by Flutter
/// itself (MaterialApp.themeMode) - it simply selects between these two
/// ThemeData objects based on the OS brightness, so there is no separate
/// third palette.
///
/// Everything the blood-bank UI pass specified at *theme* level lives
/// here rather than being repeated per widget:
///   * burgundy primary CTA, teal outlined secondary
///   * teal focus rings and teal selected navigation
///   * white cards with a rose-grey border and a 7% neutral shadow
///   * a 44x44 minimum interactive size on every button
///   * no full-width red app bar - the bar sits on the scaffold tone
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  /// The accessibility floor for anything tappable. Material's own
  /// default is 48; this is the explicit contractual minimum from the
  /// usability requirements, applied to button themes below.
  static const Size minTapTarget = Size(44, 44);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(seedColor: c.primary, brightness: brightness).copyWith(
      primary: c.primary,
      onPrimary: Colors.white,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.primary,
      secondary: c.accent,
      onSecondary: Colors.white,
      secondaryContainer: c.accentContainer,
      onSecondaryContainer: c.accent,
      tertiary: c.analytics,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      error: c.critical,
      onError: Colors.white,
      errorContainer: c.criticalContainer,
      onErrorContainer: c.critical,
      outline: c.border,
      outlineVariant: c.border,
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: colorScheme);

    // A very soft neutral shadow (7% opacity) so a white card lifts off
    // the porcelain background without a hard grey edge.
    final cardShadow = Colors.black.withValues(alpha: 0.07);

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      cardColor: c.surface,
      dividerColor: c.border,
      // Teal focus ring, so keyboard focus is visible and is never
      // confused with a critical state.
      focusColor: c.accent.withValues(alpha: 0.12),
      hoverColor: c.accent.withValues(alpha: 0.06),
      splashColor: c.primary.withValues(alpha: 0.10),
      highlightColor: c.primary.withValues(alpha: 0.06),
      textTheme: base.textTheme.apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
      // The bar sits on the same tone as the page - deliberately not a
      // full-width red header.
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: c.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: cardShadow,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
      ),
      // Primary CTA: burgundy fill, white label - checked for contrast
      // against #8F1838.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.disabled,
          disabledForegroundColor: Colors.white,
          minimumSize: minTapTarget,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.disabled,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: minTapTarget,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // Secondary action: outlined teal on a transparent ground, so not
      // every button on the screen is a filled block.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          disabledForegroundColor: c.disabled,
          side: BorderSide(color: c.accent),
          minimumSize: minTapTarget,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent, disabledForegroundColor: c.disabled, minimumSize: minTapTarget),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.textSecondary, disabledForegroundColor: c.disabled, minimumSize: minTapTarget),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accentContainer,
        selectedIconTheme: IconThemeData(color: c.accent),
        unselectedIconTheme: IconThemeData(color: c.textSecondary),
        selectedLabelTextStyle: TextStyle(color: c.accent, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: c.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accentContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? c.accent : c.textSecondary),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
            color: states.contains(WidgetState.selected) ? c.accent : c.textSecondary,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: c.elevatedSurface,
        selectedColor: c.accentContainer,
        side: BorderSide(color: c.border),
        labelStyle: TextStyle(color: c.textPrimary, fontSize: 12),
        secondaryLabelStyle: TextStyle(color: c.accent, fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.elevatedSurface,
        hintStyle: TextStyle(color: c.textSecondary),
        labelStyle: TextStyle(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        // Teal focus border, matching the focus ring elsewhere.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.critical),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: TextStyle(color: c.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: c.textPrimary, fontSize: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light ? c.textPrimary : c.elevatedSurface,
        contentTextStyle: TextStyle(color: brightness == Brightness.light ? Colors.white : c.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.textPrimary, borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.elevatedSurface),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? c.accent : c.textSecondary),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accentContainer : c.elevatedSurface,
        ),
      ),
      extensions: [c],
    );
  }
}
