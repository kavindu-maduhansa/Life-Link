import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'blood_request_details_screen.dart';

import '../../theme/app_colors.dart';
import '../../utils/request_status.dart';

/// Screen displaying active emergency blood requests for donors in real time.
class EmergencyRequestsScreen extends StatefulWidget {
  const EmergencyRequestsScreen({super.key});

  /// Formats date string from Timestamp, DateTime, String, int, or null safely.
  static String formatRequestDate(dynamic value) {
    if (value == null) return 'Date not specified';

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

    if (date == null) return 'Date not specified';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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

  /// Checks whether a request status represents an active request for donors.
  /// Supports: verified, matched, active, open.
  /// Excludes: pending (awaiting hospital verification), completed, cancelled,
  /// canceled, closed, fulfilled, rejected, expired.
  static bool isActiveStatus(dynamic rawStatus) {
    if (rawStatus == null) return false;
    final status = rawStatus.toString().trim().toLowerCase();
    if (status.isEmpty) return false;

    const inactiveStatuses = {
      'pending',
      'completed',
      'cancelled',
      'canceled',
      'closed',
      'fulfilled',
      'rejected',
      'expired',
    };
    if (inactiveStatuses.contains(status)) {
      return false;
    }

    const activeStatuses = {'verified', 'matched', 'active', 'open', 'approved'};
    if (activeStatuses.contains(status)) return true;
    if (status.startsWith('verified') ||
        status.startsWith('matched') ||
        status.startsWith('active') ||
        status.startsWith('approved')) {
      return true;
    }
    return false;
  }

  /// Returns visual configuration (label, foreground, background, icon) for an urgency level.
  /// Takes a [BuildContext] so the badge colours come from the active
  /// theme. It previously returned hard-coded light-mode literals, which
  /// is why this screen had no Dark Mode.
  static UrgencyBadgeConfig getUrgencyConfig(BuildContext context, dynamic rawUrgency) {
    final colors = context.colors;
    final urgency = rawUrgency?.toString().trim().toLowerCase() ?? '';

    switch (urgency) {
      case 'critical':
        return UrgencyBadgeConfig(
          label: 'Critical',
          textColor: colors.critical,
          backgroundColor: colors.criticalContainer,
          borderColor: colors.criticalContainer,
          icon: Icons.warning_amber_rounded,
        );
      case 'high':
        return UrgencyBadgeConfig(
          label: 'High Urgency',
          textColor: const Color(0xFFE65100),
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: const Color(0xFFFFE0B2),
          icon: Icons.priority_high_rounded,
        );
      case 'medium':
        return UrgencyBadgeConfig(
          label: 'Medium Urgency',
          textColor: colors.warning,
          backgroundColor: const Color(0xFFFFFDE7),
          borderColor: const Color(0xFFFFF9C4),
          icon: Icons.schedule_rounded,
        );
      case 'low':
        return UrgencyBadgeConfig(
          label: 'Low Urgency',
          textColor: colors.success,
          backgroundColor: colors.successContainer,
          borderColor: colors.successContainer,
          icon: Icons.check_circle_outline_rounded,
        );
      case 'normal':
        return UrgencyBadgeConfig(
          label: 'Normal Urgency',
          textColor: colors.textPrimary,
          backgroundColor: colors.primary.withValues(alpha: 0.08),
          borderColor: colors.primary.withValues(alpha: 0.2),
          icon: Icons.info_outline_rounded,
        );
      default:
        final displayLabel = rawUrgency != null && rawUrgency.toString().trim().isNotEmpty
            ? rawUrgency.toString().trim()
            : 'Standard';
        return UrgencyBadgeConfig(
          label: displayLabel,
          textColor: colors.textSecondary,
          backgroundColor: colors.elevatedSurface,
          borderColor: colors.border,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  @override
  State<EmergencyRequestsScreen> createState() => _EmergencyRequestsScreenState();
}

class _EmergencyRequestsScreenState extends State<EmergencyRequestsScreen> {
  int _streamKey = 0;
  String? _donorBloodGroup;

  @override
  void initState() {
    super.initState();
    _loadDonorBloodGroup();
  }

  Future<void> _loadDonorBloodGroup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          final bg = doc.data()?['bloodGroup'] as String?;
          if (bg != null && bg.isNotEmpty) {
            setState(() {
              _donorBloodGroup = bg;
            });
          }
        }
      }
    } catch (_) {}
  }

  void _retryLoading() {
    setState(() {
      _streamKey++;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getRequestsStream() {
    try {
      return FirebaseFirestore.instance.collection('requests').snapshots();
    } catch (_) {
      return null;
    }
  }

  void _navigateToDetails(BuildContext context, Map<String, dynamic> data, String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BloodRequestDetailsScreen(requestId: requestId, requestData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stream = _getRequestsStream();

    if (stream == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Emergency Requests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        body: Center(
          child: Text('Database is not connected.', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Emergency Requests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
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
                    CircularProgressIndicator(color: colors.primary, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text(
                      'Loading emergency requests...',
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
                        'Unable to load emergency requests',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We encountered an issue while connecting to the blood requests registry. Please check your internet connection and try again.',
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

            final allDocs = snapshot.data?.docs ?? [];

            // 3. Filter for active/open/pending requests only
            final activeDocs = allDocs.where((doc) {
              final data = doc.data();
              return EmergencyRequestsScreen.isActiveStatus(data['status']);
            }).toList();

            // 4. Sort by createdAt descending (newest first, nulls at the end)
            activeDocs.sort((a, b) {
              final dateA = EmergencyRequestsScreen.parseDateTime(a.data()['createdAt']);
              final dateB = EmergencyRequestsScreen.parseDateTime(b.data()['createdAt']);

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;
              return dateB.compareTo(dateA);
            });

            // 5. Empty State
            if (activeDocs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.volunteer_activism_outlined, size: 56, color: colors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Emergency Requests',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'There are currently no active blood requests. Please check again later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 6. Request List View
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: activeDocs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = activeDocs[index];
                final data = doc.data();
                final requestId = doc.id;

                final rawBloodGroup = data['bloodGroup'] as String?;
                final bloodGroup = (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty)
                    ? rawBloodGroup.trim()
                    : 'Not specified';

                final rawHospital = (data['hospitalName'] ?? data['organizationName']) as String?;
                final hospitalName = (rawHospital != null && rawHospital.trim().isNotEmpty)
                    ? rawHospital.trim()
                    : 'Hospital not specified';

                final rawLocation = data['location'] as String?;
                final location = (rawLocation != null && rawLocation.trim().isNotEmpty)
                    ? rawLocation.trim()
                    : 'Location not specified';

                final urgencyConfig = EmergencyRequestsScreen.getUrgencyConfig(
                  context,
                  data['urgency'] ?? data['urgencyLevel'],
                );

                final rawUnits = data['requiredUnits'] ?? data['unitsNeeded'];
                final unitsString = rawUnits != null
                    ? '$rawUnits ${rawUnits == 1 ? 'Unit' : 'Units'} required'
                    : 'Units: Not specified';

                final rawStatus = data['status'] as String?;
                final isVerified = (rawStatus != null && rawStatus.trim().toLowerCase() == 'verified') ||
                    data['verified'] == true ||
                    (data['verifiedBy'] != null && data['verifiedBy'].toString().trim().isNotEmpty);
                final statusDisplay = (rawStatus != null && rawStatus.trim().isNotEmpty)
                    ? rawStatus.trim()[0].toUpperCase() + rawStatus.trim().substring(1).toLowerCase()
                    : 'Active';

                final compatibleGroups = BloodCompatibility.compatibleDonorGroups(bloodGroup);
                final donorBloodUpper = _donorBloodGroup?.trim().toUpperCase();
                final isCompatible = donorBloodUpper != null &&
                    compatibleGroups.map((g) => g.toUpperCase()).contains(donorBloodUpper);

                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.border),
                  ),
                  color: colors.surface,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _navigateToDetails(context, data, requestId),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Blood Group Badge + Urgency Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
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
                                        const Icon(Icons.water_drop_rounded, size: 16, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          bloodGroup,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCompatible) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colors.successContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 12, color: colors.success),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Compatible',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // Urgency badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: urgencyConfig.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: urgencyConfig.borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(urgencyConfig.icon, size: 14, color: urgencyConfig.textColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      urgencyConfig.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: urgencyConfig.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Hospital Name
                          Row(
                            children: [
                              Icon(Icons.local_hospital_rounded, size: 18, color: colors.primary),
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

                          const SizedBox(height: 6),

                          // Required Units
                          Row(
                            children: [
                              Icon(Icons.medical_services_outlined, size: 16, color: colors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                unitsString,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Divider(height: 1, color: colors.border),
                          const SizedBox(height: 10),

                          // Footer: Status Tag & View Details Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colors.successContainer,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.successContainer),
                                    ),
                                    child: Text(
                                      statusDisplay,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.success),
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_rounded, size: 12, color: colors.primary),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Verified',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: colors.primary),
                                ],
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
}

/// Visual style configuration for urgency levels.
class UrgencyBadgeConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  const UrgencyBadgeConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

// ---------------------------------------------------------------------------
// EmergencyRequestsTab
// ---------------------------------------------------------------------------
// Scaffold-free version of EmergencyRequestsScreen for use inside the
// DonorShell IndexedStack. All Firebase queries, field reads, filtering and
// sorting logic are identical to the Screen version above — only the
// Scaffold and AppBar wrappers are absent.
// ---------------------------------------------------------------------------

class EmergencyRequestsTab extends StatefulWidget {
  const EmergencyRequestsTab({super.key});

  @override
  State<EmergencyRequestsTab> createState() => _EmergencyRequestsTabState();
}

class _EmergencyRequestsTabState extends State<EmergencyRequestsTab> {
  int _streamKey = 0;
  String? _donorBloodGroup;

  @override
  void initState() {
    super.initState();
    _loadDonorBloodGroup();
  }

  Future<void> _loadDonorBloodGroup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          final bg = doc.data()?['bloodGroup'] as String?;
          if (bg != null && bg.isNotEmpty) {
            setState(() {
              _donorBloodGroup = bg;
            });
          }
        }
      }
    } catch (_) {}
  }

  void _retryLoading() => setState(() => _streamKey++);

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getRequestsStream() {
    try {
      return FirebaseFirestore.instance.collection('requests').snapshots();
    } catch (_) {
      return null;
    }
  }

  void _navigateToDetails(BuildContext context, Map<String, dynamic> data, String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BloodRequestDetailsScreen(requestId: requestId, requestData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stream = _getRequestsStream();

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
                  Text(
                    'Loading emergency requests...',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary, fontWeight: FontWeight.w500),
                  ),
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
                      decoration: BoxDecoration(
                        color: colors.criticalContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_outline_rounded, size: 46, color: colors.critical),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unable to load emergency requests',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We encountered an issue connecting to the blood requests registry. Please check your connection and try again.',
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

          final allDocs = snapshot.data?.docs ?? [];

          // 3. Filter active/open/pending only
          final activeDocs = allDocs.where((doc) {
            final data = doc.data();
            return EmergencyRequestsScreen.isActiveStatus(data['status']);
          }).toList();

          // 4. Sort by createdAt descending (newest first)
          activeDocs.sort((a, b) {
            final dateA = EmergencyRequestsScreen.parseDateTime(a.data()['createdAt']);
            final dateB = EmergencyRequestsScreen.parseDateTime(b.data()['createdAt']);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          // 5. Empty state
          if (activeDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.volunteer_activism_outlined, size: 56, color: colors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Emergency Requests',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are currently no active blood requests. Please check again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          // 6. Request list
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            itemCount: activeDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = activeDocs[index];
              final data = doc.data();
              final requestId = doc.id;

              final rawBloodGroup = data['bloodGroup'] as String?;
              final bloodGroup = (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty)
                  ? rawBloodGroup.trim()
                  : 'Not specified';

              final rawHospital = (data['hospitalName'] ?? data['organizationName']) as String?;
              final hospitalName = (rawHospital != null && rawHospital.trim().isNotEmpty)
                  ? rawHospital.trim()
                  : 'Hospital not specified';

              final rawLocation = data['location'] as String?;
              final location = (rawLocation != null && rawLocation.trim().isNotEmpty)
                  ? rawLocation.trim()
                  : 'Location not specified';

              final urgencyConfig = EmergencyRequestsScreen.getUrgencyConfig(
                context,
                data['urgency'] ?? data['urgencyLevel'],
              );

              final rawUnits = data['requiredUnits'] ?? data['unitsNeeded'];
              final unitsString = rawUnits != null
                  ? '$rawUnits ${rawUnits == 1 ? 'Unit' : 'Units'} required'
                  : 'Units: Not specified';

              final rawStatus = data['status'] as String?;
              final isVerified = (rawStatus != null && rawStatus.trim().toLowerCase() == 'verified') ||
                  data['verified'] == true ||
                  (data['verifiedBy'] != null && data['verifiedBy'].toString().trim().isNotEmpty);
              final statusDisplay = (rawStatus != null && rawStatus.trim().isNotEmpty)
                  ? rawStatus.trim()[0].toUpperCase() + rawStatus.trim().substring(1).toLowerCase()
                  : 'Active';

              final compatibleGroups = BloodCompatibility.compatibleDonorGroups(bloodGroup);
              final donorBloodUpper = _donorBloodGroup?.trim().toUpperCase();
              final isCompatible = donorBloodUpper != null &&
                  compatibleGroups.map((g) => g.toUpperCase()).contains(donorBloodUpper);

              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.border),
                ),
                color: colors.surface,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToDetails(context, data, requestId),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Blood Group + Urgency Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                      const Icon(Icons.water_drop_rounded, size: 16, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        bloodGroup,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCompatible) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.successContainer,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 12, color: colors.success),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Compatible',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: urgencyConfig.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: urgencyConfig.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(urgencyConfig.icon, size: 14, color: urgencyConfig.textColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    urgencyConfig.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: urgencyConfig.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Hospital Name
                        Row(
                          children: [
                            Icon(Icons.local_hospital_rounded, size: 18, color: colors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hospitalName,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
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
                        const SizedBox(height: 6),
                        // Required Units
                        Row(
                          children: [
                            Icon(Icons.medical_services_outlined, size: 16, color: colors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              unitsString,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: colors.border),
                        const SizedBox(height: 10),
                        // Footer: Status + View Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colors.successContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusDisplay,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.success),
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 12, color: colors.primary),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Verified',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.chevron_right_rounded, size: 16, color: colors.primary),
                              ],
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
}

