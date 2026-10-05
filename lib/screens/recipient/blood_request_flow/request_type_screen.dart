import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';
import 'patient_details_screen.dart';

/// Request type confirmation screen (HF 02)
class RequestTypeScreen extends StatelessWidget {
  final bool isEmergency;

  const RequestTypeScreen({super.key, required this.isEmergency});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColor = colors.accent;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Request Type',
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Type Display
            NeumorphicCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isEmergency ? colors.critical : colors.accent)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEmergency
                          ? Icons.emergency_rounded
                          : Icons.calendar_today_rounded,
                      size: 36,
                      color: isEmergency ? colors.critical : colors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEmergency
                              ? 'Emergency Request'
                              : 'Non-Emergency Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEmergency
                              ? 'Urgent blood request for critical situations'
                              : 'Schedule blood request in advance',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Information Cards
            if (isEmergency) ...[
              _buildInfoCard(
                context: context,
                icon: Icons.speed_rounded,
                title: 'Fast Response',
                description:
                    'Your request will be prioritized and sent to available donors immediately.',
              ),
              const SizedBox(height: 14),
              _buildInfoCard(
                context: context,
                icon: Icons.location_on_rounded,
                title: 'Location Based',
                description:
                    'Donors near your location will be notified first.',
              ),
              const SizedBox(height: 14),
              _buildInfoCard(
                context: context,
                icon: Icons.phone_in_talk_rounded,
                title: 'Direct Contact',
                description:
                    'Coordinators will contact you directly for urgent coordination.',
              ),
            ] else ...[
              _buildInfoCard(
                context: context,
                icon: Icons.schedule_rounded,
                title: 'Scheduled Request',
                description:
                    'Plan your blood request in advance for better coordination.',
              ),
              const SizedBox(height: 14),
              _buildInfoCard(
                context: context,
                icon: Icons.people_rounded,
                title: 'Wider Donor Pool',
                description: 'More time allows for finding the best match.',
              ),
              const SizedBox(height: 14),
              _buildInfoCard(
                context: context,
                icon: Icons.verified_rounded,
                title: 'Verified Donors',
                description:
                    'All donors will be pre-verified before notification.',
              ),
            ],
            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PatientDetailsScreen(isEmergency: isEmergency),
                    ),
                  );
                },
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
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = context.colors;
    final primaryColor = colors.accent;

    return NeumorphicCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
