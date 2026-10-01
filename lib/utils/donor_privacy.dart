/// UI-level minimisation of donor contact details in the Doctor module.
///
/// WHAT THIS IS
/// ------------
/// Donor phone numbers are masked by default in lists and cards, and
/// revealed only after the operator explicitly asks - which is then
/// recorded in the audit trail. The point is to stop a full contact list
/// being visible on a shared blood-bank screen that anybody walking past
/// can read, and to leave a record of who looked up whose number.
///
/// WHAT THIS IS NOT
/// ----------------
/// This is presentation-layer minimisation only. The Firestore document
/// is still delivered to the client in full, so masking here is NOT a
/// security control and does not replace Firestore security rules or
/// backend authorisation. Recommended rule changes are written up in
/// `docs/LIFELINK_DATA_CONTRACT.md`; this project does not deploy rules.
library;

/// Masks a phone number, keeping only enough to recognise a number you
/// already know.
///
/// Examples:
///   '0771234567'     -> '07•••••567'
///   '+94 77 123 4567'-> '+94 7•••••••567'  (formatting preserved)
///   '123'            -> '•••'              (too short to partially show)
///   ''               -> 'Not recorded'
class DonorPrivacy {
  const DonorPrivacy._();

  static const String notRecorded = 'Not recorded';

  /// How many leading digits stay visible.
  static const int visibleLeadingDigits = 2;

  /// How many trailing digits stay visible.
  static const int visibleTrailingDigits = 3;

  /// The character used for each hidden digit.
  static const String maskChar = '•';

  static bool hasNumber(String? phone) => (phone ?? '').trim().isNotEmpty;

  /// Returns the masked form of [phone].
  ///
  /// Only digits are masked; separators such as '+', spaces and dashes
  /// are preserved so the shape of the number is still recognisable.
  /// A number with too few digits to mask meaningfully is masked in full
  /// rather than partially exposed.
  static String mask(String? phone) {
    final raw = (phone ?? '').trim();
    if (raw.isEmpty) return notRecorded;

    final digitCount = raw.runes.where((r) => _isDigit(r)).length;
    final maskAll = digitCount <= visibleLeadingDigits + visibleTrailingDigits;

    final buffer = StringBuffer();
    var seen = 0;
    for (final rune in raw.runes) {
      final char = String.fromCharCode(rune);
      if (!_isDigit(rune)) {
        buffer.write(char);
        continue;
      }
      seen++;
      final keepLeading = !maskAll && seen <= visibleLeadingDigits;
      final keepTrailing = !maskAll && seen > digitCount - visibleTrailingDigits;
      buffer.write(keepLeading || keepTrailing ? char : maskChar);
    }
    return buffer.toString();
  }

  /// What to render for a contact field, given whether the operator has
  /// revealed it on this screen.
  static String display(String? phone, {required bool revealed}) {
    if (!hasNumber(phone)) return notRecorded;
    return revealed ? phone!.trim() : mask(phone);
  }

  /// The confirmation text shown before a number is revealed. It names
  /// the consequence (an audit entry) rather than just asking twice.
  static String revealConfirmation(String donorName) => 'Reveal $donorName\'s phone number? This is recorded in the audit trail.';

  /// Fields the Doctor module deliberately does not put on a list card,
  /// because coordination does not need them at a glance. Documented
  /// here so the decision is reviewable rather than implicit.
  static const List<String> fieldsWithheldFromListCards = ['phoneNumber', 'email', 'address'];

  /// Shown on a permission-denied state so staff know it is a rules
  /// decision, not a bug or an empty collection.
  static const String permissionDeniedMessage =
      'You do not have permission to read this data. Ask an administrator to review your role, then try again.';

  static bool _isDigit(int rune) => rune >= 0x30 && rune <= 0x39;
}
