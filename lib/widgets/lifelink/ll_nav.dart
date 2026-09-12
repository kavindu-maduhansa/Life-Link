import 'package:flutter/material.dart';

/// One destination in a role's navigation.
///
/// A role module declares its own list of these. The shell renders them,
/// but never decides what they are - so the Donor module keeps Donor
/// destinations, the Doctor module keeps Doctor destinations, and the
/// Recipient and Coordinator members declare theirs without touching any
/// shared code.
@immutable
class LLNavDestination {
  const LLNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
    this.tooltip,
  });

  /// Shown under the icon in the bottom bar and beside it in the rail.
  /// Keep it to one word where possible so it does not wrap on a phone.
  final String label;

  final IconData icon;

  /// The filled variant, shown when this destination is selected.
  /// Selection is therefore carried by icon *and* colour, never colour
  /// alone.
  final IconData selectedIcon;

  /// Builds the destination's content. Kept alive by the shell's
  /// IndexedStack, so scroll position survives tab switches.
  final WidgetBuilder builder;

  final String? tooltip;
}

/// An action in the shared app bar.
///
/// Actions marked [isPrimary] stay visible at every width; the rest
/// collapse into an overflow menu on a narrow phone so the title keeps
/// its space.
@immutable
class LLAppBarAction {
  const LLAppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// True for actions needed mid-emergency (search, alerts, sign out).
  final bool isPrimary;
}

/// The complete navigation description for one role module.
///
/// See `docs/LIFELINK_DESIGN_SYSTEM.md` for a worked example of adding a
/// new role.
@immutable
class LLRoleNav {
  const LLRoleNav({
    required this.roleLabel,
    required this.destinations,
    this.actions = const [],
  });

  /// Shown next to the LifeLink mark in the app bar, e.g. "Donor" or
  /// "Blood Bank". This is how a user knows which role they are in while
  /// every other visual detail stays identical between modules.
  final String roleLabel;

  final List<LLNavDestination> destinations;
  final List<LLAppBarAction> actions;

  bool get hasNavigation => destinations.length > 1;
}
