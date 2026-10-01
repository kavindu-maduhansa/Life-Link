import 'package:flutter_test/flutter_test.dart';

import 'package:hci/utils/request_escalation.dart';
import 'package:hci/utils/request_status.dart';

/// Tests for escalation validation - the rules that decide whether a
/// level change is allowed, whether it needs a confirmation dialog, and
/// what the audit trail records.
void main() {
  group('EscalationLevel.parse', () {
    test('parses every stored value back to its level', () {
      for (final level in EscalationLevel.values) {
        expect(EscalationLevel.parse(level.value), level);
      }
    });

    test('is case- and whitespace-insensitive', () {
      expect(EscalationLevel.parse('  URGENT '), EscalationLevel.urgent);
      expect(EscalationLevel.parse('Critical'), EscalationLevel.critical);
    });

    test('absent, wrong-typed or unrecognised values default to normal', () {
      expect(EscalationLevel.parse(null), EscalationLevel.normal);
      expect(EscalationLevel.parse(3), EscalationLevel.normal);
      expect(EscalationLevel.parse('emergency'), EscalationLevel.normal);
    });
  });

  group('EscalationLevel ordering', () {
    test('ranks increase from normal to critical', () {
      expect(EscalationLevel.normal.rank, lessThan(EscalationLevel.watch.rank));
      expect(EscalationLevel.watch.rank, lessThan(EscalationLevel.urgent.rank));
      expect(EscalationLevel.urgent.rank, lessThan(EscalationLevel.critical.rank));
    });

    test('only urgent and critical count as raised', () {
      expect(EscalationLevel.normal.isRaised, isFalse);
      expect(EscalationLevel.watch.isRaised, isFalse);
      expect(EscalationLevel.urgent.isRaised, isTrue);
      expect(EscalationLevel.critical.isRaised, isTrue);
    });

    test('only critical requires confirmation by itself', () {
      expect(EscalationLevel.critical.requiresConfirmation, isTrue);
      expect(EscalationLevel.urgent.requiresConfirmation, isFalse);
    });

    test('every level has a distinct label and a stated meaning', () {
      expect(EscalationLevel.values.map((l) => l.label).toSet().length, EscalationLevel.values.length);
      for (final level in EscalationLevel.values) {
        expect(level.meaning.trim(), isNotEmpty);
      }
    });
  });

  group('EscalationRules.evaluate - refusals', () {
    test('a closed request cannot change escalation level', () {
      for (final closed in RequestStatus.historyStatuses) {
        final decision = EscalationRules.evaluate(
          requestStatus: closed,
          current: EscalationLevel.normal,
          next: EscalationLevel.urgent,
          reason: 'Donors not responding',
        );
        expect(decision.allowed, isFalse, reason: 'status $closed should be refused');
        expect(decision.refusal, EscalationRefusal.requestClosed);
        expect(decision.message, isNotNull);
      }
    });

    test('setting the level it is already at is refused as a no-op', () {
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.pending,
        current: EscalationLevel.urgent,
        next: EscalationLevel.urgent,
        reason: 'Still urgent',
      );
      expect(decision.allowed, isFalse);
      expect(decision.refusal, EscalationRefusal.sameLevel);
    });

    test('a missing reason is refused', () {
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.pending,
        current: EscalationLevel.normal,
        next: EscalationLevel.urgent,
        reason: '   ',
      );
      expect(decision.allowed, isFalse);
      expect(decision.refusal, EscalationRefusal.reasonMissing);
    });

    test('a too-short reason is refused, because it goes into the audit trail', () {
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.pending,
        current: EscalationLevel.normal,
        next: EscalationLevel.urgent,
        reason: 'no',
      );
      expect(decision.allowed, isFalse);
      expect(decision.refusal, EscalationRefusal.reasonTooShort);
    });

    test('every refusal exposes a non-empty message', () {
      for (final refusal in EscalationRefusal.values) {
        expect(refusal.message.trim(), isNotEmpty);
      }
    });
  });

  group('EscalationRules.evaluate - allowed changes', () {
    test('escalating an active request with a reason is allowed', () {
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.verified,
        current: EscalationLevel.normal,
        next: EscalationLevel.urgent,
        reason: 'No donor response after 40 minutes',
      );
      expect(decision.allowed, isTrue);
      expect(decision.isEscalation, isTrue);
      expect(decision.requiresConfirmation, isFalse);
      expect(decision.message, isNull);
    });

    test('escalating to critical requires confirmation', () {
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.matched,
        current: EscalationLevel.urgent,
        next: EscalationLevel.critical,
        reason: 'Theatre waiting, no units confirmed',
      );
      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isTrue);
      expect(decision.isEscalation, isTrue);
    });

    test('standing down from critical also requires confirmation', () {
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.matched,
        current: EscalationLevel.critical,
        next: EscalationLevel.watch,
        reason: 'Units secured from a partner facility',
      );
      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isTrue);
      expect(decision.isEscalation, isFalse);
    });

    test('de-escalating between lower levels needs no confirmation', () {
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.verified,
        current: EscalationLevel.urgent,
        next: EscalationLevel.watch,
        reason: 'Two donors on the way',
      );
      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isFalse);
      expect(decision.isEscalation, isFalse);
    });

    test('a reason of exactly the minimum length is accepted', () {
      final reason = 'a' * kEscalationReasonMinLength;
      final decision = EscalationRules.evaluate(
        requestStatus: RequestStatus.pending,
        current: EscalationLevel.normal,
        next: EscalationLevel.watch,
        reason: reason,
      );
      expect(decision.allowed, isTrue);
    });
  });

  group('EscalationRules.auditSummary', () {
    test('records the actor, both levels and the reason', () {
      final summary = EscalationRules.auditSummary(
        actorName: 'Dr. Madhuwanthi',
        from: EscalationLevel.normal,
        to: EscalationLevel.critical,
        reason: '  Theatre waiting  ',
      );
      expect(summary, contains('Dr. Madhuwanthi'));
      expect(summary, contains('Normal'));
      expect(summary, contains('Critical'));
      expect(summary, contains('Theatre waiting'));
      expect(summary, contains('escalated'));
    });

    test('a downward change reads as stood down, not escalated', () {
      final summary = EscalationRules.auditSummary(
        actorName: 'Dr. A',
        from: EscalationLevel.critical,
        to: EscalationLevel.normal,
        reason: 'Resolved',
      );
      expect(summary, contains('stood down'));
      expect(summary, isNot(contains('escalated')));
    });
  });

  group('ResponseAttemptOutcome - honest communication logging', () {
    test('the default outcome is manual follow-up, not a delivered notification', () {
      expect(ResponseAttemptOutcome.manualFollowUpRequired.label, 'Manual follow-up required');
    });

    test('no outcome claims an automated message was sent', () {
      for (final outcome in ResponseAttemptOutcome.values) {
        final label = outcome.label.toLowerCase();
        expect(label, isNot(contains('sms')));
        expect(label, isNot(contains('email')));
        expect(label, isNot(contains('notification')));
        expect(label, isNot(contains('sent')));
      }
    });

    test('the disclaimer states that LifeLink sends nothing itself', () {
      final text = ResponseAttemptOutcome.disclaimer.toLowerCase();
      expect(text, contains('does not send'));
    });

    test('stored values are stable and distinct', () {
      final values = ResponseAttemptOutcome.values.map((o) => o.value).toSet();
      expect(values.length, ResponseAttemptOutcome.values.length);
    });
  });
}
