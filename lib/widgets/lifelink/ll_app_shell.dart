import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import '../offline_banner.dart';
import 'll_brand.dart';
import 'll_nav.dart';

/// The shared LifeLink application shell.
///
/// Every role module renders inside this, so the app bar height, the
/// logo treatment, the navigation style, the selected-state colours, the
/// offline banner and the responsive breakpoint are identical across
/// Doctor, Donor, and later Recipient and Coordinator - while each role
/// keeps its own destinations and its own screens.
///
/// Responsive behaviour, defined once:
///  * below [LLBreakpoints.wide]: bottom navigation bar
///  * at or above it: navigation rail on the left
///
/// Destinations are hosted in an [IndexedStack], so switching tabs keeps
/// each screen's scroll position and open Firestore subscriptions rather
/// than rebuilding them.
class LLAppShell extends StatefulWidget {
  const LLAppShell({
    super.key,
    required this.nav,
    this.initialIndex = 0,
    this.banner,
  });

  final LLRoleNav nav;
  final int initialIndex;

  /// Optional role-specific banner shown under the offline banner and
  /// above the content - for example the Doctor module's critical-request
  /// alert. Donor roles can leave this null.
  final Widget? banner;

  @override
  State<LLAppShell> createState() => _LLAppShellState();
}

class _LLAppShellState extends State<LLAppShell> {
  late int _index = widget.initialIndex.clamp(0, widget.nav.destinations.length - 1);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final destinations = widget.nav.destinations;
    final isWide = LLBreakpoints.isWide(context);

    final content = Column(
      children: [
        // Real connectivity state, shared by every role: "you are
        // offline" changes what every action on the screen means.
        const OfflineBanner(),
        if (widget.banner != null) widget.banner!,
        Expanded(
          child: IndexedStack(
            index: _index,
            children: [
              for (final destination in destinations) destination.builder(context),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: LLAppBar(
        roleLabel: widget.nav.roleLabel,
        title: destinations.isEmpty ? widget.nav.roleLabel : destinations[_index].label,
        actions: widget.nav.actions,
      ),
      body: isWide && widget.nav.hasNavigation
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, thickness: 1, color: colors.border),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: !isWide && widget.nav.hasNavigation
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                    tooltip: d.tooltip ?? d.label,
                  ),
              ],
            )
          : null,
    );
  }
}

/// The shared LifeLink app bar.
///
/// Carries the brand mark, the role label, the current destination name
/// and the role's actions. The title is single-line with an ellipsis and
/// non-primary actions collapse below [LLBreakpoints.compactActions] -
/// both learned from a real overflow bug on a narrow phone, where an
/// unconstrained title wrapped to one character per line.
class LLAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LLAppBar({
    super.key,
    required this.roleLabel,
    required this.title,
    this.actions = const [],
  });

  final String roleLabel;
  final String title;
  final List<LLAppBarAction> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = LLBreakpoints.isCompact(context);

    final primary = actions.where((a) => a.isPrimary || !compact).toList();
    final overflow = compact ? actions.where((a) => !a.isPrimary).toList() : const <LLAppBarAction>[];

    return AppBar(
      titleSpacing: LLSpacing.md,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LLBrandMark(),
          const SizedBox(width: LLSpacing.sm),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                Text(
                  roleLabel,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        for (final action in primary)
          IconButton(
            tooltip: action.tooltip,
            icon: Icon(action.icon),
            onPressed: action.onPressed,
          ),
        if (overflow.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (i) => overflow[i].onPressed(),
            itemBuilder: (context) => [
              for (var i = 0; i < overflow.length; i++)
                PopupMenuItem(
                  value: i,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(overflow[i].icon),
                    title: Text(overflow[i].tooltip),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
