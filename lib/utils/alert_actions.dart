/// Maps an alert in the Alert Centre to the one thing a doctor would
/// actually do about it.
///
/// Before this, every alert rendered the same way and left staff to go
/// find the relevant request themselves. Each alert type now resolves to
/// a single primary action with an explicit label, so the alert list
/// becomes a work queue.
///
/// Pure mapping - no Firestore, no navigation - so the type→action table
/// is unit-testable and there is exactly one place to change it.
library;

/// The alert `type` values written to the `alerts` collection.
///
/// The first four already existed and are unchanged, so alerts written
/// before this upgrade keep working. The rest are additive.
class AlertType {
  const AlertType._();

  // Pre-existing.
  static const donorAccepted = 'donor_accepted';
  static const donorDeclined = 'donor_declined';
  static const criticalRequest = 'critical_request';
  static const pendingVerification = 'pending_verification';

  // Added by this upgrade.
  static const unassignedUrgent = 'unassigned_urgent';
  static const lowStock = 'low_stock';
  static const staleRequest = 'stale_request';
  static const requestEscalated = 'request_escalated';
}

/// Where an alert sends the operator.
enum AlertAction {
  /// Open the request detail screen.
  openRequest,

  /// Open the request detail screen scrolled to donor coordination.
  openDonorMatches,

  /// Open the request detail screen scrolled to the audit timeline.
  openRequestTimeline,

  /// Switch to the Verify Requests tab.
  openVerifyQueue,

  /// Open the Blood Stock Readiness panel.
  openStockReadiness,

  /// Claim the referenced request without leaving the alert list.
  assignToMe,

  /// Nothing actionable - just mark it read.
  none;

  /// The button label. Verb-first and specific, never "View".
  String get label => switch (this) {
    AlertAction.openRequest => 'Open request',
    AlertAction.openDonorMatches => 'Open donor matches',
    AlertAction.openRequestTimeline => 'Open request timeline',
    AlertAction.openVerifyQueue => 'Open verify queue',
    AlertAction.openStockReadiness => 'Open stock readiness',
    AlertAction.assignToMe => 'Assign to me',
    AlertAction.none => 'Mark as read',
  };

  /// True when carrying out the action needs a `requestId` on the alert.
  bool get requiresRequest => switch (this) {
    AlertAction.openRequest => true,
    AlertAction.openDonorMatches => true,
    AlertAction.openRequestTimeline => true,
    AlertAction.assignToMe => true,
    AlertAction.openVerifyQueue => false,
    AlertAction.openStockReadiness => false,
    AlertAction.none => false,
  };
}

/// The alert type → action table, plus the fallback rules that keep a
/// stale alert from becoming a dead button.
class AlertActions {
  const AlertActions._();

  /// The primary action for an alert type. Unrecognised types - including
  /// any a teammate adds later - resolve to [AlertAction.openRequest]
  /// when they carry a request reference, and [AlertAction.none]
  /// otherwise, so a new alert type is never silently unusable.
  static AlertAction primaryFor(String? type, {bool hasRequestId = true}) {
    final action = switch (type) {
      AlertType.criticalRequest => AlertAction.openRequest,
      AlertType.requestEscalated => AlertAction.openRequest,
      AlertType.pendingVerification => AlertAction.openVerifyQueue,
      AlertType.donorAccepted => AlertAction.openDonorMatches,
      AlertType.donorDeclined => AlertAction.openDonorMatches,
      AlertType.unassignedUrgent => AlertAction.assignToMe,
      AlertType.lowStock => AlertAction.openStockReadiness,
      AlertType.staleRequest => AlertAction.openRequestTimeline,
      _ => hasRequestId ? AlertAction.openRequest : AlertAction.none,
    };

    // An alert whose referenced request is gone (or was never recorded)
    // degrades to "mark as read" instead of opening a missing document.
    if (action.requiresRequest && !hasRequestId) return AlertAction.none;
    return action;
  }

  /// Shown in place of the action when the referenced request has been
  /// deleted since the alert was written.
  static const String missingReferenceNotice = 'The request this alert refers to is no longer available.';

  /// Deterministic document id for an alert, so re-running the same
  /// detection from several doctor devices merges onto one document
  /// instead of creating duplicates. This mirrors the convention the
  /// pre-existing `critical_`/`pending_` alerts already use.
  static String documentId({required String type, required String key}) {
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${type}_$safeKey';
  }

  /// Whether [doctorId] has already read the alert, from its `readBy`
  /// array. A missing or malformed array reads as unread.
  static bool isReadBy(Object? readBy, String? doctorId) {
    if (doctorId == null || doctorId.isEmpty) return false;
    if (readBy is! List) return false;
    return readBy.any((entry) => entry?.toString() == doctorId);
  }
}
