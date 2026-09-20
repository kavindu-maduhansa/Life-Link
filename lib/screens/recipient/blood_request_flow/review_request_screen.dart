import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/blood_request.dart';
import 'request_submitted_screen.dart';

/// Review request screen (HF 07)
class ReviewRequestScreen extends StatelessWidget {
  final bool isEmergency;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientMobileNumber;
  final String bloodGroup;
  final String bloodComponent;
  final int unitsNeeded;
  final String reason;
  final DateTime requiredBefore;
  final String hospitalId;
  final String hospitalName;
  final String hospitalLocation;
  final String urgency;
  final String bloodNeededBy;
  final String contactNumber;
  final String preferredUpdateMethod;

  const ReviewRequestScreen({
    super.key,
    required this.isEmergency,
    required this.requestingFor,
    required this.patientName,
    required this.patientAge,
    required this.relationship,
    required this.patientMobileNumber,
    required this.bloodGroup,
    required this.bloodComponent,
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
  });

  Future<void> _submitRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final bloodRequest = BloodRequest(
        createdBy: user.uid,
        requestType: isEmergency ? 'emergency' : 'non-emergency',
        requestingFor: requestingFor.toLowerCase(),
        patientName: patientName,
        patientAge: patientAge,
        relationship: relationship,
        patientMobileNumber: patientMobileNumber,
        bloodGroup: bloodGroup,
        bloodComponent: bloodComponent,
        unitsNeeded: unitsNeeded,
        reason: reason,
        requiredBefore: requiredBefore,
        hospitalId: hospitalId,
        hospitalName: hospitalName,
        hospitalLocation: hospitalLocation,
        urgency: urgency,
        bloodNeededBy: bloodNeededBy,
        contactNumber: contactNumber,
        preferredUpdateMethod: preferredUpdateMethod.toLowerCase(),
        status: 'pending',
        verifiedDonorsCount: 0,
        createdAt: DateTime.now(),
      );

      final docRef = await FirebaseFirestore.instance
          .collection('requests')
          .add(bloodRequest.toFirestore());

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RequestSubmittedScreen(
              requestId: docRef.id,
              isEmergency: isEmergency,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Request'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEmergency
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isEmergency
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEmergency
                        ? Icons.emergency_rounded
                        : Icons.calendar_today_rounded,
                    size: 16,
                    color: isEmergency ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEmergency ? 'Emergency Request' : 'Non-Emergency Request',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEmergency ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Patient Details Section
            _buildSectionHeader('Patient Details'),
            _buildDetailRow('Requesting For', requestingFor),
            _buildDetailRow('Patient Name', patientName),
            _buildDetailRow('Age', '$patientAge years'),
            if (requestingFor == 'Other') _buildDetailRow('Relationship', relationship),
            _buildDetailRow('Mobile Number', patientMobileNumber),
            const SizedBox(height: 16),

            // Blood Details Section
            _buildSectionHeader('Blood Details'),
            _buildDetailRow('Blood Group', bloodGroup),
            _buildDetailRow('Component', bloodComponent),
            _buildDetailRow('Units Needed', '$unitsNeeded'),
            _buildDetailRow('Reason', reason),
            _buildDetailRow('Required Before',
                '${requiredBefore.day}/${requiredBefore.month}/${requiredBefore.year}'),
            const SizedBox(height: 16),

            // Hospital Details Section
            _buildSectionHeader('Hospital Details'),
            _buildDetailRow('Hospital', hospitalName),
            _buildDetailRow('Location', hospitalLocation),
            const SizedBox(height: 16),

            // Urgency & Contact Section
            _buildSectionHeader('Urgency & Contact'),
            _buildDetailRow('Urgency', urgency),
            _buildDetailRow('Blood Needed By', bloodNeededBy),
            _buildDetailRow('Contact Number', contactNumber),
            _buildDetailRow('Update Method', preferredUpdateMethod),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitRequest(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Edit Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: primaryColor),
                ),
                child: const Text(
                  'Edit Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
