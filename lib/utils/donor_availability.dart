/// Doctor-module compatibility adapter for a donor's "can they donate
/// right now" flag.
///
/// WHY THIS EXISTS
/// ---------------
/// LifeLink currently has two different spellings of the same idea:
///
///   * `isAvailable`  - the canonical field this project standardises on.
///   * `availableNow` - the legacy field the Doctor module's walk-in
///     donor registration writes, and the one the donor search used to
///     read directly.
///
/// On top of that, a donor who signs up through the app
/// (`register_screen.dart`) gets **neither** field, because registration
/// does not collect availability at all.
///
/// The previous Doctor-side check was `data['availableNow'] != false`,
/// which silently resolved a *missing* field to "available". That meant
/// every app-registered donor was presented to blood-bank staff as
/// available to donate right now, on no evidence at all. In a blood-bank
/// workflow that is the wrong direction to fail in, so this adapter
/// never infers availability from absence - it reports [unknown] and
/// lets the UI say so.
///
/// This is a READ-ONLY adapter. It does not write, dual-write, or
/// migrate donor documents, and it does not touch the Donor module.
library;

/// A donor's availability as the Doctor module is able to determine it.
enum DonorAvailability {
  /// A recognised availability field is present and says yes.
  available,

  /// A recognised availability field is present and says no.
  unavailable,

  /// No recognised availability field is present, or its value is not a
  /// boolean. Never treated as [available].
  unknown;

  /// True only when availability was positively confirmed.
  bool get isConfirmedAvailable => this == DonorAvailability.available;

  /// True only when availability was positively denied.
  bool get isConfirmedUnavailable => this == DonorAvailability.unavailable;

  /// Short label for a chip/tag. Always paired with an icon and colour
  /// in the UI so status is never communicated by colour alone.
  String get label => switch (this) {
    DonorAvailability.available => 'Available',
    DonorAvailability.unavailable => 'Unavailable',
    DonorAvailability.unknown => 'Availability unknown',
  };

  /// A one-line explanation a doctor can act on.
  String get explanation => switch (this) {
    DonorAvailability.available => 'Donor has marked themselves available to donate.',
    DonorAvailability.unavailable => 'Donor has marked themselves unavailable.',
    DonorAvailability.unknown => 'This donor record has no availability field. Confirm by phone before relying on it.',
  };

  /// Sort weight, lower sorts first: confirmed available, then unknown,
  /// then confirmed unavailable. Unknown deliberately sorts above
  /// unavailable (it is worth a phone call) but below confirmed.
  int get sortWeight => switch (this) {
    DonorAvailability.available => 0,
    DonorAvailability.unknown => 1,
    DonorAvailability.unavailable => 2,
  };
}

/// Reads a donor's availability out of a raw Firestore document map.
///
/// Resolution order, as documented in `docs/LIFELINK_DATA_CONTRACT.md`:
///   1. canonical [canonicalField] (`isAvailable`) when it holds a bool
///   2. legacy [legacyField] (`availableNow`) when it holds a bool
///   3. otherwise [DonorAvailability.unknown]
///
/// A present-but-non-boolean value (for example the string `"true"`,
/// written by hand in the Firebase console) is treated as unknown
/// rather than guessed at, and does not stop the fallback from being
/// consulted.
class DonorAvailabilityReader {
  const DonorAvailabilityReader._();

  /// The field name LifeLink standardises on.
  static const canonicalField = 'isAvailable';

  /// The older field name still present on walk-in donor records.
  static const legacyField = 'availableNow';

  static DonorAvailability read(Map<String, dynamic>? data) {
    if (data == null) return DonorAvailability.unknown;

    final canonical = data[canonicalField];
    if (canonical is bool) {
      return canonical ? DonorAvailability.available : DonorAvailability.unavailable;
    }

    final legacy = data[legacyField];
    if (legacy is bool) {
      return legacy ? DonorAvailability.available : DonorAvailability.unavailable;
    }

    return DonorAvailability.unknown;
  }

  /// Which field the value was actually read from, for the data-contract
  /// hint shown on the donor detail sheet. Null when neither field
  /// supplied a usable boolean.
  static String? sourceField(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data[canonicalField] is bool) return canonicalField;
    if (data[legacyField] is bool) return legacyField;
    return null;
  }

  /// True when the donor should pass an "Available only" filter.
  ///
  /// Only a positively confirmed donor passes - an unknown donor is
  /// excluded, because the filter's promise to staff is "these people
  /// said yes", not "these people did not say no".
  static bool passesAvailableOnlyFilter(Map<String, dynamic>? data) {
    return read(data).isConfirmedAvailable;
  }
}
