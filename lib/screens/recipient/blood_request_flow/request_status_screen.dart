import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';

/// Request status tracking screen (HF 10)
class RequestStatusScreen extends StatelessWidget {
  final String requestId;

  const RequestStatusScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColor = colors.accent;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Request Status',
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Request not found',
                style: TextStyle(color: colors.textSecondary),
              ),
            );
          }

          final data = snapshot.data!.data();
          final status = data?['status'] as String? ?? 'pending';
          final bloodGroup = data?['bloodGroup'] as String? ?? 'Unknown';
          final unitsNeeded = data?['unitsNeeded'] as int? ?? 0;
          final hospitalName = data?['hospitalName'] as String? ?? 'Unknown';
          final patientName = data?['patientName'] as String? ?? 'Unknown';
          final verifiedDonorsCount = data?['verifiedDonorsCount'] as int? ?? 0;
          final createdAt = data?['createdAt'] as Timestamp?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request Summary Card
                NeumorphicCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              bloodGroup,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hospitalName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$unitsNeeded unit${unitsNeeded > 1 ? 's' : ''} needed',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.people_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$verifiedDonorsCount donors',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status Timeline
                Text(
                  'Request Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTimelineItem(
                  context: context,
                  icon: Icons.send_rounded,
                  title: 'Request Submitted',
                  description: 'Your request has been submitted',
                  isCompleted: true,
                  isCurrent: status == 'pending',
                  primaryColor: primaryColor,
                ),
                _buildTimelineItem(
                  context: context,
                  icon: Icons.people_rounded,
                  title: 'Donor/Internal Teams Accepted',
                  description: '$verifiedDonorsCount donors have responded',
                  isCompleted: [
                    'verified',
                    'matched',
                    'completed',
                  ].contains(status),
                  isCurrent: status == 'verified',
                  primaryColor: primaryColor,
                ),
                _buildTimelineItem(
                  context: context,
                  icon: Icons.medical_services_rounded,
                  title: 'Doctor Verification in Progress',
                  description: 'Doctor is verifying the request',
                  isCompleted: ['matched', 'completed'].contains(status),
                  isCurrent: status == 'matched',
                  primaryColor: primaryColor,
                ),
                _buildTimelineItem(
                  context: context,
                  icon: Icons.check_circle_rounded,
                  title: 'Request Complete',
                  description: 'Blood donation completed',
                  isCompleted: status == 'completed',
                  isCurrent: status == 'completed',
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 24),

                // Request Details
                Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                NeumorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Request ID', requestId),
                      if (createdAt != null)
                        _buildDetailRow(
                          context,
                          'Created',
                          _formatDate(createdAt.toDate()),
                        ),
                      _buildDetailRow(context, 'Status', _formatStatus(status)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Back Button
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
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Text(
                      'Back to My Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required bool isCurrent,
    required Color primaryColor,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? primaryColor
                  : colors.elevatedSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted || isCurrent ? primaryColor : colors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.darkShadow.withValues(alpha: 0.08),
                  offset: const Offset(1, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isCompleted || isCurrent
                  ? Colors.white
                  : colors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isCurrent
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }
}
