import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';

/// Shared LifeLink visual primitives.
///
/// These carry no business logic on purpose: a role module passes in what
/// to show, and keeps its own Firestore queries, validation and rules in
/// its own files. That is what lets the Doctor and Donor modules look
/// identical without sharing any behaviour.

/// The semantic role of a status. Every module maps its own domain states
/// onto these, so "available", "verified" and "fulfilled" all render the
/// same green in every module.
enum LLTone {
  /// Brand identity: blood group, donation identity, primary emphasis.
  brand,

  /// Operational, informational, secondary action, selected navigation.
  operational,

  /// Available, eligible, verified, completed.
  success,

  /// Pending attention, low stock, temporarily ineligible.
  warning,

  /// Emergencies and destructive actions only.
  critical,

  /// Analytics and non-urgent supporting detail.
  analytics,

  /// Neutral / not recorded / disabled.
  neutral;

  /// (foreground, container) for this tone in the active theme.
  (Color, Color) resolve(BuildContext context) {
    final c = context.colors;
    return switch (this) {
      LLTone.brand => (c.primary, c.primaryContainer),
      LLTone.operational => (c.accent, c.accentContainer),
      LLTone.success => (c.success, c.successContainer),
      LLTone.warning => (c.warning, c.warningContainer),
      LLTone.critical => (c.critical, c.criticalContainer),
      LLTone.analytics => (c.analytics, c.elevatedSurface),
      LLTone.neutral => (c.textSecondary, c.elevatedSurface),
    };
  }
}

/// The standard LifeLink card: white surface, rose-grey border, soft
/// shadow, 16dp radius. A card that needs to signal a critical state
/// takes [tone] - which tints the border only, never floods the card,
/// so a screen full of urgent items stays readable.
class LLCard extends StatelessWidget {
  const LLCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LLSpacing.lg),
    this.tone,
    this.emphasised = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When set together with [emphasised], tints the card's border.
  final LLTone? tone;
  final bool emphasised;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = emphasised && tone != null ? tone!.resolve(context).$1.withValues(alpha: 0.55) : colors.border;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(LLRadius.card),
        border: Border.all(color: borderColor),
        boxShadow: LLElevation.card(Theme.of(context).brightness),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LLRadius.card),
      child: card,
    );
  }
}

/// A status badge: tinted container, saturated icon and label.
///
/// Status is always carried by **icon + text + colour** together. Nothing
/// in LifeLink communicates state through colour alone, so the badges
/// stay readable for colour-blind users and in greyscale print-outs.
class LLStatusBadge extends StatelessWidget {
  const LLStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    this.dense = false,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final LLTone tone;
  final bool dense;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone.resolve(context);

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? LLSpacing.sm : 9,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LLRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 11 : LLIconSize.badge, color: fg),
          const SizedBox(width: LLSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 10 : 10.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );

    return tooltip == null ? badge : Tooltip(message: tooltip!, child: badge);
  }
}

/// A selectable filter chip, 44dp minimum height.
///
/// Selection is shown with a check icon as well as the accent colour.
class LLFilterChip extends StatelessWidget {
  const LLFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LLRadius.chip),
        child: Container(
          constraints: BoxConstraints(minHeight: LLA11y.minTapTarget.height),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: LLSpacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.accentContainer : colors.surface,
            borderRadius: BorderRadius.circular(LLRadius.chip),
            border: Border.all(color: selected ? colors.accent : colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: LLIconSize.inline, color: colors.accent),
                const SizedBox(width: LLSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.accent : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shared search field: teal focus ring, explicit clear action.
class LLSearchField extends StatelessWidget {
  const LLSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.helperText,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
        // Listening to the controller means the clear button appears on
        // the first keystroke without a setState that would rebuild the
        // whole list underneath.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                    onChanged?.call('');
                  },
                ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: LLSpacing.md),
      ),
    );
  }
}

/// A section heading with an icon and optional supporting line, used to
/// break a long dashboard into labelled areas in both modules.
class LLSectionHeader extends StatelessWidget {
  const LLSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: LLIconSize.sectionHeader, color: colors.primary),
        const SizedBox(width: LLSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: LLSpacing.xxs),
                  child: Text(
                    subtitle!,
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.3),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A labelled key/value row, used in profile and detail screens.
class LLInfoRow extends StatelessWidget {
  const LLInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: colors.textSecondary),
          const SizedBox(width: LLSpacing.md),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
