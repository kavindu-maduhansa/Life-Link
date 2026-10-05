import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';

/// Notifications screen (HF 11)
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                      Icons.notifications_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Alerts',
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
          // Notifications list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('alerts')
                  .where('recipientId', isEqualTo: user?.uid)
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
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You will see updates here',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final data = notification.data();
                    final title = data['title'] as String? ?? 'Notification';
                    final message = data['message'] as String? ?? '';
                    final type = data['type'] as String? ?? 'info';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final isRead = data['isRead'] as bool? ?? false;

                    return NeumorphicCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(
                                type,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getNotificationIcon(type),
                              color: _getNotificationColor(type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(createdAt.toDate()),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'emergency':
        return Icons.emergency_rounded;
      case 'donor_matched':
        return Icons.person_rounded;
      case 'doctor_verified':
        return Icons.verified_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
