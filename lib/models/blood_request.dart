import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/request_escalation.dart';

/// Represents a single emergency blood request document from the
/// `requests` Firestore collection.
///
/// Team integration note: `patientName`, `bloodGroup`, `unitsNeeded`,
/// `urgency`, `hospitalName`, `location`, `notes`, `createdBy`,
/// `createdByName`, `status`, `createdAt` are the Recipient module's
/// original fields and are read as-is here, unchanged. Every field
/// added below by the Doctor module (`unitsConfirmed`,
/// `donorsNotifiedCount`, `donorsAcceptedCount`, `pinnedBy`, the
/// two-person approval fields, the clinical detail fields, the
/// assignment fields and the escalation fields) is additive and
/// defaults safely to null/0/empty when absent, so it never breaks a
/// request document written before this upgrade.
///
/// Parsing lives in [fromMap] and [fromDoc] is a thin wrapper, so the
/// backward-compatibility rules can be unit tested without initialising
/// Firebase. See `test/models/blood_request_test.dart`.
class BloodRequest {
  final String id;
  final String patientName;
  final String bloodGroup;
  final int unitsNeeded;
  final String urgency; // Critical, High, Normal
  final String hospitalName;
  final String location;
  final String notes;
  final String createdBy;
  final String createdByName;
  final String status; // pending, verified, matched, fulfilled, rejected, expired
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Doctor-module additions (all additive / backward compatible).
  final int unitsConfirmed;
  final int donorsNotifiedCount;
  final int donorsAcceptedCount;
  final List<String> pinnedBy;

  // #two-person-verification - Critical urgency requests require a
  // second, different staff member to co-sign before the request
  // actually moves to `verified`. These fields record who gave the
  // first approval and when; they stay null for every other urgency
  // level and for requests verified before this feature.
  final String? firstApproverId;
  final String? firstApproverName;
  final DateTime? firstApprovedAt;

  /// Who provided the second, independent co-sign. `RequestService`
  /// already wrote these two fields; they are now read back so the
  /// details screen can name both approvers instead of only the first.
  final String? secondApproverId;
  final String? secondApproverName;

  // ---------------------------------------------------------------
  // Clinical detail (all optional, all null when not recorded).
  //
  // The Recipient module owns request creation and does not collect
  // these yet, so in the current build they are normally null and the
  // UI renders "Not recorded". They exist so that when request creation
  // starts capturing them, the Doctor screens already display them -
  // and so that nothing here is ever invented to fill a gap.
  // ---------------------------------------------------------------

  /// The hospital's own patient identifier. Distinct from [id], which is
  /// the Firestore *request* document id and must never be presented as
  /// a patient identifier.
  final String? patientReference;

  final String? ward;

  /// When the blood is actually needed by, as opposed to when the
  /// request was created.
  final DateTime? requiredAt;

  /// See `BloodComponent` in `models/blood_inventory.dart`.
  final String? bloodComponent;

  final String? requestingOfficerName;
  final String? contactExtension;

  /// See [CrossmatchStatus].
  final String? crossmatchStatus;

  final String? hospitalId;
  final String? clinicalNotes;

  // ---------------------------------------------------------------
  // Ownership (see utils/request_assignment.dart for the rules).
  // ---------------------------------------------------------------
  final String? assignedDoctorId;
  final String? assignedDoctorName;
  final DateTime? assignedAt;

  // ---------------------------------------------------------------
  // Escalation (see utils/request_escalation.dart).
  // ---------------------------------------------------------------

  /// Stored as a lowercase string; absent or unrecognised values parse
  /// to [EscalationLevel.normal].
  final EscalationLevel escalationLevel;
  final DateTime? escalatedAt;
  final String? escalationNote;

  // Recipient-module additions (all additive / backward compatible).
  final String? requestType;
  final String? requestingFor;
  final int? patientAge;
  final String? relationship;
  final String? patientId;
  final String? reason;
  final DateTime? requiredBefore;
  final String? hospitalLocation;
  final String? wardUnit;
  final String? doctorClinic;
  final String? bloodNeededBy;
  final String? contactNumber;
  final String? preferredUpdateMethod;
  final int verifiedDonorsCount;

  const BloodRequest({
    this.id = '',
    required this.patientName,
    required this.bloodGroup,
    required this.unitsNeeded,
    required this.urgency,
    required this.hospitalName,
    this.location = '',
    this.notes = '',
    required this.createdBy,
    this.createdByName = 'Recipient',
    this.status = 'pending',
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.unitsConfirmed = 0,
    this.donorsNotifiedCount = 0,
    this.donorsAcceptedCount = 0,
    this.pinnedBy = const [],
    this.firstApproverId,
    this.firstApproverName,
    this.firstApprovedAt,
    this.secondApproverId,
    this.secondApproverName,
    this.patientReference,
    this.ward,
    this.requiredAt,
    this.bloodComponent,
    this.requestingOfficerName,
    this.contactExtension,
    this.crossmatchStatus,
    this.hospitalId,
    this.clinicalNotes,
    this.assignedDoctorId,
    this.assignedDoctorName,
    this.assignedAt,
    this.escalationLevel = EscalationLevel.normal,
    this.escalatedAt,
    this.escalationNote,
    this.requestType,
    this.requestingFor,
    this.patientAge,
    this.relationship,
    this.patientId,
    this.reason,
    this.requiredBefore,
    this.hospitalLocation,
    this.wardUnit,
    this.doctorClinic,
    this.bloodNeededBy,
    this.contactNumber,
    this.preferredUpdateMethod,
    this.verifiedDonorsCount = 0,
  });

  int get unitsRemaining => (unitsNeeded - unitsConfirmed).clamp(0, unitsNeeded);

  bool isPinnedBy(String? uid) => uid != null && pinnedBy.contains(uid);

  /// True only for a Critical-urgency request that has its first
  /// co-sign recorded but has not yet been fully verified by a second,
  /// different staff member.
  bool get awaitingSecondApproval => urgency == 'Critical' && status == 'pending' && firstApproverId != null;

  /// True when no operator currently owns this request.
  bool get isUnassigned => (assignedDoctorId ?? '').trim().isEmpty;

  /// True when staff have raised this request to Urgent or Critical.
  bool get isEscalated => escalationLevel.isRaised;

  factory BloodRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BloodRequest.fromMap(doc.id, doc.data());
  }

  factory BloodRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BloodRequest.fromMap(doc.id, doc.data());
  }

  /// Parses a raw `requests` document map.
  ///
  /// Every read is null-tolerant: a document written before this upgrade
  /// has none of the clinical, assignment or escalation keys and still
  /// parses into a complete object with nulls and safe defaults.
  factory BloodRequest.fromMap(String id, Map<String, dynamic>? raw) {
    final data = raw ?? <String, dynamic>{};
    return BloodRequest(
      id: id,
      patientName: (data['patientName'] as String?)?.trim().isNotEmpty == true ? data['patientName'] as String : 'Unknown Patient',
      bloodGroup: data['bloodGroup'] as String? ?? '-',
      unitsNeeded: (data['unitsNeeded'] as num?)?.toInt() ?? (data['requiredUnits'] as num?)?.toInt() ?? 1,
      urgency: data['urgency'] as String? ?? data['urgencyLevel'] as String? ?? 'Normal',
      hospitalName: data['hospitalName'] as String? ?? '-',
      location: data['location'] as String? ?? data['hospitalLocation'] as String? ?? '-',
      notes: (data['notes'] ?? data['description'] ?? data['reason']) as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Recipient',
      status: data['status'] as String? ?? 'pending',
      verifiedBy: data['verifiedBy'] as String?,
      verifiedAt: _toDate(data['verifiedAt']),
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      unitsConfirmed: (data['unitsConfirmed'] as num?)?.toInt() ?? 0,
      donorsNotifiedCount: (data['donorsNotifiedCount'] as num?)?.toInt() ?? 0,
      donorsAcceptedCount: (data['donorsAcceptedCount'] as num?)?.toInt() ?? 0,
      pinnedBy: (data['pinnedBy'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      firstApproverId: data['firstApproverId'] as String?,
      firstApproverName: data['firstApproverName'] as String?,
      firstApprovedAt: _toDate(data['firstApprovedAt']),
      secondApproverId: data['secondApproverId'] as String?,
      secondApproverName: data['secondApproverName'] as String?,
      patientReference: _text(data['patientReference']) ?? _text(data['patientId']),
      ward: _text(data['ward']) ?? _text(data['wardUnit']),
      requiredAt: _toDate(data['requiredAt']) ?? _toDate(data['requiredBefore']),
      bloodComponent: _text(data['bloodComponent']),
      requestingOfficerName: _text(data['requestingOfficerName']),
      contactExtension: _text(data['contactExtension']) ?? _text(data['contactNumber']),
      crossmatchStatus: _text(data['crossmatchStatus']),
      hospitalId: _text(data['hospitalId']),
      clinicalNotes: _text(data['clinicalNotes']),
      assignedDoctorId: _text(data['assignedDoctorId']),
      assignedDoctorName: _text(data['assignedDoctorName']),
      assignedAt: _toDate(data['assignedAt']),
      escalationLevel: EscalationLevel.parse(data['escalationLevel']),
      escalatedAt: _toDate(data['escalatedAt']),
      escalationNote: _text(data['escalationNote']),
      requestType: data['requestType'] as String?,
      requestingFor: data['requestingFor'] as String?,
      patientAge: (data['patientAge'] as num?)?.toInt(),
      relationship: data['relationship'] as String?,
      patientId: _text(data['patientId']) ?? _text(data['patientReference']),
      reason: _text(data['reason']) ?? _text(data['notes']) ?? _text(data['description']),
      requiredBefore: _toDate(data['requiredBefore']) ?? _toDate(data['requiredAt']),
      hospitalLocation: _text(data['hospitalLocation']) ?? _text(data['location']),
      wardUnit: _text(data['wardUnit']) ?? _text(data['ward']),
      doctorClinic: _text(data['doctorClinic']),
      bloodNeededBy: _text(data['bloodNeededBy']),
      contactNumber: _text(data['contactNumber']) ?? _text(data['contactExtension']),
      preferredUpdateMethod: _text(data['preferredUpdateMethod']),
      verifiedDonorsCount: (data['verifiedDonorsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'createdByName': createdByName,
      'requestType': requestType ?? (urgency.toLowerCase().contains('critical') || urgency.toLowerCase().contains('emergency') ? 'emergency' : 'non-emergency'),
      'requestingFor': requestingFor ?? 'self',
      'patientName': patientName,
      if (patientAge != null) 'patientAge': patientAge,
      if (relationship != null) 'relationship': relationship,
      'patientId': patientId ?? patientReference ?? '',
      'patientReference': patientReference ?? patientId ?? '',
      'bloodGroup': bloodGroup,
      'unitsNeeded': unitsNeeded,
      'reason': reason ?? notes,
      'notes': notes.isNotEmpty ? notes : (reason ?? ''),
      if (requiredBefore != null) 'requiredBefore': Timestamp.fromDate(requiredBefore!),
      if (requiredAt != null) 'requiredAt': Timestamp.fromDate(requiredAt!),
      'hospitalId': hospitalId ?? '',
      'hospitalName': hospitalName,
      'hospitalLocation': hospitalLocation ?? (location.isNotEmpty && location != '-' ? location : 'Not specified'),
      'location': location.isNotEmpty && location != '-' ? location : (hospitalLocation ?? '-'),
      'wardUnit': wardUnit ?? ward ?? '',
      'ward': ward ?? wardUnit ?? '',
      'doctorClinic': doctorClinic ?? '',
      'urgency': urgency,
      if (bloodNeededBy != null) 'bloodNeededBy': bloodNeededBy,
      if (contactNumber != null) 'contactNumber': contactNumber,
      if (preferredUpdateMethod != null) 'preferredUpdateMethod': preferredUpdateMethod,
      'status': status,
      'verifiedDonorsCount': verifiedDonorsCount,
      'unitsConfirmed': unitsConfirmed,
      'donorsNotifiedCount': donorsNotifiedCount,
      'donorsAcceptedCount': donorsAcceptedCount,
      'pinnedBy': pinnedBy,
      if (firstApproverId != null) 'firstApproverId': firstApproverId,
      if (firstApproverName != null) 'firstApproverName': firstApproverName,
      if (firstApprovedAt != null) 'firstApprovedAt': Timestamp.fromDate(firstApprovedAt!),
      if (secondApproverId != null) 'secondApproverId': secondApproverId,
      if (secondApproverName != null) 'secondApproverName': secondApproverName,
      if (bloodComponent != null) 'bloodComponent': bloodComponent,
      if (requestingOfficerName != null) 'requestingOfficerName': requestingOfficerName,
      if (contactExtension != null) 'contactExtension': contactExtension,
      if (crossmatchStatus != null) 'crossmatchStatus': crossmatchStatus,
      if (clinicalNotes != null) 'clinicalNotes': clinicalNotes,
      if (assignedDoctorId != null) 'assignedDoctorId': assignedDoctorId,
      if (assignedDoctorName != null) 'assignedDoctorName': assignedDoctorName,
      if (assignedAt != null) 'assignedAt': Timestamp.fromDate(assignedAt!),
      'escalationLevel': escalationLevel.value,
      if (escalatedAt != null) 'escalatedAt': Timestamp.fromDate(escalatedAt!),
      if (escalationNote != null) 'escalationNote': escalationNote,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  BloodRequest copyWith({
    String? id,
    String? patientName,
    String? bloodGroup,
    int? unitsNeeded,
    String? urgency,
    String? hospitalName,
    String? location,
    String? notes,
    String? createdBy,
    String? createdByName,
    String? status,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unitsConfirmed,
    int? donorsNotifiedCount,
    int? donorsAcceptedCount,
    List<String>? pinnedBy,
    String? firstApproverId,
    String? firstApproverName,
    DateTime? firstApprovedAt,
    String? secondApproverId,
    String? secondApproverName,
    String? patientReference,
    String? ward,
    DateTime? requiredAt,
    String? bloodComponent,
    String? requestingOfficerName,
    String? contactExtension,
    String? crossmatchStatus,
    String? hospitalId,
    String? clinicalNotes,
    String? assignedDoctorId,
    String? assignedDoctorName,
    DateTime? assignedAt,
    EscalationLevel? escalationLevel,
    DateTime? escalatedAt,
    String? escalationNote,
    String? requestType,
    String? requestingFor,
    int? patientAge,
    String? relationship,
    String? patientId,
    String? reason,
    DateTime? requiredBefore,
    String? hospitalLocation,
    String? wardUnit,
    String? doctorClinic,
    String? bloodNeededBy,
    String? contactNumber,
    String? preferredUpdateMethod,
    int? verifiedDonorsCount,
  }) {
    return BloodRequest(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsNeeded: unitsNeeded ?? this.unitsNeeded,
      urgency: urgency ?? this.urgency,
      hospitalName: hospitalName ?? this.hospitalName,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unitsConfirmed: unitsConfirmed ?? this.unitsConfirmed,
      donorsNotifiedCount: donorsNotifiedCount ?? this.donorsNotifiedCount,
      donorsAcceptedCount: donorsAcceptedCount ?? this.donorsAcceptedCount,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      firstApproverId: firstApproverId ?? this.firstApproverId,
      firstApproverName: firstApproverName ?? this.firstApproverName,
      firstApprovedAt: firstApprovedAt ?? this.firstApprovedAt,
      secondApproverId: secondApproverId ?? this.secondApproverId,
      secondApproverName: secondApproverName ?? this.secondApproverName,
      patientReference: patientReference ?? this.patientReference,
      ward: ward ?? this.ward,
      requiredAt: requiredAt ?? this.requiredAt,
      bloodComponent: bloodComponent ?? this.bloodComponent,
      requestingOfficerName: requestingOfficerName ?? this.requestingOfficerName,
      contactExtension: contactExtension ?? this.contactExtension,
      crossmatchStatus: crossmatchStatus ?? this.crossmatchStatus,
      hospitalId: hospitalId ?? this.hospitalId,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      assignedDoctorName: assignedDoctorName ?? this.assignedDoctorName,
      assignedAt: assignedAt ?? this.assignedAt,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      escalationNote: escalationNote ?? this.escalationNote,
      requestType: requestType ?? this.requestType,
      requestingFor: requestingFor ?? this.requestingFor,
      patientAge: patientAge ?? this.patientAge,
      relationship: relationship ?? this.relationship,
      patientId: patientId ?? this.patientId,
      reason: reason ?? this.reason,
      requiredBefore: requiredBefore ?? this.requiredBefore,
      hospitalLocation: hospitalLocation ?? this.hospitalLocation,
      wardUnit: wardUnit ?? this.wardUnit,
      doctorClinic: doctorClinic ?? this.doctorClinic,
      bloodNeededBy: bloodNeededBy ?? this.bloodNeededBy,
      contactNumber: contactNumber ?? this.contactNumber,
      preferredUpdateMethod: preferredUpdateMethod ?? this.preferredUpdateMethod,
      verifiedDonorsCount: verifiedDonorsCount ?? this.verifiedDonorsCount,
    );
  }

  /// Returns a trimmed string, or null for absent, non-string or
  /// whitespace-only values - so the UI's "Not recorded" state is driven
  /// by a single consistent rule instead of per-widget empty checks.
  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Accepts a Firestore [Timestamp] or a plain [DateTime]; anything else
  /// (including a server timestamp that has not resolved yet) is null.
  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Crossmatch (compatibility testing) status vocabulary.
///
/// LifeLink does not perform or interpret crossmatching - the hospital
/// laboratory does. These values only mirror what the lab recorded, and
/// the request details screen states that explicitly.
class CrossmatchStatus {
  const CrossmatchStatus._();

  static const notRequested = 'not_requested';
  static const pending = 'pending';
  static const compatible = 'compatible';
  static const incompatible = 'incompatible';

  static const List<String> all = [notRequested, pending, compatible, incompatible];

  static String label(String? raw) => switch (raw) {
    notRequested => 'Not requested',
    pending => 'Crossmatch pending',
    compatible => 'Crossmatch compatible',
    incompatible => 'Crossmatch incompatible',
    null => 'Not recorded',
    _ => raw,
  };

  /// True only for a value that should draw attention. An unrecorded
  /// crossmatch is a gap, not an alarm.
  static bool isBlocking(String? raw) => raw == incompatible;
}

/// Represents a single donor's response record inside a request's
/// `responses` subcollection (FR10 - donor response tracking).
class DonorResponseRecord {
  final String id;
  final String donorId;
  final String donorName;
  final String donorPhone;
  final String bloodGroup;
  final String status; // notified, accepted, declined, completed
  final String notifiedBy;
  final DateTime? notifiedAt;
  final DateTime? respondedAt;
  final int unitsPledged;

  const DonorResponseRecord({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.donorPhone,
    required this.bloodGroup,
    required this.status,
    required this.notifiedBy,
    this.notifiedAt,
    this.respondedAt,
    this.unitsPledged = 1,
  });

  factory DonorResponseRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return DonorResponseRecord(
      id: doc.id,
      donorId: data['donorId'] as String? ?? '',
      donorName: data['donorName'] as String? ?? 'Donor',
      donorPhone: data['donorPhone'] as String? ?? '',
      bloodGroup: data['bloodGroup'] as String? ?? '-',
      status: data['status'] as String? ?? 'notified',
      notifiedBy: data['notifiedBy'] as String? ?? '',
      notifiedAt: (data['notifiedAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      unitsPledged: (data['unitsPledged'] as num?)?.toInt() ?? 1,
    );
  }
}
