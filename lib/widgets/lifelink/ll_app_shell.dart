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
  late int _index = widget.initialIndex.clamp(
    0,
    widget.nav.destinations.length - 1,
  );

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
              for (final destination in destinations)
                destination.builder(context),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: LLAppBar(
        roleLabel: widget.nav.roleLabel,
        title: destinations.isEmpty
            ? widget.nav.roleLabel
            : destinations[_index].label,
        actions: widget.nav.actions,
      ),
      body: isWide && widget.nav.hasNavigation
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  backgroundColor: colors.surface,
                  indicatorColor: colors.primary.withValues(alpha: 0.15),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(color: colors.primary),
                  unselectedIconTheme: IconThemeData(
                    color: colors.textSecondary,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: colors.textSecondary,
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(
                          d.selectedIcon,
                          color: colors.primary,
                        ),
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
          ? Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.5)
                        : colors.darkShadow.withValues(alpha: 0.08),
                    offset: const Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: colors.surface,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: colors.primaryContainer,
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 12,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: states.contains(WidgetState.selected)
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  backgroundColor: colors.surface,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: colors.primaryContainer,
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(
                          d.selectedIcon,
                          color: colors.primary,
                        ),
                        label: d.label,
                        tooltip: d.tooltip ?? d.label,
                      ),
                  ],
                ),
              ),
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
    final overflow = compact
        ? actions.where((a) => !a.isPrimary).toList()
        : const <LLAppBarAction>[];

    return AppBar(
      titleSpacing: LLSpacing.md,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: colors.border, height: 1.0),
      ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  roleLabel,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
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
            color: colors.textSecondary,
            onPressed: action.onPressed,
          ),
        if (overflow.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: 'More actions',
            icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary),
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LLRadius.control),
            ),
            onSelected: (i) => overflow[i].onPressed(),
            itemBuilder: (context) => [
              for (var i = 0; i < overflow.length; i++)
                PopupMenuItem(
                  value: i,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      overflow[i].icon,
                      color: colors.textSecondary,
                    ),
                    title: Text(
                      overflow[i].tooltip,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
