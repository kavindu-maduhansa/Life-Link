import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {
  final String? id;
  final String createdBy;
  final String requestType; // 'emergency' or 'non-emergency'
  final String requestingFor; // 'self' or 'other'
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientId;
  final String bloodGroup;
  final int unitsNeeded;
  final String reason;
  final DateTime requiredBefore;
  final String hospitalId;
  final String hospitalName;
  final String hospitalLocation;
  final String urgency; // e.g., 'within 3 hours'
  final String bloodNeededBy;
  final String contactNumber;
  final String preferredUpdateMethod; // 'sms', 'email', 'app'
  final String
  status; // 'pending', 'verified', 'matched', 'completed', 'cancelled'
  final int verifiedDonorsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BloodRequest({
    this.id,
    required this.createdBy,
    required this.requestType,
    required this.requestingFor,
    required this.patientName,
    required this.patientAge,
    required this.relationship,
    required this.patientId,
    required this.bloodGroup,
    required this.unitsNeeded,
    required this.reason,
    required this.requiredBefore,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalLocation,
    required this.urgency,
    required this.bloodNeededBy,
    required this.contactNumber,
    required this.preferredUpdateMethod,
    this.status = 'pending',
    this.verifiedDonorsCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory BloodRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BloodRequest(
      id: doc.id,
      createdBy: data['createdBy'] as String,
      requestType: data['requestType'] as String,
      requestingFor: data['requestingFor'] as String,
      patientName: data['patientName'] as String,
      patientAge: data['patientAge'] as int,
      relationship: data['relationship'] as String,
      patientId: data['patientId'] as String,
      bloodGroup: data['bloodGroup'] as String,
      unitsNeeded: data['unitsNeeded'] as int,
      reason: data['reason'] as String,
      requiredBefore: (data['requiredBefore'] as Timestamp).toDate(),
      hospitalId: data['hospitalId'] as String,
      hospitalName: data['hospitalName'] as String,
      hospitalLocation: data['hospitalLocation'] as String,
      urgency: data['urgency'] as String,
      bloodNeededBy: data['bloodNeededBy'] as String,
      contactNumber: data['contactNumber'] as String,
      preferredUpdateMethod: data['preferredUpdateMethod'] as String,
      status: data['status'] as String? ?? 'pending',
      verifiedDonorsCount: data['verifiedDonorsCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'requestType': requestType,
      'requestingFor': requestingFor,
      'patientName': patientName,
      'patientAge': patientAge,
      'relationship': relationship,
      'patientId': patientId,
      'bloodGroup': bloodGroup,
      'unitsNeeded': unitsNeeded,
      'reason': reason,
      'requiredBefore': Timestamp.fromDate(requiredBefore),
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'hospitalLocation': hospitalLocation,
      'urgency': urgency,
      'bloodNeededBy': bloodNeededBy,
      'contactNumber': contactNumber,
      'preferredUpdateMethod': preferredUpdateMethod,
      'status': status,
      'verifiedDonorsCount': verifiedDonorsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  BloodRequest copyWith({
    String? id,
    String? createdBy,
    String? requestType,
    String? requestingFor,
    String? patientName,
    int? patientAge,
    String? relationship,
    String? patientId,
    String? bloodGroup,
    int? unitsNeeded,
    String? reason,
    DateTime? requiredBefore,
    String? hospitalId,
    String? hospitalName,
    String? hospitalLocation,
    String? urgency,
    String? bloodNeededBy,
    String? contactNumber,
    String? preferredUpdateMethod,
    String? status,
    int? verifiedDonorsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodRequest(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      requestType: requestType ?? this.requestType,
      requestingFor: requestingFor ?? this.requestingFor,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      relationship: relationship ?? this.relationship,
      patientId: patientId ?? this.patientId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsNeeded: unitsNeeded ?? this.unitsNeeded,
      reason: reason ?? this.reason,
      requiredBefore: requiredBefore ?? this.requiredBefore,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalLocation: hospitalLocation ?? this.hospitalLocation,
      urgency: urgency ?? this.urgency,
      bloodNeededBy: bloodNeededBy ?? this.bloodNeededBy,
      contactNumber: contactNumber ?? this.contactNumber,
      preferredUpdateMethod:
          preferredUpdateMethod ?? this.preferredUpdateMethod,
      status: status ?? this.status,
      verifiedDonorsCount: verifiedDonorsCount ?? this.verifiedDonorsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
