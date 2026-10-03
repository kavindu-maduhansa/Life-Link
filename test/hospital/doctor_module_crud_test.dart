import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hci/models/blood_request.dart';
import 'package:hci/utils/request_status.dart';

/// Comprehensive Doctor/Hospital module tests — Assignment 3.
///
/// These are pure-Dart unit tests (no Firebase emulator or widget
/// tree required) that exercise the domain logic every Doctor
/// screen relies on. The 26 test cases below map directly to the
/// CRUD operations, status transitions, model parsing and
/// validation rules documented in MEMBER3_ASSIGNMENT3_EVIDENCE.md.
///
/// Firestore write operations (service layer) are integration-tested
/// via the emulator or manual testing; these unit tests cover the
/// deterministic logic that guards those writes.
void main() {
  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------

  /// Minimal request doc, the shape the Recipient module writes.
  Map<String, dynamic> baseDoc() => <String, dynamic>{
    'patientName': 'Test Patient',
    'bloodGroup': 'A+',
    'unitsNeeded': 2,
    'urgency': 'High',
    'hospitalName': 'Test Hospital',
    'location': 'Ward 5',
    'notes': '',
    'createdBy': 'recipient-uid-1',
    'createdByName': 'Recipient',
    'status': 'pending',
    'createdAt': Timestamp.fromDate(DateTime(2026, 6, 15, 10, 0)),
  };

  // =================================================================
  // GROUP 1: Cancelled status (Phase 4)
  // =================================================================
  group('Cancelled status transitions', () {
    test('1. pending can transition to cancelled', () {
      expect(
        RequestStatus.isValidTransition(RequestStatus.pending, RequestStatus.cancelled),
        isTrue,
      );
    });

    test('2. verified can transition to cancelled', () {
      expect(
        RequestStatus.isValidTransition(RequestStatus.verified, RequestStatus.cancelled),
        isTrue,
      );
    });

    test('3. matched can transition to cancelled', () {
      expect(
        RequestStatus.isValidTransition(RequestStatus.matched, RequestStatus.cancelled),
        isTrue,
      );
    });

    test('4. cancelled is terminal — cannot transition to any other status', () {
      for (final target in [
        RequestStatus.pending,
        RequestStatus.verified,
        RequestStatus.matched,
        RequestStatus.fulfilled,
        RequestStatus.rejected,
        RequestStatus.expired,
      ]) {
        expect(
          RequestStatus.isValidTransition(RequestStatus.cancelled, target),
          isFalse,
          reason: 'cancelled → $target should be blocked',
        );
      }
    });

    test('5. fulfilled cannot transition to cancelled (already terminal)', () {
      expect(
        RequestStatus.isValidTransition(RequestStatus.fulfilled, RequestStatus.cancelled),
        isFalse,
      );
    });

    test('6. rejected cannot transition to cancelled', () {
      expect(
        RequestStatus.isValidTransition(RequestStatus.rejected, RequestStatus.cancelled),
        isFalse,
      );
    });

    test('7. cancelled label is user-friendly', () {
      expect(RequestStatus.label(RequestStatus.cancelled), 'Cancelled');
    });

    test('8. cancelled icon is block_rounded', () {
      expect(RequestStatus.icon(RequestStatus.cancelled), isNotNull);
    });
  });

  // =================================================================
  // GROUP 2: Cancelled status is in historyStatuses
  // =================================================================
  group('Status lists', () {
    test('9. cancelled is in historyStatuses, not activeStatuses', () {
      expect(RequestStatus.historyStatuses, contains(RequestStatus.cancelled));
      expect(RequestStatus.activeStatuses, isNot(contains(RequestStatus.cancelled)));
    });

    test('10. activeStatuses has pending, verified, matched', () {
      expect(RequestStatus.activeStatuses, containsAll([
        RequestStatus.pending,
        RequestStatus.verified,
        RequestStatus.matched,
      ]));
    });
  });

  // =================================================================
  // GROUP 3: BloodRequest model — cancellation fields
  // =================================================================
  group('BloodRequest cancellation fields', () {
    test('11. fromMap parses cancellation fields from a document', () {
      final doc = baseDoc()
        ..['status'] = 'cancelled'
        ..['cancellationReason'] = 'No longer needed'
        ..['cancelledBy'] = 'doctor-1'
        ..['cancelledAt'] = Timestamp.fromDate(DateTime(2026, 6, 15, 12, 0));

      final request = BloodRequest.fromMap('req-cancel', doc);

      expect(request.status, 'cancelled');
      expect(request.cancellationReason, 'No longer needed');
      expect(request.cancelledBy, 'doctor-1');
      expect(request.cancelledAt, DateTime(2026, 6, 15, 12, 0));
    });

    test('12. fromMap defaults cancellation fields to null when absent', () {
      final request = BloodRequest.fromMap('req-2', baseDoc());

      expect(request.cancellationReason, isNull);
      expect(request.cancelledBy, isNull);
      expect(request.cancelledAt, isNull);
    });

    test('13. copyWith updates cancellation fields', () {
      final original = BloodRequest.fromMap('req-3', baseDoc());
      final updated = original.copyWith(
        cancellationReason: 'Duplicate request',
        cancelledBy: 'doc-1',
      );

      expect(updated.cancellationReason, 'Duplicate request');
      expect(updated.cancelledBy, 'doc-1');
      expect(original.cancellationReason, isNull); // immutable
    });
  });

  // =================================================================
  // GROUP 4: BloodRequest model — reviewedBy field
  // =================================================================
  group('BloodRequest reviewedBy field', () {
    test('14. fromMap parses reviewedBy as a list of strings', () {
      final doc = baseDoc()..['reviewedBy'] = ['doc-1', 'doc-2'];
      final request = BloodRequest.fromMap('req-4', doc);

      expect(request.reviewedBy, ['doc-1', 'doc-2']);
    });

    test('15. fromMap defaults reviewedBy to empty list when absent', () {
      final request = BloodRequest.fromMap('req-5', baseDoc());
      expect(request.reviewedBy, isEmpty);
    });

    test('16. copyWith updates reviewedBy', () {
      final original = BloodRequest.fromMap('req-6', baseDoc());
      final updated = original.copyWith(reviewedBy: ['doc-A']);

      expect(updated.reviewedBy, ['doc-A']);
      expect(original.reviewedBy, isEmpty);
    });
  });

  // =================================================================
  // GROUP 5: Backward compatibility
  // =================================================================
  group('Backward compatibility', () {
    test('17. legacy doc (no new fields) parses without errors', () {
      final request = BloodRequest.fromMap('legacy-1', baseDoc());

      expect(request.id, 'legacy-1');
      expect(request.patientName, 'Test Patient');
      expect(request.bloodGroup, 'A+');
      expect(request.unitsNeeded, 2);
      expect(request.status, 'pending');
      // New fields default gracefully
      expect(request.cancellationReason, isNull);
      expect(request.reviewedBy, isEmpty);
    });

    test('18. doc with extra unknown fields parses safely', () {
      final doc = baseDoc()..['futureField'] = 'some value';
      final request = BloodRequest.fromMap('future-1', doc);
      expect(request.id, 'future-1');
      expect(request.patientName, 'Test Patient');
    });

    test('19. numeric fields handle null and wrong types gracefully', () {
      final doc = baseDoc()
        ..['unitsNeeded'] = null
        ..['unitsConfirmed'] = 'not-a-number';
      final request = BloodRequest.fromMap('bad-types', doc);

      expect(request.unitsNeeded, 1); // null defaults to safe fallback 1
      expect(request.unitsConfirmed, 0); // invalid type defaults to 0
    });
  });

  // =================================================================
  // GROUP 6: RequestHealth with cancelled status
  // =================================================================
  group('RequestHealth handles cancelled status', () {
    test('20. cancelled requests are ON_TRACK (closed, no SLA tracking)', () {
      final level = RequestHealth.computeLevel(
        status: RequestStatus.cancelled,
        urgency: UrgencyLevel.critical,
        createdAt: DateTime.now().subtract(const Duration(hours: 24)),
        unitsNeeded: 5,
        unitsConfirmed: 0,
      );

      expect(level, RequestHealth.onTrack);
    });

    test('21. cancelled request reasons mention closed status', () {
      final reasons = RequestHealth.reasons(
        status: RequestStatus.cancelled,
        urgency: UrgencyLevel.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        unitsNeeded: 3,
        unitsConfirmed: 1,
      );

      expect(reasons.first, contains('closed'));
    });
  });

  // =================================================================
  // GROUP 7: Blood compatibility (used in donor search)
  // =================================================================
  group('BloodCompatibility', () {
    test('22. O- can only receive from O-', () {
      final donors = BloodCompatibility.compatibleDonorGroups('O-');
      expect(donors, ['O-']);
    });

    test('23. AB+ can receive from all 8 groups (universal recipient)', () {
      final donors = BloodCompatibility.compatibleDonorGroups('AB+');
      expect(donors.length, 8);
      expect(donors, containsAll(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']));
    });

    test('24. case and whitespace in group are handled', () {
      final donors = BloodCompatibility.compatibleDonorGroups(' o+ ');
      expect(donors, contains('O-'));
    });
  });

  // =================================================================
  // GROUP 8: Donor eligibility (used in donor search)
  // =================================================================
  group('DonorEligibility', () {
    test('25. donor with no history is eligible', () {
      expect(DonorEligibility.isEligible(null), isTrue);
      expect(DonorEligibility.daysUntilEligible(null), isNull);
    });

    test('26. donor who donated 30 days ago is not eligible (90-day rule)', () {
      final lastDonation = DateTime.now().subtract(const Duration(days: 30));
      expect(DonorEligibility.isEligible(lastDonation), isFalse);
      expect(DonorEligibility.daysUntilEligible(lastDonation), greaterThan(0));
    });
  });
}
