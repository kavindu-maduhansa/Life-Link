import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hci/models/blood_request.dart';
import 'package:hci/utils/request_escalation.dart';

/// Tests for `BloodRequest.fromMap`, the parser every Doctor screen
/// depends on.
///
/// The critical property is backward compatibility: a request document
/// written by the Recipient module *before* this upgrade has none of the
/// clinical, assignment or escalation keys, and must still parse into a
/// complete object rather than throwing. These tests use plain maps, so
/// they run without initialising Firebase.
void main() {
  /// The exact shape the Recipient module writes today - nothing more.
  Map<String, dynamic> legacyDoc() => <String, dynamic>{
    'patientName': 'A. Perera',
    'bloodGroup': 'O+',
    'unitsNeeded': 3,
    'urgency': 'Critical',
    'hospitalName': 'General Hospital',
    'location': 'Colombo',
    'notes': 'Surgery scheduled',
    'createdBy': 'recipient-uid',
    'createdByName': 'B. Silva',
    'status': 'pending',
    'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1, 9, 30)),
  };

  group('legacy documents (no new fields)', () {
    test('parses without throwing and keeps every original field', () {
      final request = BloodRequest.fromMap('req-1', legacyDoc());

      expect(request.id, 'req-1');
      expect(request.patientName, 'A. Perera');
      expect(request.bloodGroup, 'O+');
      expect(request.unitsNeeded, 3);
      expect(request.urgency, 'Critical');
      expect(request.hospitalName, 'General Hospital');
      expect(request.status, 'pending');
      expect(request.createdAt, DateTime(2026, 3, 1, 9, 30));
    });

    test('every clinical field is null rather than invented', () {
      final request = BloodRequest.fromMap('req-1', legacyDoc());

      expect(request.patientReference, isNull);
      expect(request.ward, isNull);
      expect(request.requiredAt, isNull);
      expect(request.bloodComponent, isNull);
      expect(request.requestingOfficerName, isNull);
      expect(request.contactExtension, isNull);
      expect(request.crossmatchStatus, isNull);
      expect(request.hospitalId, isNull);
      expect(request.clinicalNotes, isNull);
    });

    test('assignment defaults to unassigned', () {
      final request = BloodRequest.fromMap('req-1', legacyDoc());

      expect(request.assignedDoctorId, isNull);
      expect(request.assignedDoctorName, isNull);
      expect(request.assignedAt, isNull);
      expect(request.isUnassigned, isTrue);
    });

    test('escalation defaults to normal and not escalated', () {
      final request = BloodRequest.fromMap('req-1', legacyDoc());

      expect(request.escalationLevel, EscalationLevel.normal);
      expect(request.escalatedAt, isNull);
      expect(request.escalationNote, isNull);
      expect(request.isEscalated, isFalse);
    });

    test('a completely empty document still parses with safe defaults', () {
      final request = BloodRequest.fromMap('req-empty', const <String, dynamic>{});

      expect(request.patientName, 'Unknown Patient');
      expect(request.bloodGroup, '-');
      expect(request.unitsNeeded, 1);
      expect(request.urgency, 'Normal');
      expect(request.status, 'pending');
      expect(request.unitsConfirmed, 0);
      expect(request.pinnedBy, isEmpty);
      expect(request.escalationLevel, EscalationLevel.normal);
      expect(request.isUnassigned, isTrue);
    });

    test('a null document map does not throw', () {
      expect(() => BloodRequest.fromMap('req-null', null), returnsNormally);
    });
  });

  group('new clinical fields', () {
    test('are read when present', () {
      final data = legacyDoc()
        ..addAll({
          'patientReference': 'MRN-88213',
          'ward': 'ICU 2',
          'requiredAt': Timestamp.fromDate(DateTime(2026, 3, 1, 14, 0)),
          'bloodComponent': 'Packed Red Cells',
          'requestingOfficerName': 'Dr. N. Fernando',
          'contactExtension': '4417',
          'crossmatchStatus': CrossmatchStatus.pending,
          'hospitalId': 'GH-COL-01',
          'clinicalNotes': 'Awaiting theatre confirmation',
        });

      final request = BloodRequest.fromMap('req-2', data);

      expect(request.patientReference, 'MRN-88213');
      expect(request.ward, 'ICU 2');
      expect(request.requiredAt, DateTime(2026, 3, 1, 14, 0));
      expect(request.bloodComponent, 'Packed Red Cells');
      expect(request.requestingOfficerName, 'Dr. N. Fernando');
      expect(request.contactExtension, '4417');
      expect(request.crossmatchStatus, CrossmatchStatus.pending);
      expect(request.hospitalId, 'GH-COL-01');
      expect(request.clinicalNotes, 'Awaiting theatre confirmation');
    });

    test('whitespace-only and non-string values resolve to null, not blank text', () {
      final data = legacyDoc()
        ..addAll({
          'ward': '   ',
          'patientReference': '',
          'contactExtension': 4417, // wrong type in Firestore
        });

      final request = BloodRequest.fromMap('req-3', data);

      expect(request.ward, isNull);
      expect(request.patientReference, isNull);
      expect(request.contactExtension, isNull);
    });

    test('text values are trimmed', () {
      final request = BloodRequest.fromMap('req-4', legacyDoc()..['ward'] = '  Ward 7  ');
      expect(request.ward, 'Ward 7');
    });

    test('the request id is never used as the patient reference', () {
      final request = BloodRequest.fromMap('firestore-doc-id-xyz', legacyDoc());
      expect(request.id, 'firestore-doc-id-xyz');
      expect(request.patientReference, isNull);
      expect(request.patientReference, isNot(request.id));
    });
  });

  group('assignment fields', () {
    test('are read and reported as assigned', () {
      final data = legacyDoc()
        ..addAll({
          'assignedDoctorId': 'doc-uid-1',
          'assignedDoctorName': 'Dr. Madhuwanthi',
          'assignedAt': Timestamp.fromDate(DateTime(2026, 3, 1, 10, 0)),
        });

      final request = BloodRequest.fromMap('req-5', data);

      expect(request.assignedDoctorId, 'doc-uid-1');
      expect(request.assignedDoctorName, 'Dr. Madhuwanthi');
      expect(request.assignedAt, DateTime(2026, 3, 1, 10, 0));
      expect(request.isUnassigned, isFalse);
    });

    test('an empty assignedDoctorId counts as unassigned', () {
      final request = BloodRequest.fromMap('req-6', legacyDoc()..['assignedDoctorId'] = '   ');
      expect(request.isUnassigned, isTrue);
    });
  });

  group('escalation fields', () {
    test('a stored level is parsed and reported as escalated', () {
      final data = legacyDoc()
        ..addAll({
          'escalationLevel': 'urgent',
          'escalatedAt': Timestamp.fromDate(DateTime(2026, 3, 1, 11, 0)),
          'escalationNote': 'No donors responding',
        });

      final request = BloodRequest.fromMap('req-7', data);

      expect(request.escalationLevel, EscalationLevel.urgent);
      expect(request.isEscalated, isTrue);
      expect(request.escalationNote, 'No donors responding');
    });

    test('an unrecognised level falls back to normal instead of throwing', () {
      final request = BloodRequest.fromMap('req-8', legacyDoc()..['escalationLevel'] = 'DEFCON 1');
      expect(request.escalationLevel, EscalationLevel.normal);
      expect(request.isEscalated, isFalse);
    });

    test('watch is recorded but does not count as raised', () {
      final request = BloodRequest.fromMap('req-9', legacyDoc()..['escalationLevel'] = 'watch');
      expect(request.escalationLevel, EscalationLevel.watch);
      expect(request.isEscalated, isFalse);
    });
  });

  group('two-person approval fields', () {
    test('the second approver is now read back, not only written', () {
      final data = legacyDoc()
        ..addAll({
          'status': 'verified',
          'firstApproverId': 'doc-a',
          'firstApproverName': 'Dr. A',
          'secondApproverId': 'doc-b',
          'secondApproverName': 'Dr. B',
        });

      final request = BloodRequest.fromMap('req-10', data);

      expect(request.firstApproverName, 'Dr. A');
      expect(request.secondApproverName, 'Dr. B');
    });

    test('a critical pending request with one approval awaits a second', () {
      final data = legacyDoc()..addAll({'firstApproverId': 'doc-a'});
      expect(BloodRequest.fromMap('req-11', data).awaitingSecondApproval, isTrue);
    });
  });

  group('timestamps', () {
    test('an unresolved server timestamp (null) does not throw', () {
      final request = BloodRequest.fromMap('req-12', legacyDoc()..['updatedAt'] = null);
      expect(request.updatedAt, isNull);
    });

    test('a plain DateTime is accepted as well as a Timestamp', () {
      final request = BloodRequest.fromMap('req-13', legacyDoc()..['requiredAt'] = DateTime(2026, 5, 5));
      expect(request.requiredAt, DateTime(2026, 5, 5));
    });
  });

  group('CrossmatchStatus', () {
    test('null renders as Not recorded rather than a guess', () {
      expect(CrossmatchStatus.label(null), 'Not recorded');
    });

    test('known values get human labels', () {
      expect(CrossmatchStatus.label(CrossmatchStatus.compatible), 'Crossmatch compatible');
      expect(CrossmatchStatus.label(CrossmatchStatus.incompatible), 'Crossmatch incompatible');
      expect(CrossmatchStatus.label(CrossmatchStatus.pending), 'Crossmatch pending');
      expect(CrossmatchStatus.label(CrossmatchStatus.notRequested), 'Not requested');
    });

    test('an unknown value is shown as-is instead of being dropped', () {
      expect(CrossmatchStatus.label('lab-hold'), 'lab-hold');
    });

    test('only an incompatible crossmatch is treated as blocking', () {
      expect(CrossmatchStatus.isBlocking(CrossmatchStatus.incompatible), isTrue);
      expect(CrossmatchStatus.isBlocking(CrossmatchStatus.pending), isFalse);
      expect(CrossmatchStatus.isBlocking(null), isFalse);
    });
  });
}
