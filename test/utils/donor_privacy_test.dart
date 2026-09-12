import 'package:flutter_test/flutter_test.dart';

import 'package:hci/utils/donor_privacy.dart';

/// Tests for donor contact masking.
///
/// This is presentation-layer minimisation, not a security control - the
/// tests assert that the masked form never leaks the middle digits and
/// that a number too short to partially hide is hidden completely.
void main() {
  group('DonorPrivacy.mask', () {
    test('keeps two leading and three trailing digits', () {
      expect(DonorPrivacy.mask('0771234567'), '07•••••567');
    });

    test('preserves separators so the shape stays recognisable', () {
      final masked = DonorPrivacy.mask('+94 77 123 4567');
      expect(masked.startsWith('+94'), isTrue);
      expect(masked.endsWith('567'), isTrue);
      expect(masked, contains(' '));
    });

    test('hides every middle digit', () {
      final masked = DonorPrivacy.mask('0771234567');
      // '1234' are middle digits and must not survive.
      expect(masked, isNot(contains('1')));
      expect(masked, isNot(contains('2')));
      expect(masked, isNot(contains('3')));
      expect(masked, isNot(contains('4')));
    });

    test('masks a short number completely rather than partially exposing it', () {
      expect(DonorPrivacy.mask('123'), '•••');
      expect(DonorPrivacy.mask('12345'), '•••••');
    });

    test('a six-digit number is the first length that shows any digits', () {
      expect(DonorPrivacy.mask('123456'), '12•456');
    });

    test('an empty or whitespace-only number reads as Not recorded', () {
      expect(DonorPrivacy.mask(''), DonorPrivacy.notRecorded);
      expect(DonorPrivacy.mask('   '), DonorPrivacy.notRecorded);
      expect(DonorPrivacy.mask(null), DonorPrivacy.notRecorded);
    });

    test('a masked number never equals the original', () {
      const original = '0771234567';
      expect(DonorPrivacy.mask(original), isNot(original));
    });
  });

  group('DonorPrivacy.hasNumber', () {
    test('distinguishes a recorded number from a blank one', () {
      expect(DonorPrivacy.hasNumber('0771234567'), isTrue);
      expect(DonorPrivacy.hasNumber(''), isFalse);
      expect(DonorPrivacy.hasNumber('   '), isFalse);
      expect(DonorPrivacy.hasNumber(null), isFalse);
    });
  });

  group('DonorPrivacy.display', () {
    test('masks by default', () {
      expect(DonorPrivacy.display('0771234567', revealed: false), DonorPrivacy.mask('0771234567'));
    });

    test('shows the real number only once revealed', () {
      expect(DonorPrivacy.display('0771234567', revealed: true), '0771234567');
    });

    test('trims the revealed number', () {
      expect(DonorPrivacy.display('  0771234567  ', revealed: true), '0771234567');
    });

    test('a missing number reads as Not recorded whether revealed or not', () {
      expect(DonorPrivacy.display(null, revealed: true), DonorPrivacy.notRecorded);
      expect(DonorPrivacy.display('', revealed: true), DonorPrivacy.notRecorded);
    });
  });

  group('reveal confirmation', () {
    test('names the donor and states that the reveal is audited', () {
      final text = DonorPrivacy.revealConfirmation('A. Perera');
      expect(text, contains('A. Perera'));
      expect(text.toLowerCase(), contains('audit'));
    });
  });

  group('stated limitations', () {
    test('the permission-denied message points at a role, not a bug', () {
      final text = DonorPrivacy.permissionDeniedMessage.toLowerCase();
      expect(text, contains('permission'));
      expect(text, contains('role'));
    });

    test('the withheld-field list is documented and non-empty', () {
      expect(DonorPrivacy.fieldsWithheldFromListCards, contains('phoneNumber'));
      expect(DonorPrivacy.fieldsWithheldFromListCards, isNotEmpty);
    });
  });
}
