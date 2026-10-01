// FirebaseException (used to tell a permission-denied read apart from a
// connection failure) is re-exported by firebase_auth, so cloud_firestore
// does not need importing here.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/blood_inventory.dart';
import '../../services/request_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/stock_readiness.dart';
import '../../widgets/entrance_fade_slide.dart';

/// Blood Stock Readiness - what is actually on the shelf, per blood
/// group and component, so staff can see whether the units are already
/// there before they start phoning donors.
///
/// HONESTY RULES BAKED IN
/// ----------------------
///  * No seeded or demo stock. An empty `bloodInventory` collection
///    renders an empty state explaining how to add a line - it never
///    invents plausible-looking unit counts.
///  * A line with no recorded minimum threshold is not scored against
///    an imagined one; it says "No minimum set".
///  * A line not updated for over 24 hours is labelled as possibly out
///    of date, because a stock figure nobody has touched in days is not
///    evidence of what is on the shelf right now.
class BloodStockScreen extends StatefulWidget {
  const BloodStockScreen({super.key});

  @override
  State<BloodStockScreen> createState() => _BloodStockScreenState();
}

class _BloodStockScreenState extends State<BloodStockScreen> {
  String? _groupFilter;
  String? _componentFilter;

  // Created once, not in build, so filtering does not re-subscribe to
  // Firestore on every keystroke.
  late final Stream<List<BloodInventoryItem>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = RequestService.instance.inventoryStream();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Blood Stock Readiness', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          _StockFilters(
            groupFilter: _groupFilter,
            componentFilter: _componentFilter,
            onGroupChanged: (value) => setState(() => _groupFilter = value),
            onComponentChanged: (value) => setState(() => _componentFilter = value),
          ),
          Expanded(
            child: StreamBuilder<List<BloodInventoryItem>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _StockErrorState(error: snapshot.error!);
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final all = snapshot.data!;
                if (all.isEmpty) return const _StockEmptyState();

                final filtered = all.where((item) {
                  if (_groupFilter != null && item.bloodGroup != _groupFilter) return false;
                  if (_componentFilter != null && item.component != _componentFilter) return false;
                  return true;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    _StockSummaryHeader(items: all),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const _StockFilteredEmptyState()
                    else
                      for (var i = 0; i < filtered.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: EntranceFadeSlide(
                            delay: Duration(milliseconds: 30 * i.clamp(0, 8)),
                            child: StockLineCard(item: filtered[i]),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Update stock'),
        onPressed: () => showStockUpdateSheet(context),
      ),
    );
  }
}

/// A single stock line: group + component badge, the counts, the
/// readiness verdict, and an expandable "why" list.
class StockLineCard extends StatefulWidget {
  const StockLineCard({super.key, required this.item, this.compact = false});

  final BloodInventoryItem item;

  /// Compact form is used inside the dashboard card, where the reasons
  /// list would be too much detail.
  final bool compact;

  @override
  State<StockLineCard> createState() => _StockLineCardState();
}

class _StockLineCardState extends State<StockLineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final verdict = StockReadiness.verdictFor(widget.item);
    final (Color tone, Color container, IconData icon) = _toneFor(verdict.level, colors);

    return Container(
      padding: EdgeInsets.all(widget.compact ? 11 : 14),
      decoration: BoxDecoration(
        // Stock cards stay on the white surface; only the status badge
        // carries the tint, so a shelf full of warnings never becomes a
        // wall of solid red.
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: verdict.level.isCritical ? tone.withValues(alpha: 0.55) : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BloodGroupBadge(group: widget.item.bloodGroup),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.component,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${verdict.usableUnits} free / ${widget.item.availableUnits} on shelf / ${widget.item.reservedUnits} reserved',
                      maxLines: 2,
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(label: verdict.level.label, icon: icon, tone: tone, container: container),
            ],
          ),
          if (verdict.hasExpiryRisk || !verdict.freshness.isTrustworthy || verdict.hasOverReservation) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (verdict.hasExpiryRisk)
                  _StatusPill(
                    label: '${verdict.expiryRiskUnits} expiring soon',
                    icon: Icons.timelapse_rounded,
                    tone: colors.warning,
                    container: colors.warningContainer,
                  ),
                if (!verdict.freshness.isTrustworthy)
                  _StatusPill(
                    label: verdict.freshness.label,
                    icon: Icons.update_disabled_rounded,
                    tone: colors.warning,
                    container: colors.warningContainer,
                  ),
                if (verdict.hasOverReservation)
                  _StatusPill(
                    label: 'Reserved exceeds available',
                    icon: Icons.error_outline_rounded,
                    tone: colors.critical,
                    container: colors.criticalContainer,
                  ),
              ],
            ),
          ],
          if (!widget.compact) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
                label: Text(_expanded ? 'Hide detail' : 'Why this status?', style: const TextStyle(fontSize: 12)),
              ),
            ),
            // AnimatedSize follows the platform's own animation settings,
            // so Reduce Motion shortens it rather than this widget
            // re-implementing its own motion policy.
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final reason in verdict.reasons)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5, right: 8),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(color: colors.textSecondary, shape: BoxShape.circle),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(reason, style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.35)),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.item.updatedBy != null)
                            Text(
                              'Last updated by ${widget.item.updatedBy}.',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colors.textSecondary),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  static (Color, Color, IconData) _toneFor(StockLevel level, AppColors colors) {
    return switch (level) {
      StockLevel.outOfStock => (colors.critical, colors.criticalContainer, Icons.block_rounded),
      StockLevel.criticalShortage => (colors.critical, colors.criticalContainer, Icons.priority_high_rounded),
      StockLevel.lowStock => (colors.warning, colors.warningContainer, Icons.trending_down_rounded),
      StockLevel.adequate => (colors.success, colors.successContainer, Icons.check_circle_outline_rounded),
      StockLevel.noThreshold => (colors.textSecondary, colors.elevatedSurface, Icons.help_outline_rounded),
    };
  }
}

/// Compact readiness card for the dashboard: the roll-up plus the two
/// worst lines, linking through to the full panel rather than
/// duplicating it.
class BloodStockReadinessCard extends StatefulWidget {
  const BloodStockReadinessCard({super.key});

  @override
  State<BloodStockReadinessCard> createState() => _BloodStockReadinessCardState();
}

class _BloodStockReadinessCardState extends State<BloodStockReadinessCard> {
  late final Stream<List<BloodInventoryItem>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = RequestService.instance.inventoryStream();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StreamBuilder<List<BloodInventoryItem>>(
      stream: _stream,
      builder: (context, snapshot) {
        final summary = snapshot.hasData ? StockReadiness.summaryLine(snapshot.data!) : null;
        final worst = snapshot.hasData
            ? snapshot.data!.where((i) => StockReadiness.verdictFor(i).needsAttention).take(2).toList()
            : const <BloodInventoryItem>[];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Blood Stock Readiness',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodStockScreen())),
                    child: const Text('Open', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              if (snapshot.hasError)
                Text('Stock could not be loaded right now.', style: TextStyle(fontSize: 12, color: colors.textSecondary))
              else if (!snapshot.hasData)
                Text('Loading stock...', style: TextStyle(fontSize: 12, color: colors.textSecondary))
              else if (snapshot.data!.isEmpty)
                Text(
                  'No stock lines recorded yet. Staff can add them from the stock panel.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35),
                )
              else ...[
                Text(
                  summary ?? 'All recorded stock lines are at or above their minimum.',
                  style: TextStyle(
                    fontSize: 12,
                    color: summary == null ? colors.success : colors.textPrimary,
                    fontWeight: summary == null ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                for (final item in worst)
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: StockLineCard(item: item, compact: true),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// States
// ---------------------------------------------------------------

class _StockEmptyState extends StatelessWidget {
  const _StockEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 44, color: colors.textSecondary),
            const SizedBox(height: 14),
            Text(
              'No stock recorded yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'LifeLink does not estimate or seed stock figures. Once authorised staff record a '
              'line with "Update stock", its readiness appears here and on the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showStockUpdateSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record the first line'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockFilteredEmptyState extends StatelessWidget {
  const _StockFilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_rounded, size: 34, color: colors.textSecondary),
          const SizedBox(height: 10),
          Text('No stock line matches these filters.', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

/// Distinguishes a permission problem from a general failure, because
/// the two need different responses from the person looking at it.
class _StockErrorState extends StatelessWidget {
  const _StockErrorState({required this.error});

  final Object error;

  bool get _isPermissionDenied {
    final e = error;
    return e is FirebaseException && e.code == 'permission-denied';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPermission = _isPermissionDenied;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission ? Icons.lock_outline_rounded : Icons.cloud_off_rounded,
              size: 42,
              color: isPermission ? colors.warning : colors.critical,
            ),
            const SizedBox(height: 14),
            Text(
              isPermission ? 'You do not have access to blood stock' : 'Stock could not be loaded',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isPermission
                  ? 'Firestore rules are refusing this read for your account. Ask an administrator to '
                        'review your role - signing out and back in will not change it.'
                  : 'This is usually a connection problem. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Filters, badges and the update sheet
// ---------------------------------------------------------------

class _StockFilters extends StatelessWidget {
  const _StockFilters({
    required this.groupFilter,
    required this.componentFilter,
    required this.onGroupChanged,
    required this.onComponentChanged,
  });

  final String? groupFilter;
  final String? componentFilter;
  final ValueChanged<String?> onGroupChanged;
  final ValueChanged<String?> onComponentChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StockFilterChip(label: 'All groups', selected: groupFilter == null, onTap: () => onGroupChanged(null)),
                for (final group in kBloodGroups) ...[
                  const SizedBox(width: 6),
                  _StockFilterChip(label: group, selected: groupFilter == group, onTap: () => onGroupChanged(group)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StockFilterChip(label: 'All components', selected: componentFilter == null, onTap: () => onComponentChanged(null)),
                for (final component in BloodComponent.all) ...[
                  const SizedBox(width: 6),
                  _StockFilterChip(
                    label: BloodComponent.shortLabel(component),
                    selected: componentFilter == component,
                    onTap: () => onComponentChanged(component),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockFilterChip extends StatelessWidget {
  const _StockFilterChip({required this.label, required this.selected, required this.onTap});

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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          // 44dp minimum height keeps the chip a comfortable target.
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? colors.accentContainer : colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? colors.accent : colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selection is shown by a check AND the colour, never the
              // colour alone.
              if (selected) ...[Icon(Icons.check_rounded, size: 14, color: colors.accent), const SizedBox(width: 4)],
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

class _BloodGroupBadge extends StatelessWidget {
  const _BloodGroupBadge({required this.group});

  final String group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        group,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.primary),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon, required this.tone, required this.container});

  final String label;
  final IconData icon;
  final Color tone;
  final Color container;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + text + colour together - never colour alone.
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: tone),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockSummaryHeader extends StatelessWidget {
  const _StockSummaryHeader({required this.items});

  final List<BloodInventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summary = StockReadiness.summaryLine(items);
    final healthy = summary == null;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: healthy ? colors.successContainer : colors.warningContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (healthy ? colors.success : colors.warning).withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.check_circle_outline_rounded : Icons.report_problem_outlined,
            size: 19,
            color: healthy ? colors.success : colors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthy ? 'All recorded lines are at or above their minimum' : summary,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary, height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(
                  '${items.length} stock line(s) recorded. Figures are entered by staff, not measured by LifeLink.',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet for recording a stock line. Every number comes from the person
/// filling it in.
Future<void> showStockUpdateSheet(BuildContext context) {
  return showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _StockUpdateSheet());
}

class _StockUpdateSheet extends StatefulWidget {
  const _StockUpdateSheet();

  @override
  State<_StockUpdateSheet> createState() => _StockUpdateSheetState();
}

class _StockUpdateSheetState extends State<_StockUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _facilityController = TextEditingController();
  final _availableController = TextEditingController();
  final _reservedController = TextEditingController(text: '0');
  final _minimumController = TextEditingController();
  final _expiryController = TextEditingController(text: '0');

  String _group = kBloodGroups.first;
  String _component = BloodComponent.packedRedCells;
  bool _saving = false;

  @override
  void dispose() {
    _facilityController.dispose();
    _availableController.dispose();
    _reservedController.dispose();
    _minimumController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await RequestService.instance.upsertInventoryLine(
        facilityId: _facilityController.text.trim(),
        bloodGroup: _group,
        component: _component,
        availableUnits: int.tryParse(_availableController.text.trim()) ?? 0,
        reservedUnits: int.tryParse(_reservedController.text.trim()) ?? 0,
        minimumThreshold: int.tryParse(_minimumController.text.trim()) ?? 0,
        expiryRiskUnits: int.tryParse(_expiryController.text.trim()) ?? 0,
        doctorId: user.uid,
        doctorName: user.displayName ?? user.email ?? 'Staff',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock line saved.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save the stock line: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        // Keeps the sheet above the keyboard on a small phone.
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record blood stock',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'These counts are recorded exactly as entered and shown to every operator. '
                'Enter what is physically on the shelf.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _facilityController,
                decoration: const InputDecoration(labelText: 'Facility / blood bank ID'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Enter the facility this stock belongs to' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _group,
                decoration: const InputDecoration(labelText: 'Blood group'),
                items: [for (final g in kBloodGroups) DropdownMenuItem(value: g, child: Text(g))],
                onChanged: (value) => setState(() => _group = value ?? _group),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _component,
                decoration: const InputDecoration(labelText: 'Component'),
                items: [for (final c in BloodComponent.all) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (value) => setState(() => _component = value ?? _component),
              ),
              const SizedBox(height: 12),
              _NumberField(controller: _availableController, label: 'Units on shelf', isRequired: true),
              const SizedBox(height: 12),
              _NumberField(controller: _reservedController, label: 'Units reserved'),
              const SizedBox(height: 12),
              _NumberField(controller: _minimumController, label: 'Minimum threshold (leave blank if none)'),
              const SizedBox(height: 12),
              _NumberField(controller: _expiryController, label: 'Units close to expiry'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save stock line'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, this.isRequired = false});

  final TextEditingController controller;
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return isRequired ? 'Required' : null;
        final parsed = int.tryParse(text);
        if (parsed == null) return 'Enter a whole number';
        if (parsed < 0) return 'Cannot be negative';
        return null;
      },
    );
  }
}
