import 'package:flutter_test/flutter_test.dart';

import 'package:hci/utils/alert_actions.dart';

/// Tests for the alert → action mapping that turns the Alert Centre into
/// a work queue, and for the fallbacks that stop a stale alert from
/// rendering a button that goes nowhere.
void main() {
  group('AlertActions.primaryFor - known types', () {
    test('a critical request opens the request', () {
      expect(AlertActions.primaryFor(AlertType.criticalRequest), AlertAction.openRequest);
    });

    test('an escalated request opens the request', () {
      expect(AlertActions.primaryFor(AlertType.requestEscalated), AlertAction.openRequest);
    });

    test('a pending verification opens the verify queue', () {
      expect(AlertActions.primaryFor(AlertType.pendingVerification), AlertAction.openVerifyQueue);
    });

    test('donor accepted/declined both open donor matches', () {
      expect(AlertActions.primaryFor(AlertType.donorAccepted), AlertAction.openDonorMatches);
      expect(AlertActions.primaryFor(AlertType.donorDeclined), AlertAction.openDonorMatches);
    });

    test('an unassigned urgent request offers Assign to me', () {
      expect(AlertActions.primaryFor(AlertType.unassignedUrgent), AlertAction.assignToMe);
    });

    test('low stock opens stock readiness', () {
      expect(AlertActions.primaryFor(AlertType.lowStock), AlertAction.openStockReadiness);
    });

    test('a stale request opens the request timeline', () {
      expect(AlertActions.primaryFor(AlertType.staleRequest), AlertAction.openRequestTimeline);
    });
  });

  group('AlertActions.primaryFor - fallbacks', () {
    test('an unknown type with a request reference still opens that request', () {
      expect(AlertActions.primaryFor('some_future_type'), AlertAction.openRequest);
    });

    test('an unknown type with no request reference degrades to mark-as-read', () {
      expect(AlertActions.primaryFor('some_future_type', hasRequestId: false), AlertAction.none);
    });

    test('a null type is handled without throwing', () {
      expect(AlertActions.primaryFor(null, hasRequestId: false), AlertAction.none);
    });

    test('a request-dependent action degrades when the reference is missing', () {
      for (final type in [
        AlertType.criticalRequest,
        AlertType.requestEscalated,
        AlertType.donorAccepted,
        AlertType.donorDeclined,
        AlertType.unassignedUrgent,
        AlertType.staleRequest,
      ]) {
        expect(
          AlertActions.primaryFor(type, hasRequestId: false),
          AlertAction.none,
          reason: '$type should not offer an action pointing at a missing request',
        );
      }
    });

    test('actions that need no request survive a missing reference', () {
      expect(AlertActions.primaryFor(AlertType.lowStock, hasRequestId: false), AlertAction.openStockReadiness);
      expect(AlertActions.primaryFor(AlertType.pendingVerification, hasRequestId: false), AlertAction.openVerifyQueue);
    });
  });

  group('AlertAction presentation', () {
    test('every action has a distinct, verb-first label', () {
      final labels = AlertAction.values.map((a) => a.label).toList();
      expect(labels.toSet().length, labels.length);
      for (final label in labels) {
        expect(label.trim(), isNotEmpty);
        expect(label, isNot('View'), reason: 'labels should say what happens, not "View"');
      }
    });

    test('requiresRequest is true exactly for the request-scoped actions', () {
      expect(AlertAction.openRequest.requiresRequest, isTrue);
      expect(AlertAction.openDonorMatches.requiresRequest, isTrue);
      expect(AlertAction.openRequestTimeline.requiresRequest, isTrue);
      expect(AlertAction.assignToMe.requiresRequest, isTrue);
      expect(AlertAction.openVerifyQueue.requiresRequest, isFalse);
      expect(AlertAction.openStockReadiness.requiresRequest, isFalse);
      expect(AlertAction.none.requiresRequest, isFalse);
    });
  });

  group('AlertActions.documentId - duplicate prevention', () {
    test('the same type and key always produce the same id', () {
      final a = AlertActions.documentId(type: AlertType.lowStock, key: 'O+_Platelets');
      final b = AlertActions.documentId(type: AlertType.lowStock, key: 'O+_Platelets');
      expect(a, b);
    });

    test('different keys produce different ids', () {
      expect(
        AlertActions.documentId(type: AlertType.lowStock, key: 'O+'),
        isNot(AlertActions.documentId(type: AlertType.lowStock, key: 'O-')),
      );
    });

    test('characters Firestore document ids dislike are replaced', () {
      final id = AlertActions.documentId(type: AlertType.lowStock, key: 'O+/Packed Red Cells');
      expect(id, isNot(contains('/')));
      expect(id, isNot(contains(' ')));
      expect(id, isNot(contains('+')));
    });
  });

  group('AlertActions.isReadBy', () {
    test('true when the uid is in readBy', () {
      expect(AlertActions.isReadBy(['a', 'b'], 'b'), isTrue);
    });

    test('false when the uid is absent', () {
      expect(AlertActions.isReadBy(['a'], 'b'), isFalse);
    });

    test('a missing or malformed readBy reads as unread rather than throwing', () {
      expect(AlertActions.isReadBy(null, 'b'), isFalse);
      expect(AlertActions.isReadBy('a,b', 'b'), isFalse);
      expect(AlertActions.isReadBy(const [], 'b'), isFalse);
    });

    test('a null or empty uid is never considered to have read anything', () {
      expect(AlertActions.isReadBy(['a'], null), isFalse);
      expect(AlertActions.isReadBy(['a'], ''), isFalse);
    });

    test('non-string entries are compared safely', () {
      expect(AlertActions.isReadBy([1, 'b'], 'b'), isTrue);
      expect(AlertActions.isReadBy([null, 'b'], 'b'), isTrue);
    });
  });

  test('the missing-reference notice explains why no action is offered', () {
    expect(AlertActions.missingReferenceNotice.trim(), isNotEmpty);
    expect(AlertActions.missingReferenceNotice.toLowerCase(), contains('no longer available'));
  });
}
