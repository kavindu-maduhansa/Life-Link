/// Emergency escalation vocabulary and validation for the Doctor/Blood
/// Bank module.
///
/// Escalation is an *operational* signal that staff raise deliberately.
/// It is deliberately separate from:
///   * `urgency` - set by the Recipient module when the request is created
///   * `RequestHealth` - an automatic SLA heuristic computed from waiting time
///
/// Keeping all three apart means a doctor can escalate a request that the
/// SLA heuristic still considers "on track", which is the whole point of
/// having a human in the loop.
///
/// HONESTY NOTE: LifeLink has no SMS, email, push or FCM integration
/// wired up (see `RequestService` - alerts are Firestore documents read
/// by the in-app Alert Centre only). Nothing in this file claims to
/// contact anybody. Recording an escalation records an *intent*, and the
/// UI labels the follow-up as manual.
library;

import 'request_status.dart';

/// How loudly a request is being flagged by staff, lowest to highest.
enum EscalationLevel {
  normal,
  watch,
  urgent,
  critical;

  /// The value stored in Firestore. Stable strings, so a level written
  /// today still parses after a rename of the enum member.
  String get value => switch (this) {
    EscalationLevel.normal => 'normal',
    EscalationLevel.watch => 'watch',
    EscalationLevel.urgent => 'urgent',
    EscalationLevel.critical => 'critical',
  };

  String get label => switch (this) {
    EscalationLevel.normal => 'Normal',
    EscalationLevel.watch => 'Watch',
    EscalationLevel.urgent => 'Urgent',
    EscalationLevel.critical => 'Critical',
  };

  /// What raising to this level actually commits staff to.
  String get meaning => switch (this) {
    EscalationLevel.normal => 'Handled in the normal queue.',
    EscalationLevel.watch => 'Flagged to be checked again shortly.',
    EscalationLevel.urgent => 'Needs an owner and active donor outreach now.',
    EscalationLevel.critical => 'Blood bank emergency handling - senior staff should be involved.',
  };

  /// 0 = normal … 3 = critical. Used for ordering and for deciding
  /// whether a change is an escalation or a de-escalation.
  int get rank => index;

  /// Levels at or above [urgent] are the ones the dashboard surfaces in
  /// the command area.
  bool get isRaised => rank >= EscalationLevel.urgent.rank;

  /// Only a move *to* critical demands a second look from the operator.
  bool get requiresConfirmation => this == EscalationLevel.critical;

  /// Parses a stored value, defaulting to [normal] for anything absent
  /// or unrecognised so an old request document still renders.
  static EscalationLevel parse(Object? raw) {
    if (raw is! String) return EscalationLevel.normal;
    final normalised = raw.trim().toLowerCase();
    for (final level in EscalationLevel.values) {
      if (level.value == normalised) return level;
    }
    return EscalationLevel.normal;
  }
}

/// Why a proposed escalation change was refused.
enum EscalationRefusal {
  /// The request is fulfilled, rejected or expired.
  requestClosed,

  /// The new level is the same as the current one.
  sameLevel,

  /// A reason is mandatory for every level change.
  reasonMissing,

  /// A reason was supplied but is too short to be useful in an audit.
  reasonTooShort;

  String get message => switch (this) {
    EscalationRefusal.requestClosed => 'This request is closed, so its escalation level cannot be changed.',
    EscalationRefusal.sameLevel => 'The request is already at that escalation level.',
    EscalationRefusal.reasonMissing => 'Record why the escalation level is changing.',
    EscalationRefusal.reasonTooShort => 'Give a slightly longer reason - this goes into the audit trail.',
  };
}

/// The outcome of validating a proposed escalation change.
class EscalationDecision {
  const EscalationDecision._({required this.allowed, this.refusal, this.requiresConfirmation = false, this.isEscalation = false});

  final bool allowed;
  final EscalationRefusal? refusal;

  /// True when the UI must show a confirmation dialog before writing.
  final bool requiresConfirmation;

  /// True when severity is going up, false when it is coming down.
  final bool isEscalation;

  String? get message => refusal?.message;
}

/// Minimum characters required in an escalation reason. Short enough not
/// to obstruct an emergency, long enough that the audit entry says
/// something.
const int kEscalationReasonMinLength = 4;

/// Validation for an escalation level change. Pure - no Firestore, no
/// widgets - so every branch is unit-testable.
class EscalationRules {
  const EscalationRules._();

  static EscalationDecision evaluate({
    required String requestStatus,
    required EscalationLevel current,
    required EscalationLevel next,
    required String reason,
  }) {
    if (RequestStatus.historyStatuses.contains(requestStatus)) {
      return const EscalationDecision._(allowed: false, refusal: EscalationRefusal.requestClosed);
    }
    if (current == next) {
      return const EscalationDecision._(allowed: false, refusal: EscalationRefusal.sameLevel);
    }

    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return const EscalationDecision._(allowed: false, refusal: EscalationRefusal.reasonMissing);
    }
    if (trimmed.length < kEscalationReasonMinLength) {
      return const EscalationDecision._(allowed: false, refusal: EscalationRefusal.reasonTooShort);
    }

    final isEscalation = next.rank > current.rank;
    return EscalationDecision._(
      allowed: true,
      // Confirm when arriving at critical, and also when standing down
      // from critical - both are decisions worth a deliberate tap.
      requiresConfirmation: next.requiresConfirmation || current == EscalationLevel.critical,
      isEscalation: isEscalation,
    );
  }

  /// The audit-trail sentence for a completed change. Written from the
  /// real actor and levels, never templated with invented detail.
  static String auditSummary({
    required String actorName,
    required EscalationLevel from,
    required EscalationLevel to,
    required String reason,
  }) {
    final direction = to.rank > from.rank ? 'escalated' : 'stood down';
    return '$actorName $direction this request from ${from.label} to ${to.label}: ${reason.trim()}';
  }
}

/// A logged attempt to reach somebody about a request.
///
/// LifeLink cannot place a call or send a message itself, so this records
/// what a human did (or still needs to do) rather than pretending a
/// notification was delivered.
enum ResponseAttemptOutcome {
  manualFollowUpRequired,
  contactedReached,
  contactedNoAnswer;

  String get value => switch (this) {
    ResponseAttemptOutcome.manualFollowUpRequired => 'manual_follow_up_required',
    ResponseAttemptOutcome.contactedReached => 'contacted_reached',
    ResponseAttemptOutcome.contactedNoAnswer => 'contacted_no_answer',
  };

  String get label => switch (this) {
    ResponseAttemptOutcome.manualFollowUpRequired => 'Manual follow-up required',
    ResponseAttemptOutcome.contactedReached => 'Contacted — reached',
    ResponseAttemptOutcome.contactedNoAnswer => 'Contacted — no answer',
  };

  /// Shown under the action list so nobody reads this as an automated
  /// notification feature.
  static const String disclaimer =
      'LifeLink does not send SMS, email or push notifications. Recording an attempt logs what staff did, for the audit trail.';
}
