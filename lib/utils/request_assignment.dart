/// Pure ownership rules for Doctor/Blood Bank request assignment.
///
/// Keeping the decisions here (instead of inside the Firestore
/// transaction or the widget) means "who is allowed to claim what" is
/// testable without Firebase, and the transaction in
/// `RequestService.claimRequest` only has to enforce the *atomicity*,
/// not re-derive the rules.
library;

/// How the request list is filtered by ownership.
enum AssignmentFilter {
  all,
  assignedToMe,
  unassigned;

  String get label => switch (this) {
    AssignmentFilter.all => 'All requests',
    AssignmentFilter.assignedToMe => 'Assigned to me',
    AssignmentFilter.unassigned => 'Unassigned',
  };
}

/// A request's ownership as it relates to the signed-in operator.
enum AssignmentState {
  unassigned,
  assignedToMe,
  assignedToOther;

  String get label => switch (this) {
    AssignmentState.unassigned => 'Unassigned',
    AssignmentState.assignedToMe => 'Assigned to you',
    AssignmentState.assignedToOther => 'Assigned',
  };
}

/// The result of attempting an ownership change.
enum AssignmentOutcome {
  /// The claim/release/reassign was applied.
  applied,

  /// Somebody else already owned it by the time the write ran. Nothing
  /// was changed; the UI must show who holds it now.
  conflict,

  /// The request document no longer exists.
  missing,

  /// The requested change would have been a no-op (already in that
  /// state), so nothing was written.
  noChange,

  /// The action is not permitted for this operator on this request.
  notPermitted,
}

/// The result of an ownership write, carrying enough context for the UI
/// to explain what happened without re-reading the document.
class AssignmentAttempt {
  const AssignmentAttempt(this.outcome, {this.ownerName});

  final AssignmentOutcome outcome;

  /// Who holds the request now. Only set for [AssignmentOutcome.conflict],
  /// where naming the winner is the whole point of the message.
  final String? ownerName;

  bool get succeeded => outcome == AssignmentOutcome.applied;

  String message({String? action}) => AssignmentRules.outcomeMessage(outcome, ownerName: ownerName, action: action);
}

/// Ownership rules, derived only from the request's own assignment
/// fields and the signed-in user's uid. No role table is consulted
/// here - see [AssignmentRules.canReassign] for why reassignment is
/// deliberately conservative.
class AssignmentRules {
  const AssignmentRules._();

  static AssignmentState stateFor({required String? assignedDoctorId, required String? currentUserId}) {
    final assigned = (assignedDoctorId ?? '').trim();
    if (assigned.isEmpty) return AssignmentState.unassigned;
    final me = (currentUserId ?? '').trim();
    if (me.isNotEmpty && assigned == me) return AssignmentState.assignedToMe;
    return AssignmentState.assignedToOther;
  }

  /// An operator may claim a request only while nobody holds it.
  /// Claiming something you already hold is a no-op, not a claim.
  static bool canClaim({required String? assignedDoctorId, required String? currentUserId}) {
    if ((currentUserId ?? '').trim().isEmpty) return false;
    return stateFor(assignedDoctorId: assignedDoctorId, currentUserId: currentUserId) == AssignmentState.unassigned;
  }

  /// An operator may release only their own assignment. Releasing
  /// somebody else's work is a reassignment, not a release.
  static bool canRelease({required String? assignedDoctorId, required String? currentUserId}) {
    return stateFor(assignedDoctorId: assignedDoctorId, currentUserId: currentUserId) == AssignmentState.assignedToMe;
  }

  /// Taking over a request another operator already holds.
  ///
  /// This project has no per-user permission or seniority data on the
  /// `users` document that would justify letting any doctor silently
  /// override a colleague, so reassignment is offered only when the
  /// caller passes [allowOverride] - which the UI sets only after an
  /// explicit confirmation naming the current owner. The action is
  /// always recorded in the audit timeline.
  static bool canReassign({required String? assignedDoctorId, required String? currentUserId, required bool allowOverride}) {
    if (!allowOverride) return false;
    return stateFor(assignedDoctorId: assignedDoctorId, currentUserId: currentUserId) == AssignmentState.assignedToOther;
  }

  /// Filters a request by the active ownership filter.
  static bool matchesFilter({required AssignmentFilter filter, required String? assignedDoctorId, required String? currentUserId}) {
    final state = stateFor(assignedDoctorId: assignedDoctorId, currentUserId: currentUserId);
    return switch (filter) {
      AssignmentFilter.all => true,
      AssignmentFilter.assignedToMe => state == AssignmentState.assignedToMe,
      AssignmentFilter.unassigned => state == AssignmentState.unassigned,
    };
  }

  /// Human-readable feedback for an [AssignmentOutcome], used for the
  /// snackbar so success, conflict and failure are never silent.
  static String outcomeMessage(AssignmentOutcome outcome, {String? ownerName, String? action}) {
    final verb = action ?? 'update the assignment';
    return switch (outcome) {
      AssignmentOutcome.applied => 'Assignment updated.',
      AssignmentOutcome.conflict =>
        '${ownerName == null || ownerName.trim().isEmpty ? 'Another operator' : ownerName} claimed this request first. Nothing was changed.',
      AssignmentOutcome.missing => 'This request no longer exists.',
      AssignmentOutcome.noChange => 'No change was needed.',
      AssignmentOutcome.notPermitted => 'You cannot $verb on this request.',
    };
  }
}
