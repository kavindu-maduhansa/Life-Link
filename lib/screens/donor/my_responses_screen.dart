import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'emergency_requests_screen.dart';

import '../../theme/app_colors.dart';
import '../../widgets/neumorphic/neumorphic_widgets.dart';

/// Screen displaying all blood donation responses submitted by the currently logged-in donor.
class MyResponsesScreen extends StatefulWidget {
  const MyResponsesScreen({super.key});

  /// Formats date safely from Timestamp, DateTime, String, int, or null.
  static String formatResponseDate(dynamic value) {
    if (value == null) return 'Recently submitted';

    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is int) {
      try {
        date = DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        date = null;
      }
    }

    if (date == null) return 'Recently submitted';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final monthStr = months[date.month - 1];
    final dayStr = date.day.toString().padLeft(2, '0');
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    return '$dayStr $monthStr ${date.year} at $hourStr:$minuteStr';
  }

  /// Converts dynamic timestamp to DateTime for client-side sorting.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Returns visual configuration (label, colors, icon) for a response status.
  /// Takes a [BuildContext] so the badge colours come from the active
  /// theme. It previously returned hard-coded light-mode literals, which
  /// is why this screen had no Dark Mode.
  static StatusBadgeConfig getStatusConfig(
    BuildContext context,
    dynamic rawStatus,
  ) {
    final colors = context.colors;
    final status = rawStatus?.toString().trim().toLowerCase() ?? '';

    switch (status) {
      case 'accepted':
      case 'approved':
        return StatusBadgeConfig(
          label: 'Accepted',
          textColor: colors.success,
          backgroundColor: colors.successContainer,
          borderColor: colors.successContainer,
          icon: Icons.check_circle_outline_rounded,
          description:
              'The hospital coordinator has accepted your donation offer. They will contact you shortly.',
        );
      case 'rejected':
      case 'declined':
        return StatusBadgeConfig(
          label: 'Rejected',
          textColor: colors.critical,
          backgroundColor: colors.criticalContainer,
          borderColor: colors.criticalContainer,
          icon: Icons.cancel_outlined,
          description:
              'This request has already been fulfilled or cannot proceed at this time. Thank you for your willingness to help.',
        );
      case 'withdrawn':
      case 'cancelled':
        return StatusBadgeConfig(
          label: 'Withdrawn',
          textColor: colors.textSecondary,
          backgroundColor: colors.border.withValues(alpha: 0.3),
          borderColor: colors.border,
          icon: Icons.remove_circle_outline_rounded,
          description:
              'You have withdrawn your donation offer for this emergency request.',
        );
      case 'pending':
      default:
        return StatusBadgeConfig(
          label: 'Pending Review',
          textColor: colors.warning,
          backgroundColor: colors.warningContainer,
          borderColor: colors.warningContainer,
          icon: Icons.hourglass_empty_rounded,
          description:
              'Your response has been sent to the hospital and is awaiting review by the medical team.',
        );
    }
  }

  /// Dialog to edit pledged units and donor notes (UPDATE operation).
  static Future<void> showEditResponseDialog(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final colors = context.colors;
    final data = doc.data() ?? {};
    int units = (data['unitsPledged'] as num?)?.toInt() ?? 1;
    final phoneController = TextEditingController(
      text: (data['phoneNumber'] ?? data['donorPhone'] ?? '') as String,
    );
    final noteController = TextEditingController(
      text: (data['note'] ?? data['notes'] ?? '') as String,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Donation Response',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Units Pledged',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 3].map((u) {
                      final selected = units == u;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text('$u Unit${u > 1 ? 's' : ''}'),
                          selected: selected,
                          selectedColor: colors.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setModalState(() => units = u),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Phone',
                      prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Note for Hospital Team (Optional)',
                      hintText: 'e.g. Can arrive by 3:00 PM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await doc.reference.update({
                          'unitsPledged': units,
                          'phoneNumber': phoneController.text.trim(),
                          'donorPhone': phoneController.text.trim(),
                          'note': noteController.text.trim(),
                          'notes': noteController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Response updated successfully.',
                              ),
                              backgroundColor: colors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (_) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Failed to update response.'),
                              backgroundColor: colors.critical,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog to withdraw/delete response (DELETE operation).
  static Future<void> showWithdrawConfirmDialog(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.critical),
            const SizedBox(width: 8),
            const Text(
              'Withdraw Response',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to withdraw your donation response? The hospital team will be notified.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Keep Response',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: colors.critical),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await doc.reference.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Response withdrawn successfully.'),
              backgroundColor: colors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        try {
          await doc.reference.update({
            'status': 'withdrawn',
            'withdrawnAt': FieldValue.serverTimestamp(),
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Response marked as withdrawn.'),
                backgroundColor: colors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to withdraw response.'),
                backgroundColor: colors.critical,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  @override
  State<MyResponsesScreen> createState() => _MyResponsesScreenState();
}

class _MyResponsesScreenState extends State<MyResponsesScreen> {
  int _streamKey = 0;

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  void _retryLoading() {
    setState(() {
      _streamKey++;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getResponsesStream(String uid) {
    try {
      return FirebaseFirestore.instance
          .collectionGroup('responses')
          .where('donorId', isEqualTo: uid)
          .snapshots();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = _currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text(
            'My Responses',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
          ),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 56,
                  color: colors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Please Sign In',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sign in to your donor account to track your submitted blood donation responses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stream = _getResponsesStream(currentUser.uid);

    if (stream == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text(
            'My Responses',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
          ),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Database is not connected.',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'My Responses',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: KeyedSubtree(
        key: ValueKey(_streamKey),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: colors.primary,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading your responses...',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.criticalContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.criticalContainer),
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 46,
                          color: colors.critical,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Unable to load your responses',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We encountered an issue retrieving your response history. Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _retryLoading,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs.toList() ?? [];

            // 3. Sort by respondedAt descending in memory (newest first, nulls at the end)
            // This avoids requiring a Firestore composite index while keeping sorting reliable.
            docs.sort((a, b) {
              final dateA = MyResponsesScreen.parseDateTime(
                a.data()['respondedAt'],
              );
              final dateB = MyResponsesScreen.parseDateTime(
                b.data()['respondedAt'],
              );

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;
              return dateB.compareTo(dateA);
            });

            // 4. Empty State
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 56,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Responses Yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You haven't responded to any emergency blood requests yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmergencyRequestsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.emergency_rounded, size: 18),
                        label: const Text('View Emergency Requests'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 5. Response Cards List View
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final rawBloodGroup =
                    data['bloodGroup'] as String? ??
                    data['requestBloodGroup'] as String?;
                final bloodGroup =
                    (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty)
                    ? rawBloodGroup.trim()
                    : 'Blood Donor';

                final rawHospital =
                    (data['hospitalName'] ?? data['organizationName'])
                        as String?;
                final hospitalName =
                    (rawHospital != null && rawHospital.trim().isNotEmpty)
                    ? rawHospital.trim()
                    : 'Emergency Blood Request';

                final rawRequestId =
                    data['requestId'] as String? ??
                    doc.reference.parent.parent?.id;
                final requestIdDisplay =
                    (rawRequestId != null && rawRequestId.trim().isNotEmpty)
                    ? (rawRequestId.length > 10
                          ? 'Ref: #${rawRequestId.substring(0, 8)}...'
                          : 'Ref: #$rawRequestId')
                    : null;

                final rawStatus = data['status'];
                final statusConfig = MyResponsesScreen.getStatusConfig(
                  context,
                  rawStatus,
                );
                final respondedDateStr = MyResponsesScreen.formatResponseDate(
                  data['respondedAt'],
                );

                return NeumorphicCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Blood Group Badge + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.water_drop_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  bloodGroup,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusConfig.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusConfig.borderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusConfig.icon,
                                  size: 14,
                                  color: statusConfig.textColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusConfig.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusConfig.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Hospital Name
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hospitalName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Response status note
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: statusConfig.textColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statusConfig.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 10),

                      // Footer: Timestamp & Request Reference
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                respondedDateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (requestIdDisplay != null)
                            Text(
                              requestIdDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                MyResponsesScreen.showEditResponseDialog(
                                  context,
                                  doc,
                                ),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text('Edit Details'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                MyResponsesScreen.showWithdrawConfirmDialog(
                                  context,
                                  doc,
                                ),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 15,
                              color: colors.critical,
                            ),
                            label: Text(
                              'Withdraw',
                              style: TextStyle(
                                color: colors.critical,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Visual style configuration for a response status badge.
class StatusBadgeConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final String description;

  const StatusBadgeConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.description,
  });
}

// ---------------------------------------------------------------------------
// MyResponsesTab
// ---------------------------------------------------------------------------
// Scaffold-free version of MyResponsesScreen for use inside the DonorShell
// IndexedStack. All Firebase queries, field reads and sorting logic are
// identical to the Screen version above — only the Scaffold/AppBar are absent.
// ---------------------------------------------------------------------------

class MyResponsesTab extends StatefulWidget {
  const MyResponsesTab({super.key});

  @override
  State<MyResponsesTab> createState() => _MyResponsesTabState();
}

class _MyResponsesTabState extends State<MyResponsesTab> {
  int _streamKey = 0;

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  void _retryLoading() => setState(() => _streamKey++);

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getResponsesStream(String uid) {
    try {
      return FirebaseFirestore.instance
          .collectionGroup('responses')
          .where('donorId', isEqualTo: uid)
          .snapshots();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = _currentUser;

    // Not signed in
    if (currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 56,
                color: colors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Please Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your donor account to track your submitted blood donation responses.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final stream = _getResponsesStream(currentUser.uid);

    if (stream == null) {
      return Center(
        child: Text(
          'Database is not connected.',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey(_streamKey),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: colors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your responses...',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // 2. Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.criticalContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 46,
                        color: colors.critical,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unable to load your responses',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We encountered an issue retrieving your response history. Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _retryLoading,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs.toList() ?? [];

          // 3. Sort by respondedAt descending (newest first, nulls last)
          docs.sort((a, b) {
            final dateA = MyResponsesScreen.parseDateTime(
              a.data()['respondedAt'],
            );
            final dateB = MyResponsesScreen.parseDateTime(
              b.data()['respondedAt'],
            );
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          // 4. Empty state
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        size: 56,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Responses Yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You haven't responded to any emergency blood requests yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EmergencyRequestsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emergency_rounded, size: 18),
                      label: const Text('View Emergency Requests'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 5. Response card list
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final rawBloodGroup =
                  data['bloodGroup'] as String? ??
                  data['requestBloodGroup'] as String?;
              final bloodGroup =
                  (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty)
                  ? rawBloodGroup.trim()
                  : 'Blood Donor';

              final rawHospital =
                  (data['hospitalName'] ?? data['organizationName']) as String?;
              final hospitalName =
                  (rawHospital != null && rawHospital.trim().isNotEmpty)
                  ? rawHospital.trim()
                  : 'Emergency Blood Request';

              final rawRequestId =
                  data['requestId'] as String? ??
                  doc.reference.parent.parent?.id;
              final requestIdDisplay =
                  (rawRequestId != null && rawRequestId.trim().isNotEmpty)
                  ? (rawRequestId.length > 10
                        ? 'Ref: #${rawRequestId.substring(0, 8)}...'
                        : 'Ref: #$rawRequestId')
                  : null;

              final rawStatus = data['status'];
              final statusConfig = MyResponsesScreen.getStatusConfig(
                context,
                rawStatus,
              );
              final respondedDateStr = MyResponsesScreen.formatResponseDate(
                data['respondedAt'],
              );

              return NeumorphicCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Blood Group Badge + Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bloodGroup,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusConfig.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusConfig.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusConfig.icon,
                                size: 14,
                                color: statusConfig.textColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusConfig.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusConfig.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Hospital Name
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hospitalName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status description note
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: statusConfig.textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusConfig.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: 10),
                    // Footer: Timestamp & Request Reference
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              respondedDateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (requestIdDisplay != null)
                          Text(
                            requestIdDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              MyResponsesScreen.showEditResponseDialog(
                                context,
                                doc,
                              ),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Edit Details'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () =>
                              MyResponsesScreen.showWithdrawConfirmDialog(
                                context,
                                doc,
                              ),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: colors.critical,
                          ),
                          label: Text(
                            'Withdraw',
                            style: TextStyle(
                              color: colors.critical,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
