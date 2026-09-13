import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/blood_inventory.dart';
import '../models/blood_request.dart';
import '../utils/alert_actions.dart';
import '../utils/request_assignment.dart';
import '../utils/request_escalation.dart';
import '../utils/request_status.dart';
import '../utils/stock_readiness.dart';

/// Centralises every Firestore write the Doctor/Hospital module makes,
/// so screens stay presentation-only (item #22 - code architecture).
/// Every action here also writes an entry to `auditLogs` (item #11).
class RequestService {
  RequestService._();
  static final RequestService instance = RequestService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('requests');
  CollectionReference<Map<String, dynamic>> get _auditLogs => _db.collection('auditLogs');
  CollectionReference<Map<String, dynamic>> get _alerts => _db.collection('alerts');

  DocumentReference<Map<String, dynamic>> requestRef(String requestId) => _requests.doc(requestId);

  // ---------------------------------------------------------------
  // Audit trail (#11)
  // ---------------------------------------------------------------
  Future<void> logAudit({
    required String action,
    required String requestId,
    required String performedBy,
    required String performedByName,
    Map<String, dynamic>? details,
  }) async {
    await _auditLogs.add({
      'action': action,
      'requestId': requestId,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'timestamp': FieldValue.serverTimestamp(),
      'details': ?details,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> auditTrail(String requestId) {
    return _auditLogs.where('requestId', isEqualTo: requestId).orderBy('timestamp', descending: true).snapshots();
  }

  // ---------------------------------------------------------------
  // Duplicate detection (#4) - operational heuristic, not a
  // definitive claim. Looks for other active requests at the same
  // hospital, for the same blood group, created close in time.
  // ---------------------------------------------------------------
  Future<List<BloodRequest>> findPossibleDuplicates(BloodRequest request) async {
    if (request.createdAt == null) return [];
    final snapshot = await _requests
        .where('hospitalName', isEqualTo: request.hospitalName)
        .where('bloodGroup', isEqualTo: request.bloodGroup)
        .where('status', whereIn: RequestStatus.activeStatuses)
        .limit(20)
        .get();

    return snapshot.docs.map(BloodRequest.fromDoc).where((r) => r.id != request.id).where((r) {
      if (r.createdAt == null) return false;
      final diff = r.createdAt!.difference(request.createdAt!).abs();
      // Same hospital + same blood group + created within a 24h
      // window is treated as a *possible* duplicate worth a
      // manual look - never asserted as definite.
      return diff.inHours <= 24;
    }).toList();
  }

  // ---------------------------------------------------------------
  // FR08 - verification workflow
  // ---------------------------------------------------------------
  // #two-person-verification - Critical urgency requests require a
  // second, different staff member to co-sign before the request
  // actually transitions to `verified`. Every other urgency level
  // keeps the original single-tap flow, unchanged.
  Future<void> verifyRequest(BloodRequest request, {required String doctorId, required String doctorName}) async {
    if (!RequestStatus.isValidTransition(request.status, RequestStatus.verified)) return;

    if (request.urgency == UrgencyLevel.critical) {
      if (request.firstApproverId == null) {
        // First co-sign only - status stays pending until a second,
        // different staff member confirms.
        await requestRef(request.id).update({
          'firstApproverId': doctorId,
          'firstApproverName': doctorName,
          'firstApprovedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await logAudit(
          action: 'request_first_approval',
          requestId: request.id,
          performedBy: doctorId,
          performedByName: doctorName,
          details: {'note': 'Critical request - awaiting a second, independent staff member to co-sign.'},
        );
        return;
      }
      if (request.firstApproverId == doctorId) {
        throw StateError('You already gave the first approval on this critical request. A different staff member must confirm it.');
      }
      await requestRef(request.id).update({
        'status': RequestStatus.verified,
        'verifiedBy': doctorName,
        'verifiedAt': FieldValue.serverTimestamp(),
        'secondApproverId': doctorId,
        'secondApproverName': doctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await logAudit(
        action: 'request_verified',
        requestId: request.id,
        performedBy: doctorId,
        performedByName: doctorName,
        details: {'firstApprover': request.firstApproverName, 'secondApprover': doctorName},
      );
      return;
    }

    await requestRef(request.id).update({
      'status': RequestStatus.verified,
      'verifiedBy': doctorName,
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await logAudit(action: 'request_verified', requestId: request.id, performedBy: doctorId, performedByName: doctorName);
  }

  Future<void> rejectRequest(BloodRequest request, {required String doctorId, required String doctorName, required String reason}) async {
    if (!RequestStatus.isValidTransition(request.status, RequestStatus.rejected)) return;
    await requestRef(request.id).update({
      'status': RequestStatus.rejected,
      'verifiedBy': doctorName,
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
    await logAudit(
      action: 'request_rejected',
      requestId: request.id,
      performedBy: doctorId,
      performedByName: doctorName,
      details: {'reason': reason},
    );
  }

  /// #10 - Re-verification workflow. Moves a rejected/expired request
  /// back to `pending` so it re-enters the verification queue after
  /// the recipient updates it. Uses the same `requests` collection -
  /// no second request-creation system is introduced.
  Future<void> requestReVerification(BloodRequest request, {required String doctorId, required String doctorName}) async {
    if (!RequestStatus.isValidTransition(request.status, RequestStatus.pending)) return;
    await requestRef(
      request.id,
    ).update({'status': RequestStatus.pending, 'rejectionReason': FieldValue.delete(), 'updatedAt': FieldValue.serverTimestamp()});
    await logAudit(action: 'reverification_requested', requestId: request.id, performedBy: doctorId, performedByName: doctorName);
  }

  // ---------------------------------------------------------------
  // FR09/FR10 - donor notification + response tracking
  // ---------------------------------------------------------------
  Future<void> notifyDonor({
    required String requestId,
    required Map<String, dynamic> donor,
    required int unitsPledged,
    required String doctorId,
    required String doctorName,
  }) async {
    // Prevent notifying the same donor twice for the same request
    // while they still have an active (non-declined) response on
    // file - a fresh notification is allowed again if they declined.
    final existing = await requestRef(requestId).collection('responses').where('donorId', isEqualTo: donor['donorId']).get();
    final alreadyActive = existing.docs.any((d) => d.data()['status'] != 'declined');
    if (alreadyActive) {
      throw StateError('${donor['donorName']} has already been notified for this request.');
    }

    await requestRef(requestId).collection('responses').add({
      'donorId': donor['donorId'],
      'donorName': donor['donorName'],
      'donorPhone': donor['donorPhone'],
      'bloodGroup': donor['bloodGroup'],
      'status': 'notified',
      'unitsPledged': unitsPledged,
      'notifiedBy': doctorName,
      'notifiedAt': FieldValue.serverTimestamp(),
    });

    await requestRef(requestId).update({'status': RequestStatus.matched, 'updatedAt': FieldValue.serverTimestamp()});

    await _recomputeCounts(requestId);

    await logAudit(
      action: 'donor_notified',
      requestId: requestId,
      performedBy: doctorId,
      performedByName: doctorName,
      details: {'donorName': donor['donorName']},
    );
  }

  Future<void> updateResponseStatus({
    required String requestId,
    required String responseId,
    required String donorId,
    required String donorName,
    required String status, // accepted, declined, completed
    required String doctorId,
    required String doctorName,
  }) async {
    await requestRef(
      requestId,
    ).collection('responses').doc(responseId).update({'status': status, 'respondedAt': FieldValue.serverTimestamp()});

    if (status == 'completed') {
      await _db.collection('users').doc(donorId).update({'lastDonationDate': FieldValue.serverTimestamp()});

      // Write exactly one donation history record for the completed donation
      final historyId = '${requestId}_$responseId';
      final historyRef = _db.collection('donation_history').doc(historyId);
      final existingHistory = await historyRef.get();

      if (!existingHistory.exists) {
        final respDoc = await requestRef(requestId).collection('responses').doc(responseId).get();
        final reqDoc = await requestRef(requestId).get();
        final respData = respDoc.data() ?? {};
        final reqData = reqDoc.data() ?? {};

        final bloodGroup = (respData['bloodGroup'] as String?)?.trim().isNotEmpty == true
            ? respData['bloodGroup']
            : (reqData['bloodGroup'] as String?) ?? '-';
        final hospitalName = (reqData['hospitalName'] as String?)?.trim().isNotEmpty == true
            ? reqData['hospitalName']
            : (respData['hospitalName'] as String?) ?? 'Hospital';
        final location = (reqData['location'] as String?)?.trim().isNotEmpty == true
            ? reqData['location']
            : 'Hospital';

        await historyRef.set({
          'donorId': donorId,
          'donorName': donorName,
          'bloodGroup': bloodGroup,
          'hospitalName': hospitalName,
          'location': location,
          'donationDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'completed',
          'requestId': requestId,
          'responseId': responseId,
          'verifiedBy': doctorName,
          'unitsDonated': (respData['unitsPledged'] as num?)?.toInt() ?? 1,
          'notes': 'Donation verified and completed by hospital staff.',
        });
      }
    }

    await _recomputeCounts(requestId);
    await _createResponseAlert(requestId: requestId, donorName: donorName, status: status);

    await logAudit(
      action: 'donor_response_$status',
      requestId: requestId,
      performedBy: doctorId,
      performedByName: doctorName,
      details: {'donorName': donorName},
    );
  }

  /// Recomputes the request's denormalised counters
  /// (`unitsConfirmed`, `donorsNotifiedCount`, `donorsAcceptedCount`)
  /// from its `responses` subcollection, and rolls the request's own
  /// status forward/back to reflect fulfilment progress. Kept as a
  /// one-shot read + write (not a listener) to avoid extra realtime
  /// listener overhead per item #19.
  Future<void> _recomputeCounts(String requestId) async {
    final reqSnap = await requestRef(requestId).get();
    final unitsNeeded = (reqSnap.data()?['unitsNeeded'] as num?)?.toInt() ?? 1;
    final currentStatus = reqSnap.data()?['status'] as String? ?? RequestStatus.pending;

    final responses = await requestRef(requestId).collection('responses').get();
    var notified = 0;
    var accepted = 0;
    var confirmedUnits = 0;
    for (final doc in responses.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'notified';
      final units = (data['unitsPledged'] as num?)?.toInt() ?? 1;
      notified++;
      if (status == 'accepted' || status == 'completed') {
        accepted++;
        confirmedUnits += units;
      }
    }

    final update = <String, dynamic>{
      'donorsNotifiedCount': notified,
      'donorsAcceptedCount': accepted,
      'unitsConfirmed': confirmedUnits,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only move the top-level status forward when it is still an
    // active, non-terminal state, so a rejected/expired request is
    // never silently re-activated by a stray response update (#20).
    if (RequestStatus.activeStatuses.contains(currentStatus)) {
      if (confirmedUnits >= unitsNeeded && unitsNeeded > 0) {
        update['status'] = RequestStatus.fulfilled;
      } else if (accepted == 0 && currentStatus == RequestStatus.matched && notified > 0) {
        // every notified donor declined - back to verified so staff
        // can search again.
        update['status'] = RequestStatus.verified;
      }
    }

    await requestRef(requestId).update(update);
  }

  // ---------------------------------------------------------------
  // #13 - Pin important requests (kept on the request document itself
  // so it is visible to every doctor account, consistent with the
  // rest of this Firestore-backed module).
  // ---------------------------------------------------------------
  Future<void> togglePin(String requestId, String doctorId, bool pin) async {
    await requestRef(requestId).update({
      'pinnedBy': pin ? FieldValue.arrayUnion([doctorId]) : FieldValue.arrayRemove([doctorId]),
    });
  }

  // ---------------------------------------------------------------
  // #8 - Smart Alert Center (Firestore-based, no FCM configured yet)
  // ---------------------------------------------------------------
  Future<void> _createResponseAlert({required String requestId, required String donorName, required String status}) async {
    if (status != 'accepted' && status != 'declined') return;
    final id = '${requestId}_${status}_$donorName'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    await _alerts.doc(id).set({
      'type': status == 'accepted' ? 'donor_accepted' : 'donor_declined',
      'requestId': requestId,
      'message': status == 'accepted' ? '$donorName accepted a donation request.' : '$donorName declined a donation request.',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    }, SetOptions(merge: true));
  }

  /// Deterministic alert for a newly-created critical pending request,
  /// so re-running this from multiple doctor devices never creates
  /// duplicate alerts (same doc id is simply overwritten/merged).
  Future<void> createCriticalRequestAlert(BloodRequest request) async {
    await _alerts.doc('critical_${request.id}').set({
      'type': 'critical_request',
      'requestId': request.id,
      'message': 'New CRITICAL request: ${request.bloodGroup} for ${request.patientName} at ${request.hospitalName}.',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    }, SetOptions(merge: true));
  }

  Future<void> createPendingVerificationAlert(BloodRequest request) async {
    await _alerts.doc('pending_${request.id}').set({
      'type': 'pending_verification',
      'requestId': request.id,
      'message': 'New request awaiting verification: ${request.bloodGroup} at ${request.hospitalName}.',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    }, SetOptions(merge: true));
  }

  Future<void> markAlertRead(String alertId, String doctorId) async {
    await _alerts.doc(alertId).update({
      'readBy': FieldValue.arrayUnion([doctorId]),
    });
  }

  /// #23 - "mark all read". Batches the update so marking a large
  /// alert list read is a single round-trip, not N sequential writes.
  Future<void> markAllAlertsRead(List<String> alertIds, String doctorId) async {
    if (alertIds.isEmpty) return;
    final batch = _db.batch();
    for (final id in alertIds) {
      batch.update(_alerts.doc(id), {
        'readBy': FieldValue.arrayUnion([doctorId]),
      });
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> alertsStream() {
    return _alerts.orderBy('createdAt', descending: true).limit(50).snapshots();
  }

  // ---------------------------------------------------------------
  // Walk-in donor registration
  // ---------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Registers a donor who walks into the hospital/blood bank in
  /// person, without going through the Donor module's own app
  /// sign-up flow. Writes to the SAME `users` collection and the SAME
  /// field names the Donor module and this module's search already
  /// read (`fullName`, `bloodGroup`, `phoneNumber`, `location`,
  /// `role`, `verified`, `availableNow`, `isActive`) so the record is
  /// indistinguishable to every other query in the app - it just
  /// shows up as a normal, staff-verified donor. `registeredBy` /
  /// `source` are additive fields only used to label the entry as
  /// walk-in on this screen; nothing else in the app depends on them.
  Future<String> registerWalkInDonor({
    required String fullName,
    required String bloodGroup,
    required String phoneNumber,
    required String location,
    required String doctorId,
    required String doctorName,
  }) async {
    final doc = await _users.add({
      'fullName': fullName,
      'bloodGroup': bloodGroup,
      'phoneNumber': phoneNumber,
      'location': location,
      'role': 'Donor',
      'verified': true, // staff verified them in person at registration time
      'isAvailable': true,
      'availableNow': true,
      'isActive': true,
      'source': 'walk-in',
      'registeredBy': doctorId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _auditLogs.add({
      'action': 'walk_in_donor_registered',
      'requestId': doc.id,
      'performedBy': doctorId,
      'performedByName': doctorName,
      'timestamp': FieldValue.serverTimestamp(),
      'details': {'fullName': fullName, 'bloodGroup': bloodGroup},
    });

    return doc.id;
  }

  // ---------------------------------------------------------------
  // Request ownership / assignment
  //
  // The rules live in `utils/request_assignment.dart`; the job here is
  // to apply them ATOMICALLY. Two operators tapping "Assign to me" on
  // the same request at the same moment is a realistic blood-bank
  // scenario, and a plain `update()` would silently let the second
  // write win. A transaction re-reads the document inside the commit,
  // so the loser is told who got it instead of quietly overwriting
  // their colleague.
  // ---------------------------------------------------------------

  /// Claims an unassigned request for [doctorId].
  ///
  /// Returns [AssignmentOutcome.conflict] (naming the current owner)
  /// when somebody else claimed it first, without writing anything.
  Future<AssignmentAttempt> claimRequest({required String requestId, required String doctorId, required String doctorName}) async {
    if (doctorId.trim().isEmpty) {
      return const AssignmentAttempt(AssignmentOutcome.notPermitted);
    }

    var outcome = AssignmentOutcome.notPermitted;
    String? ownerName;

    await _db.runTransaction((tx) async {
      // Reset per attempt: a transaction body can be retried.
      outcome = AssignmentOutcome.notPermitted;
      ownerName = null;

      final snapshot = await tx.get(requestRef(requestId));
      if (!snapshot.exists) {
        outcome = AssignmentOutcome.missing;
        return;
      }
      final data = snapshot.data() ?? <String, dynamic>{};
      final currentOwner = (data['assignedDoctorId'] as String?)?.trim() ?? '';

      if (currentOwner == doctorId) {
        outcome = AssignmentOutcome.noChange;
        return;
      }
      if (currentOwner.isNotEmpty) {
        outcome = AssignmentOutcome.conflict;
        ownerName = (data['assignedDoctorName'] as String?)?.trim();
        return;
      }

      tx.update(requestRef(requestId), {
        'assignedDoctorId': doctorId,
        'assignedDoctorName': doctorName,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      outcome = AssignmentOutcome.applied;
    });

    if (outcome == AssignmentOutcome.applied) {
      await logAudit(
        action: 'request_assigned',
        requestId: requestId,
        performedBy: doctorId,
        performedByName: doctorName,
        details: {'assignedTo': doctorName, 'via': 'assign_to_me'},
      );
    }
    return AssignmentAttempt(outcome, ownerName: ownerName);
  }

  /// Releases [doctorId]'s own claim on a request.
  ///
  /// Refuses (without writing) if the request is held by somebody else
  /// by the time the transaction runs.
  Future<AssignmentAttempt> releaseRequest({required String requestId, required String doctorId, required String doctorName}) async {
    var outcome = AssignmentOutcome.notPermitted;
    String? ownerName;

    await _db.runTransaction((tx) async {
      outcome = AssignmentOutcome.notPermitted;
      ownerName = null;

      final snapshot = await tx.get(requestRef(requestId));
      if (!snapshot.exists) {
        outcome = AssignmentOutcome.missing;
        return;
      }
      final data = snapshot.data() ?? <String, dynamic>{};
      final currentOwner = (data['assignedDoctorId'] as String?)?.trim() ?? '';

      if (currentOwner.isEmpty) {
        outcome = AssignmentOutcome.noChange;
        return;
      }
      if (currentOwner != doctorId) {
        outcome = AssignmentOutcome.conflict;
        ownerName = (data['assignedDoctorName'] as String?)?.trim();
        return;
      }

      tx.update(requestRef(requestId), {
        'assignedDoctorId': FieldValue.delete(),
        'assignedDoctorName': FieldValue.delete(),
        'assignedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      outcome = AssignmentOutcome.applied;
    });

    if (outcome == AssignmentOutcome.applied) {
      await logAudit(action: 'request_assignment_released', requestId: requestId, performedBy: doctorId, performedByName: doctorName);
    }
    return AssignmentAttempt(outcome, ownerName: ownerName);
  }

  /// Takes a request over from the operator who currently holds it.
  ///
  /// [previousOwnerName] is recorded in the audit trail so the handover
  /// is traceable. The UI only offers this after an explicit
  /// confirmation naming that operator.
  Future<AssignmentAttempt> reassignRequestToMe({required String requestId, required String doctorId, required String doctorName}) async {
    if (doctorId.trim().isEmpty) {
      return const AssignmentAttempt(AssignmentOutcome.notPermitted);
    }

    var outcome = AssignmentOutcome.notPermitted;
    String? previousOwnerName;

    await _db.runTransaction((tx) async {
      outcome = AssignmentOutcome.notPermitted;
      previousOwnerName = null;

      final snapshot = await tx.get(requestRef(requestId));
      if (!snapshot.exists) {
        outcome = AssignmentOutcome.missing;
        return;
      }
      final data = snapshot.data() ?? <String, dynamic>{};
      final currentOwner = (data['assignedDoctorId'] as String?)?.trim() ?? '';

      if (currentOwner == doctorId) {
        outcome = AssignmentOutcome.noChange;
        return;
      }
      previousOwnerName = (data['assignedDoctorName'] as String?)?.trim();

      tx.update(requestRef(requestId), {
        'assignedDoctorId': doctorId,
        'assignedDoctorName': doctorName,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      outcome = AssignmentOutcome.applied;
    });

    if (outcome == AssignmentOutcome.applied) {
      await logAudit(
        action: 'request_reassigned',
        requestId: requestId,
        performedBy: doctorId,
        performedByName: doctorName,
        details: {'takenFrom': previousOwnerName ?? 'an unnamed operator', 'assignedTo': doctorName},
      );
    }
    return AssignmentAttempt(outcome, ownerName: previousOwnerName);
  }

  // ---------------------------------------------------------------
  // Emergency escalation
  // ---------------------------------------------------------------

  /// Records an escalation level change, its reason, and an audit entry
  /// naming the actor and both levels.
  ///
  /// Validation is done by [EscalationRules.evaluate] before this is
  /// called; the check is repeated here so a mis-wired caller cannot
  /// write an unvalidated change.
  Future<bool> setEscalationLevel({
    required BloodRequest request,
    required EscalationLevel next,
    required String reason,
    required String doctorId,
    required String doctorName,
  }) async {
    final decision = EscalationRules.evaluate(requestStatus: request.status, current: request.escalationLevel, next: next, reason: reason);
    if (!decision.allowed) return false;

    await requestRef(request.id).update({
      'escalationLevel': next.value,
      'escalatedAt': FieldValue.serverTimestamp(),
      'escalationNote': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logAudit(
      action: decision.isEscalation ? 'request_escalated' : 'request_de_escalated',
      requestId: request.id,
      performedBy: doctorId,
      performedByName: doctorName,
      details: {
        'fromLevel': request.escalationLevel.value,
        'toLevel': next.value,
        'reason': reason.trim(),
        'summary': EscalationRules.auditSummary(actorName: doctorName, from: request.escalationLevel, to: next, reason: reason),
      },
    );

    if (next == EscalationLevel.critical) {
      await createEscalationAlert(request: request, level: next, reason: reason.trim());
    }
    return true;
  }

  /// Logs what a human actually did about a request.
  ///
  /// LifeLink has no SMS/email/push integration, so this never claims a
  /// message was delivered - it records an attempt, defaulting to
  /// "manual follow-up required".
  Future<void> recordResponseAttempt({
    required String requestId,
    required ResponseAttemptOutcome outcome,
    required String doctorId,
    required String doctorName,
    String? note,
  }) async {
    await logAudit(
      action: 'response_attempt_recorded',
      requestId: requestId,
      performedBy: doctorId,
      performedByName: doctorName,
      details: {'outcome': outcome.value, 'outcomeLabel': outcome.label, if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );
  }

  /// Adds a free-text note to a request's audit timeline.
  Future<void> addTimelineNote({
    required String requestId,
    required String note,
    required String doctorId,
    required String doctorName,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) return;
    await logAudit(
      action: 'timeline_note_added',
      requestId: requestId,
      performedBy: doctorId,
      performedByName: doctorName,
      details: {'note': trimmed},
    );
  }

  // ---------------------------------------------------------------
  // Blood stock readiness (`bloodInventory`)
  //
  // A new, isolated collection. No other module reads or writes it, so
  // adding it cannot affect the Donor, Recipient or Coordinator work.
  // ---------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _inventory => _db.collection('bloodInventory');

  /// Live stock lines, newest-updated first.
  ///
  /// Limited to [limit] documents: a blood bank has at most 8 groups x a
  /// handful of components per facility, so this is a generous bound
  /// that still prevents an unbounded read if the collection is misused.
  Stream<List<BloodInventoryItem>> inventoryStream({String? facilityId, int limit = 120}) {
    Query<Map<String, dynamic>> query = _inventory;
    if (facilityId != null && facilityId.trim().isNotEmpty) {
      query = query.where('facilityId', isEqualTo: facilityId.trim());
    }
    return query
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BloodInventoryItem.fromDoc).toList()..sort((a, b) => StockReadiness.compare(a, b)));
  }

  /// Records or updates one stock line.
  ///
  /// Used by the "Update stock" sheet. Staff enter the counts; LifeLink
  /// never estimates or seeds stock numbers of its own.
  Future<void> upsertInventoryLine({
    required String facilityId,
    required String bloodGroup,
    required String component,
    required int availableUnits,
    required int reservedUnits,
    required int minimumThreshold,
    required int expiryRiskUnits,
    required String doctorId,
    required String doctorName,
  }) async {
    // Deterministic id, so updating the same group+component line twice
    // edits one document instead of creating a duplicate row.
    final id = '${facilityId}_${bloodGroup}_$component'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    await _inventory.doc(id).set({
      'facilityId': facilityId,
      'bloodGroup': bloodGroup.toUpperCase(),
      'component': component,
      'availableUnits': availableUnits < 0 ? 0 : availableUnits,
      'reservedUnits': reservedUnits < 0 ? 0 : reservedUnits,
      'minimumThreshold': minimumThreshold < 0 ? 0 : minimumThreshold,
      'expiryRiskUnits': expiryRiskUnits < 0 ? 0 : expiryRiskUnits,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': doctorName,
    }, SetOptions(merge: true));

    await _auditLogs.add({
      'action': 'blood_stock_updated',
      'requestId': id,
      'performedBy': doctorId,
      'performedByName': doctorName,
      'timestamp': FieldValue.serverTimestamp(),
      'details': {
        'bloodGroup': bloodGroup.toUpperCase(),
        'component': component,
        'availableUnits': availableUnits,
        'reservedUnits': reservedUnits,
      },
    });
  }

  // ---------------------------------------------------------------
  // Additional actionable alerts
  //
  // Every id is deterministic (see AlertActions.documentId), so running
  // the same detection from several doctor devices merges onto one
  // document rather than creating duplicates.
  // ---------------------------------------------------------------

  Future<void> createEscalationAlert({required BloodRequest request, required EscalationLevel level, required String reason}) async {
    await _alerts.doc(AlertActions.documentId(type: AlertType.requestEscalated, key: request.id)).set({
      'type': AlertType.requestEscalated,
      'requestId': request.id,
      'message': 'Escalated to ${level.label}: ${request.bloodGroup} at ${request.hospitalName} — $reason',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    }, SetOptions(merge: true));
  }

  Future<void> createUnassignedUrgentAlert(BloodRequest request) async {
    await _alerts.doc(AlertActions.documentId(type: AlertType.unassignedUrgent, key: request.id)).set({
      'type': AlertType.unassignedUrgent,
      'requestId': request.id,
      'message': 'Unassigned ${request.urgency} request: ${request.bloodGroup} at ${request.hospitalName}.',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    }, SetOptions(merge: true));
  }

  Future<void> createLowStockAlert(BloodInventoryItem item, StockLevel level) async {
    final key = '${item.bloodGroup}_${item.component}';
    await _alerts.doc(AlertActions.documentId(type: AlertType.lowStock, key: key)).set({
      'type': AlertType.lowStock,
      // No requestId: this alert is about stock, and the action that
      // opens stock readiness needs no request reference.
      'message': '${level.label}: ${item.bloodGroup} ${BloodComponent.shortLabel(item.component)} — ${item.usableUnits} unit(s) free.',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    }, SetOptions(merge: true));
  }
}
