import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';
import 'request_status_screen.dart';

/// My Requests list screen (HF 09)
class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColor = colors.accent;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Neumorphic custom header
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: colors.darkShadow.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.list_alt_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'My Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Request list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('createdBy', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No requests yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first blood request',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final requests = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data();
                    final status = data['status'] as String? ?? 'pending';
                    final bloodGroup =
                        data['bloodGroup'] as String? ?? 'Unknown';
                    final unitsNeeded = data['unitsNeeded'] as int? ?? 0;
                    final hospitalName =
                        data['hospitalName'] as String? ?? 'Unknown';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final isEmergency = data['requestType'] == 'emergency';

                    return NeumorphicCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RequestStatusScreen(requestId: request.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isEmergency
                                          ? colors.critical.withValues(
                                              alpha: 0.12,
                                            )
                                          : colors.accent.withValues(
                                              alpha: 0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isEmergency
                                            ? colors.critical.withValues(
                                                alpha: 0.3,
                                              )
                                            : colors.accent.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isEmergency
                                              ? Icons.emergency_rounded
                                              : Icons.calendar_today_rounded,
                                          size: 14,
                                          color: isEmergency
                                              ? colors.critical
                                              : colors.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isEmergency
                                              ? 'Emergency'
                                              : 'Non-Emergency',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isEmergency
                                                ? colors.critical
                                                : colors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildStatusChip(status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      bloodGroup,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hospitalName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$unitsNeeded unit${unitsNeeded > 1 ? 's' : ''} needed',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (createdAt != null)
                                Text(
                                  'Created: ${_formatDate(createdAt.toDate())}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending_rounded;
        break;
      case 'verified':
        color = Colors.blue;
        icon = Icons.verified_rounded;
        break;
      case 'matched':
        color = Colors.purple;
        icon = Icons.people_rounded;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
