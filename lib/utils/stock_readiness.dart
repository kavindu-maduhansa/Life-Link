import '../models/blood_inventory.dart';

/// Turns a raw [BloodInventoryItem] into the readiness judgement the
/// dashboard renders.
///
/// Every rule here is an explicit, stated policy applied to numbers the
/// blood bank recorded itself. Nothing is estimated: a line with no
/// recorded minimum threshold reports [StockLevel.noThreshold] rather
/// than being scored against an invented one, and a line that has never
/// been updated says so instead of looking current.

/// How healthy one stock line is.
enum StockLevel {
  /// No units free to allocate.
  outOfStock,

  /// Free units are less than half the recorded minimum.
  criticalShortage,

  /// Free units are below the recorded minimum.
  lowStock,

  /// Free units meet or exceed the recorded minimum.
  adequate,

  /// The line records no minimum threshold, so it cannot be scored.
  noThreshold;

  String get label => switch (this) {
    StockLevel.outOfStock => 'Out of stock',
    StockLevel.criticalShortage => 'Critical shortage',
    StockLevel.lowStock => 'Low stock',
    StockLevel.adequate => 'Adequate',
    StockLevel.noThreshold => 'No minimum set',
  };

  /// Whether this level belongs in the dashboard's attention area.
  bool get needsAttention => this == StockLevel.outOfStock || this == StockLevel.criticalShortage || this == StockLevel.lowStock;

  /// Only these two are emergencies worth the critical treatment.
  bool get isCritical => this == StockLevel.outOfStock || this == StockLevel.criticalShortage;

  /// Lower sorts first, so the worst lines lead the list. A line that
  /// cannot be scored sorts after the healthy ones - it is a data gap,
  /// not a shortage.
  int get sortWeight => switch (this) {
    StockLevel.outOfStock => 0,
    StockLevel.criticalShortage => 1,
    StockLevel.lowStock => 2,
    StockLevel.adequate => 3,
    StockLevel.noThreshold => 4,
  };
}

/// How trustworthy the line's numbers are, based only on `updatedAt`.
enum StockFreshness {
  /// Updated within [StockReadiness.staleAfter].
  current,

  /// Older than [StockReadiness.staleAfter] - shown with a warning so
  /// staff verify against the physical shelf before relying on it.
  stale,

  /// The document has no `updatedAt` at all.
  neverRecorded;

  String get label => switch (this) {
    StockFreshness.current => 'Up to date',
    StockFreshness.stale => 'Possibly out of date',
    StockFreshness.neverRecorded => 'Never recorded',
  };

  bool get isTrustworthy => this == StockFreshness.current;
}

/// The full readiness verdict for one stock line.
class StockVerdict {
  const StockVerdict({
    required this.level,
    required this.freshness,
    required this.usableUnits,
    required this.expiryRiskUnits,
    required this.hasOverReservation,
    required this.reasons,
  });

  final StockLevel level;
  final StockFreshness freshness;
  final int usableUnits;
  final int expiryRiskUnits;

  /// True when the document claims more reserved than available units.
  final bool hasOverReservation;

  /// Plain-language sentences explaining the verdict, each derived from
  /// a real recorded number - the same "why" treatment `RequestHealth`
  /// gives its SLA badge.
  final List<String> reasons;

  bool get hasExpiryRisk => expiryRiskUnits > 0;

  /// True when anything on this line should draw the eye.
  bool get needsAttention => level.needsAttention || hasExpiryRisk || !freshness.isTrustworthy || hasOverReservation;
}

/// Stock readiness policy. Pure functions only - no Firestore, no
/// widgets - so every threshold boundary is unit-testable.
class StockReadiness {
  const StockReadiness._();

  /// A stock line not touched for longer than this is flagged as
  /// possibly out of date. One working day is the stated policy.
  static const Duration staleAfter = Duration(hours: 24);

  /// Free units below this fraction of the recorded minimum count as a
  /// critical shortage rather than merely low.
  static const double criticalFraction = 0.5;

  static StockLevel levelFor(BloodInventoryItem item) {
    if (item.usableUnits <= 0) return StockLevel.outOfStock;
    if (!item.hasThreshold) return StockLevel.noThreshold;
    if (item.usableUnits < item.minimumThreshold * criticalFraction) return StockLevel.criticalShortage;
    if (item.usableUnits < item.minimumThreshold) return StockLevel.lowStock;
    return StockLevel.adequate;
  }

  static StockFreshness freshnessFor(BloodInventoryItem item, {DateTime? now}) {
    final updatedAt = item.updatedAt;
    if (updatedAt == null) return StockFreshness.neverRecorded;
    final reference = now ?? DateTime.now();
    return reference.difference(updatedAt) > staleAfter ? StockFreshness.stale : StockFreshness.current;
  }

  static StockVerdict verdictFor(BloodInventoryItem item, {DateTime? now}) {
    final level = levelFor(item);
    final freshness = freshnessFor(item, now: now);
    final reasons = <String>[];

    if (item.hasOverReservation) {
      reasons.add(
        'Data problem: ${item.reservedUnits} unit(s) reserved against ${item.availableUnits} available. Treated as 0 usable until corrected.',
      );
    }

    reasons.add(
      '${item.usableUnits} unit(s) free to allocate '
      '(${item.availableUnits} on shelf − ${item.reservedUnits} reserved).',
    );

    if (item.hasThreshold) {
      reasons.add('Recorded minimum for this line is ${item.minimumThreshold} unit(s).');
    } else {
      reasons.add('No minimum threshold is recorded, so low-stock warnings are not applied to this line.');
    }

    if (item.expiryRiskUnits > 0) {
      reasons.add('${item.expiryRiskUnits} unit(s) flagged as close to expiry — allocate these first.');
    }

    reasons.add(switch (freshness) {
      StockFreshness.current => 'Stock was last updated within the last 24 hours.',
      StockFreshness.stale => 'Stock has not been updated in over 24 hours — verify against the shelf.',
      StockFreshness.neverRecorded => 'This line has no update timestamp, so its age is unknown.',
    });

    return StockVerdict(
      level: level,
      freshness: freshness,
      usableUnits: item.usableUnits,
      expiryRiskUnits: item.expiryRiskUnits,
      hasOverReservation: item.hasOverReservation,
      reasons: reasons,
    );
  }

  /// Orders stock lines worst-first, then by blood group in the standard
  /// [kBloodGroups] order so the grid is stable between rebuilds.
  static int compare(BloodInventoryItem a, BloodInventoryItem b, {DateTime? now}) {
    final byLevel = levelFor(a).sortWeight.compareTo(levelFor(b).sortWeight);
    if (byLevel != 0) return byLevel;
    final ai = kBloodGroups.indexOf(a.bloodGroup);
    final bi = kBloodGroups.indexOf(b.bloodGroup);
    final byGroup = (ai < 0 ? kBloodGroups.length : ai).compareTo(bi < 0 ? kBloodGroups.length : bi);
    if (byGroup != 0) return byGroup;
    return a.component.compareTo(b.component);
  }

  /// A one-line roll-up for the dashboard header, e.g.
  /// "2 critical · 3 low · 1 expiring soon". Returns null when every
  /// line is healthy, so the header stays quiet when nothing is wrong.
  static String? summaryLine(List<BloodInventoryItem> items, {DateTime? now}) {
    if (items.isEmpty) return null;
    var critical = 0;
    var low = 0;
    var expiring = 0;
    var stale = 0;
    for (final item in items) {
      final verdict = verdictFor(item, now: now);
      if (verdict.level.isCritical) critical++;
      if (verdict.level == StockLevel.lowStock) low++;
      if (verdict.hasExpiryRisk) expiring++;
      if (!verdict.freshness.isTrustworthy) stale++;
    }
    final parts = <String>[
      if (critical > 0) '$critical critical',
      if (low > 0) '$low low',
      if (expiring > 0) '$expiring expiring soon',
      if (stale > 0) '$stale needs a stock check',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
