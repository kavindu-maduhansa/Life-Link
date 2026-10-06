import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_requests_screen.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/lifelink_design.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';

/// Request submitted confirmation screen (HF 08)
class RequestSubmittedScreen extends StatefulWidget {
  final String requestId;
  final bool isEmergency;

  const RequestSubmittedScreen({
    super.key,
    required this.requestId,
    required this.isEmergency,
  });

  @override
  State<RequestSubmittedScreen> createState() => _RequestSubmittedScreenState();
}

class _RequestSubmittedScreenState extends State<RequestSubmittedScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'Request Submitted',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Request not found',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
            );
          }

          final data = snapshot.data!.data();
          final verifiedDonorsCount = data?['verifiedDonorsCount'] as int? ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Success Icon with dual soft shadows
                NeumorphicSurface(
                  borderRadius: BorderRadius.circular(50),
                  elevation: NeumorphicElevationLevel.raised,
                  padding: const EdgeInsets.all(24),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: colors.success,
                  ),
                ),
                const SizedBox(height: 24),

                // Success Message
                Text(
                  'Request Submitted Successfully!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isEmergency
                      ? 'Your emergency blood request has been submitted and is being processed.'
                      : 'Your blood request has been submitted successfully.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Status Cards
                _buildStatusCard(
                  context: context,
                  icon: Icons.people_rounded,
                  title: '$verifiedDonorsCount Compatible Donors Verified',
                  description:
                      'Donors matching your blood group have been identified',
                  color: colors.accent,
                ),
                const SizedBox(height: 14),

                _buildStatusCard(
                  context: context,
                  icon: Icons.send_rounded,
                  title: 'Request Submitted',
                  description: 'Your request has been sent to the coordinator',
                  color: colors.success,
                ),
                const SizedBox(height: 14),

                _buildStatusCard(
                  context: context,
                  icon: Icons.notifications_active_rounded,
                  title: 'Donors Automatically Notified',
                  description: 'Matching donors will receive notifications',
                  color: colors.warning,
                ),
                const SizedBox(height: 14),

                _buildStatusCard(
                  context: context,
                  icon: Icons.medical_services_rounded,
                  title: 'Awaiting Doctor Verification',
                  description: 'A doctor will verify the request details',
                  color: colors.primary,
                ),
                const SizedBox(height: 32),

                // View Requests Button
                SizedBox(
                  width: double.infinity,
                  child: NeumorphicButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyRequestsScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    isPrimary: true,
                    height: 52,
                    child: const Text(
                      'View My Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Home Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LLRadius.control),
                      ),
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
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

  Widget _buildStatusCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final colors = context.colors;
    return NeumorphicCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
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
}
