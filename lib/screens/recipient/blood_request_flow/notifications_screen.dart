import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_status_screen.dart';

/// Tracking screen - Shows recipient's requests with status tracking
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC62828);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Column(
        children: [
          // Custom header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFC62828)),
            child: const Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Tracking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Request list with tracking
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('createdBy', isEqualTo: user?.uid)
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
                          Icons.track_changes_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No active requests to track',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a blood request to start tracking',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allRequests = snapshot.data!.docs;

                // Filter by status client-side
                final validStatuses = [
                  'pending',
                  'verified',
                  'matched',
                  'completed',
                ];
                final requests = allRequests.where((doc) {
                  final status = doc.data()['status'] as String? ?? '';
                  return validStatuses.contains(status.toLowerCase());
                }).toList();

                // Sort client-side by createdAt descending
                requests.sort((a, b) {
                  final aTime = a.data()['createdAt'] as Timestamp?;
                  final bTime = b.data()['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.toDate().compareTo(aTime.toDate());
                });

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
                    final unitsConfirmed = data['unitsConfirmed'] as int? ?? 0;
                    final hospitalName =
                        data['hospitalName'] as String? ?? 'Unknown';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final isEmergency = data['requestType'] == 'emergency';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      bloodGroup,
                                      style: const TextStyle(
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
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        if (createdAt != null)
                                          Text(
                                            'Created: ${_formatDate(createdAt.toDate())}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isEmergency)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.emergency_rounded,
                                            size: 12,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Emergency',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Progress indicator
                              _buildProgressTracker(
                                status,
                                unitsNeeded,
                                unitsConfirmed,
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

  Widget _buildProgressTracker(
    String status,
    int unitsNeeded,
    int unitsConfirmed,
  ) {
    final stages = ['Pending', 'Verified', 'Matched', 'Completed'];
    final currentStageIndex = stages.indexWhere(
      (s) => s.toLowerCase() == status.toLowerCase(),
    );

    return Column(
      children: [
        // Progress bar
        Row(
          children: List.generate(stages.length, (index) {
            final isCompleted = index < currentStageIndex;
            final isCurrent = index == currentStageIndex;

            return Expanded(
              child: Row(
                children: [
                  // Stage dot
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                          ? const Color(0xFFC62828)
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : isCurrent
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Stage label
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Stage labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final isCompleted = index < currentStageIndex;
            final isCurrent = index == currentStageIndex;

            return Expanded(
              child: Text(
                stages[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted || isCurrent
                      ? const Color(0xFF1F2937)
                      : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Units progress
        if (unitsNeeded > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Blood Units',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '$unitsConfirmed / $unitsNeeded',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: unitsNeeded > 0 ? unitsConfirmed / unitsNeeded : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFC62828),
                ),
                minHeight: 6,
              ),
            ],
          ),
      ],
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
