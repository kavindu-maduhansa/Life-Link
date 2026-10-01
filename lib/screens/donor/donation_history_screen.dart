import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';

/// Screen displaying the history of blood donations made by the currently logged-in donor.
class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  /// Helper to safely format donation date from Timestamp, DateTime, String, int, or null.
  static String formatDonationDate(dynamic value) {
    if (value == null) return 'Date not available';

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

    if (date == null) return 'Date not available';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final monthStr = months[date.month - 1];
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr $monthStr ${date.year}';
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

  /// Returns visual configuration (label, colors, icon) for a donation status.
  /// Takes a [BuildContext] so the badge colours come from the active
  /// theme. It previously returned hard-coded light-mode literals, which
  /// is why this screen had no Dark Mode.
  static DonationStatusConfig getStatusConfig(BuildContext context, dynamic rawStatus) {
    final colors = context.colors;
    final status = rawStatus?.toString().trim().toLowerCase() ?? '';

    switch (status) {
      case 'completed':
      case 'done':
      case 'success':
        return DonationStatusConfig(
          label: 'Completed',
          textColor: colors.success,
          backgroundColor: colors.successContainer,
          borderColor: colors.successContainer,
          icon: Icons.check_circle_rounded,
        );
      case 'verified':
      case 'approved':
        return DonationStatusConfig(
          label: 'Verified',
          textColor: Color(0xFF0369A1),
          backgroundColor: Color(0xFFE0F2FE),
          borderColor: Color(0xFF7DD3FC),
          icon: Icons.verified_rounded,
        );
      case 'pending':
      case 'processing':
        return DonationStatusConfig(
          label: 'Pending',
          textColor: colors.warning,
          backgroundColor: colors.warningContainer,
          borderColor: colors.warningContainer,
          icon: Icons.schedule_rounded,
        );
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return DonationStatusConfig(
          label: 'Cancelled',
          textColor: colors.critical,
          backgroundColor: colors.criticalContainer,
          borderColor: colors.criticalContainer,
          icon: Icons.cancel_outlined,
        );
      default:
        final displayLabel = rawStatus != null && rawStatus.toString().trim().isNotEmpty
            ? rawStatus.toString().trim()
            : 'Unknown';
        return DonationStatusConfig(
          label: displayLabel,
          textColor: colors.textSecondary,
          backgroundColor: colors.elevatedSurface,
          borderColor: colors.border,
          icon: Icons.help_outline_rounded,
        );
    }
  }

  /// Dialog to manually log a past donation (CREATE operation).
  static Future<void> showAddDonationDialog(BuildContext context, String uid) async {
    final colors = context.colors;
    final centerController = TextEditingController();
    final noteController = TextEditingController();
    String selectedBloodGroup = 'O+';
    int units = 1;
    DateTime selectedDate = DateTime.now();

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Log Blood Donation',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: centerController,
                      decoration: InputDecoration(
                        labelText: 'Hospital or Blood Bank Name *',
                        hintText: 'e.g. National Blood Transfusion Service',
                        prefixIcon: const Icon(Icons.local_hospital_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedBloodGroup,
                            decoration: InputDecoration(
                              labelText: 'Blood Group',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                                .toList(),
                            onChanged: (val) => setModalState(() => selectedBloodGroup = val ?? 'O+'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: units,
                            decoration: InputDecoration(
                              labelText: 'Units Donated',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [1, 2, 3]
                                .map((u) => DropdownMenuItem(value: u, child: Text('$u Unit${u > 1 ? 's' : ''}')))
                                .toList(),
                            onChanged: (val) => setModalState(() => units = val ?? 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.border),
                      ),
                      leading: Icon(Icons.calendar_today_rounded, color: colors.primary, size: 20),
                      title: Text(
                        'Donation Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      ),
                      trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: modalCtx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Remarks / Notes (Optional)',
                        hintText: 'e.g. Voluntary blood drive donation',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () async {
                        final hospitalName = centerController.text.trim();
                        if (hospitalName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please enter the hospital or donation center name.'),
                              backgroundColor: colors.critical,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        try {
                          await FirebaseFirestore.instance.collection('donation_history').add({
                            'donorId': uid,
                            'hospitalName': hospitalName,
                            'bloodGroup': selectedBloodGroup,
                            'unitsDonated': units,
                            'donationDate': Timestamp.fromDate(selectedDate),
                            'status': 'Completed',
                            'clinicalNote': noteController.text.trim(),
                            'isSelfLogged': true,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          await FirebaseFirestore.instance.collection('users').doc(uid).set({
                            'lastDonationDate': Timestamp.fromDate(selectedDate),
                          }, SetOptions(merge: true));

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Donation record added successfully.'),
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
                                content: const Text('Failed to save donation record.'),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Donation Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog to edit donation notes (UPDATE operation).
  static Future<void> showEditDonationDialog(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final colors = context.colors;
    final data = doc.data() ?? {};
    final centerController = TextEditingController(text: (data['hospitalName'] ?? '') as String);
    final noteController = TextEditingController(text: (data['clinicalNote'] ?? data['notes'] ?? '') as String);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Donation Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: centerController,
                decoration: InputDecoration(
                  labelText: 'Hospital or Blood Bank Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Remarks / Notes',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  try {
                    await doc.reference.update({
                      'hospitalName': centerController.text.trim(),
                      'clinicalNote': noteController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Donation record updated.'), backgroundColor: colors.success, behavior: SnackBarBehavior.floating),
                      );
                    }
                  } catch (_) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Failed to update donation record.'), backgroundColor: colors.critical, behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog to delete donation record (DELETE operation).
  static Future<void> showDeleteDonationDialog(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: colors.critical),
            const SizedBox(width: 8),
            const Text('Delete Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to delete this donation record? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Cancel', style: TextStyle(color: colors.textSecondary))),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: colors.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await doc.reference.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Donation record deleted.'), backgroundColor: colors.success, behavior: SnackBarBehavior.floating),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Failed to delete donation record.'), backgroundColor: colors.critical, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
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

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getHistoryStream(String uid) {
    try {
      return FirebaseFirestore.instance.collection('donation_history').where('donorId', isEqualTo: uid).snapshots();
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
          title: const Text('Donation History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
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
                Icon(Icons.account_circle_outlined, size: 56, color: colors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'Please Sign In',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                SizedBox(height: 8),
                Text(
                  'Sign in to your donor account to view your complete blood donation history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stream = _getHistoryStream(currentUser.uid);

    if (stream == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Donation History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Text('Database is not connected.', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Donation History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Log Past Donation',
            onPressed: () => DonationHistoryScreen.showAddDonationDialog(context, currentUser.uid),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DonationHistoryScreen.showAddDonationDialog(context, currentUser.uid),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Donation'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
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
                    CircularProgressIndicator(color: colors.primary, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text(
                      'Loading donation history...',
                      style: TextStyle(fontSize: 14, color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                        child: Icon(Icons.error_outline_rounded, size: 46, color: colors.critical),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Unable to load donation history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We encountered an issue retrieving your donation records. Please check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _retryLoading,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs.toList() ?? [];

            // 3. Sort records by donationDate descending in memory
            // (falls back to createdAt or nulls last to avoid requiring Firestore composite index)
            docs.sort((a, b) {
              final dataA = a.data();
              final dataB = b.data();

              final dateA =
                  DonationHistoryScreen.parseDateTime(dataA['donationDate']) ??
                  DonationHistoryScreen.parseDateTime(dataA['createdAt']);
              final dateB =
                  DonationHistoryScreen.parseDateTime(dataB['donationDate']) ??
                  DonationHistoryScreen.parseDateTime(dataB['createdAt']);

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;
              return dateB.compareTo(dateA);
            });

            // 4. Empty State
            if (docs.isEmpty) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Summary section showing 0 donations
                    _buildSummaryCard(context, totalDonations: 0, lastDonationDate: 'No donations yet'),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: Icon(Icons.history_rounded, size: 56, color: colors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Donation History',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have not completed any blood donations yet. Your completed donations will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              );
            }

            // Calculate summary statistics
            final totalDonations = docs.length;
            final newestRecord = docs.first.data();
            final lastDonationDate = DonationHistoryScreen.formatDonationDate(
              newestRecord['donationDate'] ?? newestRecord['createdAt'],
            );

            // 5. Scrollable Content with Summary Section and Donation Cards
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: docs.length + 1, // +1 for the summary header card
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildSummaryCard(
                      context,
                      totalDonations: totalDonations,
                      lastDonationDate: lastDonationDate,
                    ),
                  );
                }

                final doc = docs[index - 1];
                final data = doc.data();

                final rawBloodGroup = data['bloodGroup'] as String?;
                final bloodGroup = (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty)
                    ? rawBloodGroup.trim()
                    : 'Blood Donation';

                final rawHospital = (data['hospitalName'] ?? data['organizationName']) as String?;
                final hospitalName = (rawHospital != null && rawHospital.trim().isNotEmpty)
                    ? rawHospital.trim()
                    : 'Hospital / Organization not specified';

                final rawLocation = data['location'] as String?;
                final location = (rawLocation != null && rawLocation.trim().isNotEmpty)
                    ? rawLocation.trim()
                    : 'Location not specified';

                final rawStatus = data['status'];
                final statusConfig = DonationHistoryScreen.getStatusConfig(context, rawStatus);

                final donationDateStr = DonationHistoryScreen.formatDonationDate(
                  data['donationDate'] ?? data['createdAt'],
                );

                final rawNotes = data['notes'] as String?;
                final hasNotes = rawNotes != null && rawNotes.trim().isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.border),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Blood Group Badge + Donation Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                    const Icon(Icons.water_drop_rounded, size: 15, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      bloodGroup.endsWith('Blood') || bloodGroup == 'Blood Donation'
                                          ? bloodGroup
                                          : '$bloodGroup Blood',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusConfig.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusConfig.borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusConfig.icon, size: 14, color: statusConfig.textColor),
                                    const SizedBox(width: 4),
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

                          const SizedBox(height: 14),

                          // Donation Date
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 16, color: colors.primary),
                              const SizedBox(width: 8),
                              Text(
                                donationDateStr,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Hospital Name
                          Row(
                            children: [
                              Icon(Icons.local_hospital_outlined, size: 16, color: colors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hospitalName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Location
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: colors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Optional Notes
                          if (hasNotes) ...[
                            const SizedBox(height: 12),
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
                                  Icon(Icons.notes_rounded, size: 14, color: colors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      rawNotes.trim(),
                                      style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Divider(height: 1, color: colors.border),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => DonationHistoryScreen.showEditDonationDialog(context, doc),
                                icon: const Icon(Icons.edit_outlined, size: 14),
                                label: const Text('Edit Note'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => DonationHistoryScreen.showDeleteDonationDialog(context, doc),
                                icon: Icon(Icons.delete_outline_rounded, size: 15, color: colors.critical),
                                label: Text('Delete', style: TextStyle(color: colors.critical, fontSize: 13, fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ],
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
    );
  }

  /// Top summary card displaying donation statistics.
  Widget _buildSummaryCard(BuildContext context, {required int totalDonations, required String lastDonationDate}) {
    final colors = context.colors;
    // Was a solid red gradient block. The shared system reserves
    // saturated red for emergency content and calls for a tinted
    // container with a saturated border instead of a large filled area -
    // and a donation summary is a positive stat, not an emergency.
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Total Donations Box
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.volunteer_activism_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Total Donations',
                      style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalDonations',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  totalDonations == 1 ? 'Life-saving donation' : 'Life-saving donations',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          Container(height: 50, width: 1, color: Colors.white24),
          const SizedBox(width: 16),
          // Last Donation Box
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Most Recent',
                      style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  lastDonationDate,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text('Record Verified', style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual style configuration for a donation status badge.
class DonationStatusConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  const DonationStatusConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

// ---------------------------------------------------------------------------
// DonationHistoryTab
// ---------------------------------------------------------------------------
// Scaffold-free version of DonationHistoryScreen for use inside the
// DonorShell IndexedStack. All Firebase queries, field reads, sorting and
// formatting logic are identical to the Screen version above — only the
// Scaffold and AppBar wrappers are absent. Card color is colors.surface
// (not Colors.white) so Dark Mode works correctly.
// ---------------------------------------------------------------------------

class DonationHistoryTab extends StatefulWidget {
  const DonationHistoryTab({super.key});

  @override
  State<DonationHistoryTab> createState() => _DonationHistoryTabState();
}

class _DonationHistoryTabState extends State<DonationHistoryTab> {
  int _streamKey = 0;

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  void _retryLoading() => setState(() => _streamKey++);

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getHistoryStream(String uid) {
    try {
      return FirebaseFirestore.instance.collection('donation_history').where('donorId', isEqualTo: uid).snapshots();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = _currentUser;

    if (currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle_outlined, size: 56, color: colors.textSecondary),
              const SizedBox(height: 16),
              Text('Please Sign In',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Sign in to your donor account to view your complete blood donation history.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final stream = _getHistoryStream(currentUser.uid);

    if (stream == null) {
      return Center(
        child: Text('Database is not connected.', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
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
                  CircularProgressIndicator(color: colors.primary, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text('Loading donation history...',
                      style: TextStyle(fontSize: 14, color: colors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          // 2. Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: colors.criticalContainer, shape: BoxShape.circle),
                      child: Icon(Icons.error_outline_rounded, size: 46, color: colors.critical),
                    ),
                    const SizedBox(height: 20),
                    Text('Unable to load donation history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      'We encountered an issue retrieving your donation records. Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _retryLoading,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs.toList() ?? [];

          // 3. Sort records by donationDate descending in memory
          docs.sort((a, b) {
            final dataA = a.data();
            final dataB = b.data();
            final dateA =
                DonationHistoryScreen.parseDateTime(dataA['donationDate']) ??
                DonationHistoryScreen.parseDateTime(dataA['createdAt']);
            final dateB =
                DonationHistoryScreen.parseDateTime(dataB['donationDate']) ??
                DonationHistoryScreen.parseDateTime(dataB['createdAt']);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          // 4. Empty state
          if (docs.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildSummaryCard(context, totalDonations: 0, lastDonationDate: 'No donations yet'),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: Icon(Icons.history_rounded, size: 56, color: colors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('No Donation History',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'You have not completed any blood donations yet. Your completed donations will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            );
          }

          // 5. Build list with summary card header
          final totalDonations = docs.length;
          final newestRecord = docs.first.data();
          final lastDonationDate = DonationHistoryScreen.formatDonationDate(
            newestRecord['donationDate'] ?? newestRecord['createdAt'],
          );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(context,
                          totalDonations: totalDonations, lastDonationDate: lastDonationDate),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => DonationHistoryScreen.showAddDonationDialog(context, currentUser.uid),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Log Blood Donation', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final doc = docs[index - 1];
              final data = doc.data();

              final rawBloodGroup = data['bloodGroup'] as String?;
              final bloodGroup = (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty)
                  ? rawBloodGroup.trim()
                  : 'Blood Donation';

              final rawHospital = (data['hospitalName'] ?? data['organizationName']) as String?;
              final hospitalName = (rawHospital != null && rawHospital.trim().isNotEmpty)
                  ? rawHospital.trim()
                  : 'Hospital / Organization not specified';

              final rawLocation = data['location'] as String?;
              final location = (rawLocation != null && rawLocation.trim().isNotEmpty)
                  ? rawLocation.trim()
                  : 'Location not specified';

              final rawStatus = data['status'];
              final statusConfig = DonationHistoryScreen.getStatusConfig(context, rawStatus);
              final donationDateStr = DonationHistoryScreen.formatDonationDate(
                data['donationDate'] ?? data['createdAt'],
              );

              final rawNotes = data['notes'] as String?;
              final hasNotes = rawNotes != null && rawNotes.trim().isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.border),
                  ),
                  color: colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Blood Group + Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                  const Icon(Icons.water_drop_rounded, size: 15, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    bloodGroup.endsWith('Blood') || bloodGroup == 'Blood Donation'
                                        ? bloodGroup
                                        : '$bloodGroup Blood',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusConfig.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusConfig.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusConfig.icon, size: 14, color: statusConfig.textColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusConfig.label,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusConfig.textColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: colors.primary),
                            const SizedBox(width: 8),
                            Text(donationDateStr,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.local_hospital_outlined, size: 16, color: colors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(hospitalName,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: colors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(location,
                                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        if (hasNotes) ...[
                          const SizedBox(height: 12),
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
                                Icon(Icons.notes_rounded, size: 14, color: colors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(rawNotes.trim(),
                                      style:
                                          TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Divider(height: 1, color: colors.border),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => DonationHistoryScreen.showEditDonationDialog(context, doc),
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Edit Note'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => DonationHistoryScreen.showDeleteDonationDialog(context, doc),
                              icon: Icon(Icons.delete_outline_rounded, size: 15, color: colors.critical),
                              label: Text('Delete', style: TextStyle(color: colors.critical, fontSize: 13, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildSummaryCard(BuildContext context,
      {required int totalDonations, required String lastDonationDate}) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.volunteer_activism_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text('Total Donations',
                        style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$totalDonations',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                Text(
                  totalDonations == 1 ? 'Life-saving donation' : 'Life-saving donations',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          Container(height: 50, width: 1, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text('Most Recent',
                        style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(lastDonationDate,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                const Text('Record Verified', style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

