import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/blood_request.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';
import 'request_submitted_screen.dart';

/// Review request screen (HF 07)
class ReviewRequestScreen extends StatelessWidget {
  final bool isEmergency;
  final String requestingFor;
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
  final String wardUnit;
  final String doctorClinic;
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
    required this.patientId,
    required this.bloodGroup,
    required this.unitsNeeded,
    required this.reason,
    required this.requiredBefore,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalLocation,
    required this.wardUnit,
    required this.doctorClinic,
    required this.urgency,
    required this.bloodNeededBy,
    required this.contactNumber,
    required this.preferredUpdateMethod,
  });

  Future<void> _submitRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to submit a request'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final bloodRequest = BloodRequest(
        createdBy: user.uid,
        createdByName: (user.displayName?.trim().isNotEmpty == true)
            ? user.displayName!.trim()
            : (user.email != null && user.email!.contains('@')
                  ? user.email!.split('@').first
                  : 'Recipient'),
        requestType: isEmergency ? 'emergency' : 'non-emergency',
        requestingFor: requestingFor.toLowerCase(),
        patientName: patientName,
        patientAge: patientAge,
        relationship: relationship,
        patientId: patientId,
        patientReference: patientId,
        bloodGroup: bloodGroup,
        unitsNeeded: unitsNeeded,
        reason: reason,
        notes: reason,
        requiredBefore: requiredBefore,
        requiredAt: requiredBefore,
        hospitalId: hospitalId.isNotEmpty ? hospitalId : 'manual-entry',
        hospitalName: hospitalName,
        hospitalLocation: hospitalLocation.isNotEmpty
            ? hospitalLocation
            : 'Not specified',
        location: hospitalLocation.isNotEmpty
            ? hospitalLocation
            : 'Not specified',
        wardUnit: wardUnit,
        ward: wardUnit,
        doctorClinic: doctorClinic,
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

      debugPrint('Request submitted with ID: ${docRef.id}');
      debugPrint('Request createdBy: ${user.uid}');

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
      debugPrint('Error submitting request: $e');
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
    final colors = context.colors;
    final primaryColor = colors.accent;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Review Request',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.border, height: 1),
        ),
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
                    ? colors.critical.withValues(alpha: 0.12)
                    : colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isEmergency
                      ? colors.critical.withValues(alpha: 0.3)
                      : colors.accent.withValues(alpha: 0.3),
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
                    color: isEmergency ? colors.critical : colors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEmergency ? 'Emergency Request' : 'Non-Emergency Request',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEmergency ? colors.critical : colors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient Details Section
            NeumorphicCard(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Patient Details', colors),
                  _buildDetailRow('Requesting For', requestingFor, colors),
                  _buildDetailRow('Patient Name', patientName, colors),
                  _buildDetailRow('Age', '$patientAge years', colors),
                  if (requestingFor == 'Other')
                    _buildDetailRow('Relationship', relationship, colors),
                  _buildDetailRow('Patient ID', patientId, colors),
                ],
              ),
            ),

            // Blood Details Section
            NeumorphicCard(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Blood Details', colors),
                  _buildDetailRow('Blood Group', bloodGroup, colors),
                  _buildDetailRow('Units Needed', '$unitsNeeded', colors),
                  _buildDetailRow('Reason', reason, colors),
                  _buildDetailRow(
                    'Required Before',
                    '${requiredBefore.day}/${requiredBefore.month}/${requiredBefore.year}',
                    colors,
                  ),
                ],
              ),
            ),

            // Hospital Details Section
            NeumorphicCard(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Hospital Details', colors),
                  _buildDetailRow('Hospital', hospitalName, colors),
                  _buildDetailRow('Location', hospitalLocation, colors),
                  _buildDetailRow('Ward / Unit', wardUnit, colors),
                  _buildDetailRow('Doctor / Clinic', doctorClinic, colors),
                ],
              ),
            ),

            // Urgency & Contact Section
            NeumorphicCard(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Urgency & Contact', colors),
                  _buildDetailRow('Urgency', urgency, colors),
                  _buildDetailRow('Blood Needed By', bloodNeededBy, colors),
                  _buildDetailRow('Contact Number', contactNumber, colors),
                  _buildDetailRow(
                    'Update Method',
                    preferredUpdateMethod,
                    colors,
                  ),
                ],
              ),
            ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitRequest(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.6)),
                ),
                child: const Text(
                  'Edit Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
