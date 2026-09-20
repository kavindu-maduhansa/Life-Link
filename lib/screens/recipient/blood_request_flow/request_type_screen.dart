import 'package:flutter/material.dart';
import 'patient_details_screen.dart';

/// Request type confirmation screen (HF 02)
class RequestTypeScreen extends StatelessWidget {
  final bool isEmergency;

  const RequestTypeScreen({
    super.key,
    required this.isEmergency,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Type'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Type Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isEmergency
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEmergency
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEmergency
                        ? Icons.emergency_rounded
                        : Icons.calendar_today_rounded,
                    size: 48,
                    color: isEmergency ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEmergency ? 'Emergency Request' : 'Non-Emergency Request',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEmergency
                              ? 'Urgent blood request for critical situations'
                              : 'Schedule blood request in advance',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Information Cards
            if (isEmergency) ...[
              _buildInfoCard(
                icon: Icons.speed_rounded,
                title: 'Fast Response',
                description: 'Your request will be prioritized and sent to available donors immediately.',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.location_on_rounded,
                title: 'Location Based',
                description: 'Donors near your location will be notified first.',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.phone_in_talk_rounded,
                title: 'Direct Contact',
                description: 'Coordinators will contact you directly for urgent coordination.',
              ),
            ] else ...[
              _buildInfoCard(
                icon: Icons.schedule_rounded,
                title: 'Scheduled Request',
                description: 'Plan your blood request in advance for better coordination.',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.people_rounded,
                title: 'Wider Donor Pool',
                description: 'More time allows for finding the best match.',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.verified_rounded,
                title: 'Verified Donors',
                description: 'All donors will be pre-verified before notification.',
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
                      builder: (context) => PatientDetailsScreen(
                        isEmergency: isEmergency,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFC62828),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
