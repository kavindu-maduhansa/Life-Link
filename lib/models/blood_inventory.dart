import 'package:cloud_firestore/cloud_firestore.dart';

/// One stock line in the blood bank: a single blood group + component
/// combination at one facility.
///
/// NEW COLLECTION: `bloodInventory`. Nothing else in LifeLink reads or
/// writes it, so adding it cannot affect the Donor, Recipient or
/// Coordinator modules. Every field is optional with a safe default, so
/// a partially-filled document still renders instead of crashing.
///
/// This model is deliberately parsed from a plain `Map` by [fromMap] -
/// [fromDoc] is only a thin wrapper - so the parsing rules can be unit
/// tested without initialising Firebase.
class BloodInventoryItem {
  const BloodInventoryItem({
    required this.id,
    required this.facilityId,
    required this.bloodGroup,
    required this.component,
    required this.availableUnits,
    required this.reservedUnits,
    required this.minimumThreshold,
    required this.expiryRiskUnits,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;

  /// Which hospital/blood bank this line belongs to. Empty when the
  /// document does not record one.
  final String facilityId;

  /// 'O+', 'A-', … Rendered as a compact badge.
  final String bloodGroup;

  /// See [BloodComponent] for the vocabulary this project uses.
  final String component;

  /// Units physically on the shelf.
  final int availableUnits;

  /// Units already promised to a request and therefore not free to
  /// allocate again.
  final int reservedUnits;

  /// The level below which this line is considered low stock. Zero means
  /// "no threshold recorded" and suppresses the low-stock judgement
  /// rather than inventing one.
  final int minimumThreshold;

  /// Units close enough to their expiry date to be worth using first.
  /// Recorded by staff; LifeLink does not compute expiry itself.
  final int expiryRiskUnits;

  final DateTime? updatedAt;
  final String? updatedBy;

  /// Units actually free to allocate. Never negative: a document with
  /// more reserved than available is a data problem, not a negative
  /// shelf count, and is surfaced as zero usable units.
  int get usableUnits {
    final free = availableUnits - reservedUnits;
    return free < 0 ? 0 : free;
  }

  /// True when the document records more reserved units than it has
  /// available - shown as an explicit data warning rather than hidden.
  bool get hasOverReservation => reservedUnits > availableUnits;

  /// True when this line records a minimum threshold at all.
  bool get hasThreshold => minimumThreshold > 0;

  factory BloodInventoryItem.fromMap(String id, Map<String, dynamic>? raw) {
    final data = raw ?? const <String, dynamic>{};
    return BloodInventoryItem(
      id: id,
      facilityId: (data['facilityId'] as String?)?.trim() ?? '',
      bloodGroup: (data['bloodGroup'] as String?)?.trim().toUpperCase() ?? '-',
      component: (data['component'] as String?)?.trim() ?? BloodComponent.wholeBlood,
      availableUnits: _nonNegativeInt(data['availableUnits']),
      reservedUnits: _nonNegativeInt(data['reservedUnits']),
      minimumThreshold: _nonNegativeInt(data['minimumThreshold']),
      expiryRiskUnits: _nonNegativeInt(data['expiryRiskUnits']),
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: (data['updatedBy'] as String?)?.trim().isEmpty == true ? null : data['updatedBy'] as String?,
    );
  }

  factory BloodInventoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BloodInventoryItem.fromMap(doc.id, doc.data());
  }

  /// Counts stored as a negative number, a string, or null all resolve
  /// to 0 rather than throwing or being rendered as nonsense.
  static int _nonNegativeInt(Object? value) {
    final n = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    return n < 0 ? 0 : n;
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// The blood component vocabulary used by the Doctor module.
///
/// These are display/storage strings, not a clinical authority - the
/// hospital's own protocol decides what is actually transfused.
class BloodComponent {
  const BloodComponent._();

  static const wholeBlood = 'Whole Blood';
  static const packedRedCells = 'Packed Red Cells';
  static const platelets = 'Platelets';
  static const plasma = 'Fresh Frozen Plasma';
  static const cryoprecipitate = 'Cryoprecipitate';

  static const List<String> all = [wholeBlood, packedRedCells, platelets, plasma, cryoprecipitate];

  /// A short form for tight badges ('PRC', 'FFP', …).
  static String shortLabel(String component) => switch (component) {
    wholeBlood => 'WB',
    packedRedCells => 'PRC',
    platelets => 'PLT',
    plasma => 'FFP',
    cryoprecipitate => 'CRYO',
    _ => component.isEmpty ? '—' : component,
  };

  /// True for a value this project recognises. An unrecognised component
  /// is still displayed as-is, never dropped.
  static bool isKnown(String component) => all.contains(component);
}

/// The eight blood groups, in the order the readiness grid shows them.
const List<String> kBloodGroups = ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
