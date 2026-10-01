import 'package:flutter_test/flutter_test.dart';

import 'package:hci/utils/donor_availability.dart';

/// Tests for the Doctor-side donor availability compatibility adapter.
///
/// The behaviour that matters most here is the *absence* case: before
/// this adapter, the donor search used `data['availableNow'] != false`,
/// which reported a donor with no availability field at all as available
/// to donate. Every app-registered donor is in exactly that state,
/// because `register_screen.dart` does not collect availability. These
/// tests pin the corrected behaviour so it cannot regress.
void main() {
  group('DonorAvailabilityReader - canonical field', () {
    test('isAvailable: true resolves to available', () {
      expect(DonorAvailabilityReader.read({'isAvailable': true}), DonorAvailability.available);
    });

    test('isAvailable: false resolves to unavailable', () {
      expect(DonorAvailabilityReader.read({'isAvailable': false}), DonorAvailability.unavailable);
    });

    test('canonical field wins over a conflicting legacy field', () {
      expect(DonorAvailabilityReader.read({'isAvailable': false, 'availableNow': true}), DonorAvailability.unavailable);
      expect(DonorAvailabilityReader.read({'isAvailable': true, 'availableNow': false}), DonorAvailability.available);
    });
  });

  group('DonorAvailabilityReader - legacy fallback', () {
    test('availableNow is read when isAvailable is absent', () {
      expect(DonorAvailabilityReader.read({'availableNow': true}), DonorAvailability.available);
      expect(DonorAvailabilityReader.read({'availableNow': false}), DonorAvailability.unavailable);
    });

    test('a walk-in donor record (legacy field only) still resolves', () {
      final walkIn = <String, dynamic>{
        'fullName': 'Test Walk-in',
        'role': 'Donor',
        'verified': true,
        'availableNow': true,
        'source': 'walk-in',
      };
      expect(DonorAvailabilityReader.read(walkIn), DonorAvailability.available);
      expect(DonorAvailabilityReader.sourceField(walkIn), DonorAvailabilityReader.legacyField);
    });
  });

  group('DonorAvailabilityReader - missing is never available', () {
    test('an empty document resolves to unknown, not available', () {
      expect(DonorAvailabilityReader.read(const {}), DonorAvailability.unknown);
    });

    test('a null document resolves to unknown', () {
      expect(DonorAvailabilityReader.read(null), DonorAvailability.unknown);
    });

    test('an app-registered donor document (no availability field) is unknown', () {
      // Exactly the shape register_screen.dart writes today.
      final registered = <String, dynamic>{
        'fullName': 'Test Donor',
        'email': 'donor@example.test',
        'role': 'Donor',
        'phoneNumber': '',
        'isActive': true,
      };
      expect(DonorAvailabilityReader.read(registered), DonorAvailability.unknown);
      expect(DonorAvailabilityReader.read(registered).isConfirmedAvailable, isFalse);
      expect(DonorAvailabilityReader.sourceField(registered), isNull);
    });

    test('a non-boolean value is not guessed at', () {
      expect(DonorAvailabilityReader.read({'isAvailable': 'true'}), DonorAvailability.unknown);
      expect(DonorAvailabilityReader.read({'availableNow': 1}), DonorAvailability.unknown);
      expect(DonorAvailabilityReader.read({'isAvailable': null}), DonorAvailability.unknown);
    });

    test('a non-boolean canonical value still falls back to a usable legacy value', () {
      expect(DonorAvailabilityReader.read({'isAvailable': 'yes', 'availableNow': false}), DonorAvailability.unavailable);
    });
  });

  group('"Available only" filter', () {
    test('passes only positively confirmed donors', () {
      expect(DonorAvailabilityReader.passesAvailableOnlyFilter({'isAvailable': true}), isTrue);
      expect(DonorAvailabilityReader.passesAvailableOnlyFilter({'availableNow': true}), isTrue);
    });

    test('excludes unavailable and unknown donors', () {
      expect(DonorAvailabilityReader.passesAvailableOnlyFilter({'isAvailable': false}), isFalse);
      expect(DonorAvailabilityReader.passesAvailableOnlyFilter(const {}), isFalse);
      expect(DonorAvailabilityReader.passesAvailableOnlyFilter(null), isFalse);
    });
  });

  group('DonorAvailability presentation', () {
    test('every state has a distinct, non-empty label and explanation', () {
      final labels = DonorAvailability.values.map((a) => a.label).toSet();
      expect(labels.length, DonorAvailability.values.length);
      for (final state in DonorAvailability.values) {
        expect(state.label.trim(), isNotEmpty);
        expect(state.explanation.trim(), isNotEmpty);
      }
    });

    test('unknown sorts between confirmed available and confirmed unavailable', () {
      expect(DonorAvailability.available.sortWeight, lessThan(DonorAvailability.unknown.sortWeight));
      expect(DonorAvailability.unknown.sortWeight, lessThan(DonorAvailability.unavailable.sortWeight));
    });

    test('only the available state reports isConfirmedAvailable', () {
      expect(DonorAvailability.available.isConfirmedAvailable, isTrue);
      expect(DonorAvailability.unavailable.isConfirmedAvailable, isFalse);
      expect(DonorAvailability.unknown.isConfirmedAvailable, isFalse);
    });
  });
}
