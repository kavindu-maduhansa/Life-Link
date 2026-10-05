import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/blood_request.dart';
import '../utils/donor_availability.dart';
import 'request_service.dart';

/// A donor as the coordinator module sees it.
///
/// Deliberately minimal: no phone number and no email are carried here,
/// so coordinator screens cannot display them by accident (FR12).
/// NOTE: this is presentation-layer minimisation. The Firestore document
/// is still delivered to the client (see docs data contract, section 8).
class CoordinatorDonor {
  final String uid;
  final String fullName;
  final String bloodGroup;
  final String location;
  final bool isActive;
  final DonorAvailability availability;
  final DateTime? lastDonationDate;

  const CoordinatorDonor({
    required this.uid,
    required this.fullName,
    required this.bloodGroup,
    required this.location,
    required this.isActive,
    required this.availability,
    required this.lastDonationDate,
  });

  /// Anonymous display code, e.g. "D-5CSP". Names are never shown.
  String get code {
    final short = uid.length >= 4 ? uid.substring(0, 4) : uid;
    return 'D-${short.toUpperCase()}';
  }

  factory CoordinatorDonor.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final last = data['lastDonationDate'];
    final location = data['location'];
    return CoordinatorDonor(
      uid: doc.id,
      fullName: (data['fullName'] as String?)?.trim() ?? '',
      bloodGroup: ((data['bloodGroup'] as String?) ?? '-').trim().toUpperCase(),
      location: location is String ? location.trim() : '',
      isActive: data['isActive'] != false,
      availability: DonorAvailabilityReader.read(data),
      lastDonationDate: last is Timestamp ? last.toDate() : null,
    );
  }
}

/// Red-cell donor compatibility, used only as a coordination aid.
/// The hospital laboratory confirms final compatibility (crossmatch).
class BloodCompatibility {
  const BloodCompatibility._();

  static const Map<String, List<String>> _donorsForRecipient = {
    'O-': ['O-'],
    'O+': ['O+', 'O-'],
    'A-': ['A-', 'O-'],
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'AB-': ['AB-', 'A-', 'B-', 'O-'],
    'AB+': ['AB+', 'AB-', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-'],
  };

  /// Donor groups that can give red cells to [recipientGroup], or null
  /// when the group is not recognised (so callers do not filter on a guess).
  static Set<String>? donorGroupsFor(String recipientGroup) {
    final list = _donorsForRecipient[recipientGroup.trim().toUpperCase()];
    return list?.toSet();
  }
}

/// Firestore access for the Organisation / Coordinator module.
/// Uses the team's existing `users`, `requests` and
/// `requests/{id}/responses` structures. No new collections.
class CoordinatorService {
  CoordinatorService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// A request is visible to coordinators once a hospital has verified it.
  static const _openStatuses = ['verified', 'matched'];

  String? get uid => _auth.currentUser?.uid;

  // ------------------------------------------------------------
  // Requests
  // ------------------------------------------------------------

  /// Requests a hospital has already verified (FR02 / FR03).
  /// Sorted on the client (urgency, then newest): no composite index.
  Stream<List<BloodRequest>> verifiedRequests() {
    return _db
        .collection('requests')
        .where('status', whereIn: _openStatuses)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(BloodRequest.fromDoc).toList();
      list.sort(_byUrgencyThenNewest);
      return list;
    });
  }

  /// A single request, for the Request Details screen.
  Stream<BloodRequest?> request(String requestId) {
    return _db
        .collection('requests')
        .doc(requestId)
        .snapshots()
        .map((d) => d.exists ? BloodRequest.fromDoc(d) : null);
  }

  // ------------------------------------------------------------
  // Donors (FR04 / FR09)
  // ------------------------------------------------------------

  /// All donor accounts. Filtering (blood group, location, availability)
  /// is done on the client so no composite index is needed.
  Stream<List<CoordinatorDonor>> donors() {
    return _db
        .collection('users')
        .where('role', whereIn: const ['Donor', 'donor'])
        .limit(300)
        .snapshots()
        .map((snap) => snap.docs.map(CoordinatorDonor.fromDoc).toList());
  }

  /// donorId -> latest response status for one request, so the UI can
  /// show "Notified" for donors who were already contacted.
  Stream<Map<String, String>> notifiedDonors(String requestId) {
    return _db
        .collection('requests')
        .doc(requestId)
        .collection('responses')
        .snapshots()
        .map((snap) {
      final result = <String, String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final donorId = data['donorId'];
        final status = (data['status'] as String?) ?? 'notified';
        if (donorId is! String) continue;
        final existing = result[donorId];
        // Prefer an active response over an older declined one.
        if (existing == null || existing == 'declined') {
          result[donorId] = status;
        }
      }
      return result;
    });
  }

  /// Full response records for one request, used by Response Tracking.
  /// Streams the `requests/{id}/responses` subcollection as typed objects.
  Stream<List<DonorResponseRecord>> responses(String requestId) {
    return _db
        .collection('requests')
        .doc(requestId)
        .collection('responses')
        .snapshots()
        .map((snap) => snap.docs.map(DonorResponseRecord.fromDoc).toList());
  }
  
  /// Latest donor responses across the open (verified / matched) requests,
  /// one entry per donor per request, newest first. A one-shot read (no
  /// listeners), so screens refresh with pull-to-refresh.
  Future<List<CoordinatorResponseEvent>> recentResponses({
    int maxRequests = 15,
  }) async {
    final requestSnap = await _db
        .collection('requests')
        .where('status', whereIn: _openStatuses)
        .get();

    final requests = requestSnap.docs.map(BloodRequest.fromDoc).toList()
      ..sort(_byUrgencyThenNewest);

    final perRequest = await Future.wait(
      requests.take(maxRequests).map((request) async {
        try {
          final snap = await _db
              .collection('requests')
              .doc(request.id)
              .collection('responses')
              .get();
          final merged = mergeByDonor(
            snap.docs.map(DonorResponseRecord.fromDoc).toList(),
          );
          return merged
              .map((r) => CoordinatorResponseEvent(
                    requestId: request.id,
                    donorUid: r.donorId,
                    bloodGroup: request.bloodGroup,
                    hospitalName: request.hospitalName,
                    status: r.status,
                    at: r.respondedAt ?? r.notifiedAt,
                  ))
              .toList();
        } catch (_) {
          // One unreadable request must not hide all the others.
          return <CoordinatorResponseEvent>[];
        }
      }),
    );

    final events = perRequest.expand((list) => list).toList();
    events.sort((a, b) {
      final x = a.at;
      final y = b.at;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return events;
  }

  /// Notifies a donor about a verified request (FR05 / FR11).
  ///
  /// Reuses the hospital module's own RequestService.notifyDonor, so a
  /// coordinator's notification is written in exactly the same shape:
  /// `requests/{id}/responses` document, request counters, audit log.
  /// The donor app already reads these in My Responses.
  ///
  /// The donor's phone is intentionally NOT copied into the response.
  /// LifeLink sends no SMS/email/push: the donor sees the request in the app.
    Future<void> notifyDonor({
    required BloodRequest request,
    required CoordinatorDonor donor,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in again.');
    }

    final displayName = user.displayName?.trim();
    final actorName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (user.email ?? 'Coordinator');

    await RequestService.instance.notifyDonor(
      requestId: request.id,
      donor: {
        'donorId': donor.uid,
        'donorName': donor.fullName.isNotEmpty ? donor.fullName : 'Donor',
        'donorPhone': '',
        'bloodGroup': donor.bloodGroup,
      },
      unitsPledged: 1,
      doctorId: user.uid,
      doctorName: actorName,
    );

    // The invitation now exists. Adding the request details is best effort.
    await _addRequestDetailsToInvitation(
      request: request,
      donorUid: donor.uid,
    );
  }

  /// The hospital module saves the invitation without a hospital name, so
  /// the donor app shows a generic "Emergency Blood Request" title. This
  /// adds a title that says it is a coordinator request, plus the same
  /// request fields the donor app saves on its own offers. If it fails the
  /// invitation is still recorded, so the failure is only logged.
  Future<void> _addRequestDetailsToInvitation({
    required BloodRequest request,
    required String donorUid,
  }) async {
    try {
    final snap = await _db
        .collection('requests')
        .doc(request.id)
        .collection('responses')
        .where('donorId', isEqualTo: donorUid)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['status'] != 'notified') continue;
      if (data['hospitalName'] != null ||
          data['organizationName'] != null) {
        continue;
      }
      await doc.reference.update({
        'organizationName': 'Coordinator request · ${request.hospitalName}',
        'requestId': request.id,
        'requestBloodGroup': request.bloodGroup,
        'urgency': request.urgency,
      });
    }
  } catch (e) {
    debugPrint('add request details to invitation failed: $e');
  }
}

  

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  /// One response per donor. A donor can have two documents for the same
  /// request: an invitation written by the coordinator and an offer the
  /// donor made from the Requests tab. Accepted/completed wins; otherwise
  /// the most recent one wins.
  static List<DonorResponseRecord> mergeByDonor(
      List<DonorResponseRecord> records) {
    bool isAccepted(DonorResponseRecord r) =>
        r.status == 'accepted' || r.status == 'completed';

    DateTime stamp(DonorResponseRecord r) =>
        r.respondedAt ??
        r.notifiedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final byDonor = <String, DonorResponseRecord>{};
    for (final r in records) {
      final current = byDonor[r.donorId];
      if (current == null) {
        byDonor[r.donorId] = r;
        continue;
      }
      final currentAccepted = isAccepted(current);
      final nextAccepted = isAccepted(r);
      if (nextAccepted && !currentAccepted) {
        byDonor[r.donorId] = r;
      } else if (nextAccepted == currentAccepted &&
          stamp(r).isAfter(stamp(current))) {
        byDonor[r.donorId] = r;
      }
    }
    return byDonor.values.toList();
  }

  static int _urgencyRank(String urgency) {
    switch (urgency) {
      case 'Critical':
        return 0;
      case 'High':
        return 1;
      default:
        return 2;
    }
  }

  static int _byUrgencyThenNewest(BloodRequest a, BloodRequest b) {
    final r = _urgencyRank(a.urgency).compareTo(_urgencyRank(b.urgency));
    if (r != 0) return r;
    final ad = a.createdAt;
    final bd = b.createdAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return bd.compareTo(ad);
  }
}


/// One donor's latest answer on one request, as the coordinator sees it.
/// Carries only the anonymous donor code: no name, phone or email.
class CoordinatorResponseEvent {
  final String requestId;
  final String donorUid;
  final String bloodGroup;
  final String hospitalName;
  final String status;
  final DateTime? at;

  const CoordinatorResponseEvent({
    required this.requestId,
    required this.donorUid,
    required this.bloodGroup,
    required this.hospitalName,
    required this.status,
    required this.at,
  });

  String get donorCode {
    final short = donorUid.length >= 4 ? donorUid.substring(0, 4) : donorUid;
    return 'D-${short.toUpperCase()}';
  }

  bool get isAccepted => status == 'accepted' || status == 'completed';

  bool get isPending =>
      !isAccepted && status != 'declined' && status != 'withdrawn';

  String get statusLabel {
    if (isAccepted) return 'Accepted';
    if (isPending) return 'Pending';
    return status == 'withdrawn' ? 'Withdrawn' : 'Declined';
  }

  bool get isToday {
    final t = at?.toLocal();
    if (t == null) return false;
    final now = DateTime.now();
    return t.year == now.year && t.month == now.month && t.day == now.day;
  }

  String get timeAgo {
    final t = at;
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }
}