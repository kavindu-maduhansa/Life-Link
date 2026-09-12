import 'package:flutter_test/flutter_test.dart';

import 'package:hci/utils/request_assignment.dart';

/// Tests for the request ownership rules.
///
/// The Firestore transaction in `RequestService.claimRequest` enforces
/// atomicity; these tests pin the *rules* it enforces - in particular
/// that claiming is only ever allowed on an unassigned request, which is
/// what makes a simultaneous double-claim resolvable rather than a
/// last-write-wins race.
void main() {
  const me = 'doctor-me';
  const other = 'doctor-other';

  group('AssignmentRules.stateFor', () {
    test('a null or blank assignee is unassigned', () {
      expect(AssignmentRules.stateFor(assignedDoctorId: null, currentUserId: me), AssignmentState.unassigned);
      expect(AssignmentRules.stateFor(assignedDoctorId: '', currentUserId: me), AssignmentState.unassigned);
      expect(AssignmentRules.stateFor(assignedDoctorId: '   ', currentUserId: me), AssignmentState.unassigned);
    });

    test('my own uid is assignedToMe', () {
      expect(AssignmentRules.stateFor(assignedDoctorId: me, currentUserId: me), AssignmentState.assignedToMe);
    });

    test('somebody else is assignedToOther', () {
      expect(AssignmentRules.stateFor(assignedDoctorId: other, currentUserId: me), AssignmentState.assignedToOther);
    });

    test('an assigned request with no signed-in user reads as assignedToOther, never mine', () {
      expect(AssignmentRules.stateFor(assignedDoctorId: other, currentUserId: null), AssignmentState.assignedToOther);
      expect(AssignmentRules.stateFor(assignedDoctorId: other, currentUserId: ''), AssignmentState.assignedToOther);
    });
  });

  group('canClaim', () {
    test('an unassigned request can be claimed', () {
      expect(AssignmentRules.canClaim(assignedDoctorId: null, currentUserId: me), isTrue);
    });

    test('a request I already hold cannot be claimed again', () {
      expect(AssignmentRules.canClaim(assignedDoctorId: me, currentUserId: me), isFalse);
    });

    test('a request somebody else holds cannot be claimed', () {
      expect(AssignmentRules.canClaim(assignedDoctorId: other, currentUserId: me), isFalse);
    });

    test('nobody can claim without being signed in', () {
      expect(AssignmentRules.canClaim(assignedDoctorId: null, currentUserId: null), isFalse);
      expect(AssignmentRules.canClaim(assignedDoctorId: null, currentUserId: '  '), isFalse);
    });
  });

  group('canRelease', () {
    test('I can release my own assignment', () {
      expect(AssignmentRules.canRelease(assignedDoctorId: me, currentUserId: me), isTrue);
    });

    test('I cannot release somebody else\'s assignment', () {
      expect(AssignmentRules.canRelease(assignedDoctorId: other, currentUserId: me), isFalse);
    });

    test('there is nothing to release on an unassigned request', () {
      expect(AssignmentRules.canRelease(assignedDoctorId: null, currentUserId: me), isFalse);
    });
  });

  group('canReassign', () {
    test('taking over another operator\'s request requires an explicit override', () {
      expect(AssignmentRules.canReassign(assignedDoctorId: other, currentUserId: me, allowOverride: false), isFalse);
      expect(AssignmentRules.canReassign(assignedDoctorId: other, currentUserId: me, allowOverride: true), isTrue);
    });

    test('reassignment is not offered for an unassigned request - that is a claim', () {
      expect(AssignmentRules.canReassign(assignedDoctorId: null, currentUserId: me, allowOverride: true), isFalse);
    });

    test('reassignment is not offered for my own request - that is a release', () {
      expect(AssignmentRules.canReassign(assignedDoctorId: me, currentUserId: me, allowOverride: true), isFalse);
    });
  });

  group('matchesFilter', () {
    test('All shows every request', () {
      for (final assignee in <String?>[null, me, other]) {
        expect(AssignmentRules.matchesFilter(filter: AssignmentFilter.all, assignedDoctorId: assignee, currentUserId: me), isTrue);
      }
    });

    test('Assigned to me shows only my requests', () {
      expect(AssignmentRules.matchesFilter(filter: AssignmentFilter.assignedToMe, assignedDoctorId: me, currentUserId: me), isTrue);
      expect(AssignmentRules.matchesFilter(filter: AssignmentFilter.assignedToMe, assignedDoctorId: other, currentUserId: me), isFalse);
      expect(AssignmentRules.matchesFilter(filter: AssignmentFilter.assignedToMe, assignedDoctorId: null, currentUserId: me), isFalse);
    });

    test('Unassigned shows only requests nobody holds', () {
      expect(AssignmentRules.matchesFilter(filter: AssignmentFilter.unassigned, assignedDoctorId: null, currentUserId: me), isTrue);
      expect(AssignmentRules.matchesFilter(filter: AssignmentFilter.unassigned, assignedDoctorId: me, currentUserId: me), isFalse);
      expect(AssignmentRules.matchesFilter(filter: AssignmentFilter.unassigned, assignedDoctorId: other, currentUserId: me), isFalse);
    });
  });

  group('outcomeMessage', () {
    test('a conflict names the operator who won the race', () {
      final message = AssignmentRules.outcomeMessage(AssignmentOutcome.conflict, ownerName: 'Dr. Silva');
      expect(message, contains('Dr. Silva'));
      expect(message.toLowerCase(), contains('nothing was changed'));
    });

    test('a conflict with no known owner still reads sensibly', () {
      final message = AssignmentRules.outcomeMessage(AssignmentOutcome.conflict, ownerName: '   ');
      expect(message, contains('Another operator'));
    });

    test('every outcome produces a non-empty message', () {
      for (final outcome in AssignmentOutcome.values) {
        expect(AssignmentRules.outcomeMessage(outcome).trim(), isNotEmpty);
      }
    });
  });

  group('presentation', () {
    test('filters and states all have distinct labels', () {
      expect(AssignmentFilter.values.map((f) => f.label).toSet().length, AssignmentFilter.values.length);
      expect(AssignmentState.values.map((s) => s.label).toSet().length, AssignmentState.values.length);
    });
  });
}
