import 'package:flutter/material.dart';

/// Non-colour design tokens shared by every LifeLink role module.
///
/// Colour lives in [AppColors] (`theme/app_colors.dart`); everything else
/// that has to match across the Doctor, Donor, Recipient and Coordinator
/// modules lives here, so "the spacing looks different on your screen"
/// stops being a conversation.
///
/// USAGE
/// -----
/// ```dart
/// Container(
///   padding: const EdgeInsets.all(LLSpacing.md),
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(LLRadius.card),
///     border: Border.all(color: context.colors.border),
///   ),
/// )
/// ```

/// The 4dp spacing scale. Every gap in a LifeLink screen should be one of
/// these, so rhythm is consistent between modules.
class LLSpacing {
  const LLSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 30;

  /// Standard page padding on a phone.
  static const double pageH = 16;
}

/// Corner radii. Cards and sheets are deliberately softer than controls.
class LLRadius {
  const LLRadius._();

  static const double chip = 10;
  static const double control = 12;
  static const double card = 16;
  static const double sheet = 20;
  static const double pill = 20;
  static const double avatar = 11;
}

/// Icon sizes, so a badge icon is the same size in every module.
class LLIconSize {
  const LLIconSize._();

  static const double badge = 12;
  static const double inline = 14;
  static const double label = 16;
  static const double action = 18;
  static const double sectionHeader = 19;
  static const double emptyState = 44;
}

/// Layout breakpoints. One definition, so both modules switch from
/// bottom navigation to a navigation rail at exactly the same width.
class LLBreakpoints {
  const LLBreakpoints._();

  /// At or above this width a module shows a navigation rail instead of
  /// a bottom navigation bar.
  static const double wide = 900;

  /// Below this width, secondary app-bar actions collapse into an
  /// overflow menu so the title keeps its space.
  static const double compactActions = 420;

  /// Above this, stat rows lay out as expanded cards rather than a
  /// horizontal scroll strip.
  static const double statRow = 560;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wide;

  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < compactActions;
}

/// Accessibility floors that apply everywhere.
class LLA11y {
  const LLA11y._();

  /// Minimum interactive size. Also set on the button themes in
  /// [AppTheme], but exposed here for hand-built tap targets such as
  /// filter chips.
  static const Size minTapTarget = Size(44, 44);

  /// True when the user has asked the OS to reduce motion.
  ///
  /// Every LifeLink animation must check this. Entrance animations are
  /// skipped outright rather than merely shortened, because a staggered
  /// list entrance is exactly the effect the setting exists to stop.
  static bool reduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}

/// Motion durations. Short by policy: this is an emergency-coordination
/// app, and no animation should stand between staff and an urgent action.
class LLMotion {
  const LLMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 160);
  static const Duration entrance = Duration(milliseconds: 220);

  /// Per-item delay for a staggered list entrance, capped by the caller
  /// so a long list does not animate for seconds.
  static const Duration stagger = Duration(milliseconds: 35);

  /// Returns [duration], or [Duration.zero] when the user has asked for
  /// reduced motion.
  static Duration respect(BuildContext context, Duration duration) =>
      LLA11y.reduceMotion(context) ? Duration.zero : duration;
}

/// The soft neutral card shadow used across modules. Kept at a low alpha
/// so a white card lifts off the porcelain background without a hard
/// grey edge.
class LLElevation {
  const LLElevation._();

  static List<BoxShadow> card(Brightness brightness) {
    if (brightness == Brightness.dark) return const [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
