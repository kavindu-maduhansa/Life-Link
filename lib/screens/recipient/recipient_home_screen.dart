import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'blood_request_flow/patient_details_screen.dart';
import 'blood_request_flow/notifications_screen.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import '../../widgets/lifelink/ll_brand.dart';
import '../../widgets/neumorphic/neumorphic_widgets.dart';

/// Recipient Dashboard for managing emergency blood requests.
///
/// Designed as part of the LifeLink HCI high-fidelity prototype (FR01/FR06).
/// Restyled with tactile Neumorphic Soft UI components, dual-shadow raised cards,
/// and clear emergency actions while maintaining 100% functional integrity and
/// Firebase persistence.
class RecipientHomeScreen extends StatelessWidget {
  const RecipientHomeScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      }
    }
  }

  void _handleCreateRequestTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientDetailsScreen(isEmergency: true)));
  }

  /// Standardised status presentation for recipient request lifecycle.
  static Widget buildStatusBadge(BuildContext context, String? rawStatus, {bool dense = false}) {
    final status = rawStatus?.trim().toLowerCase() ?? '';
    switch (status) {
      case 'pending':
      case 'pending verification':
        return NeumorphicStatusBadge(
          label: 'Pending Verification',
          icon: Icons.hourglass_top_rounded,
          tone: LLTone.warning,
          dense: dense,
          tooltip: 'Hospital medical staff is reviewing and validating this request.',
        );
      case 'verified':
      case 'approved':
        return NeumorphicStatusBadge(
          label: 'Verified',
          icon: Icons.verified_rounded,
          tone: LLTone.operational,
          dense: dense,
          tooltip: 'Request has been verified by hospital staff and is active for donor matching.',
        );
      case 'matched':
        return NeumorphicStatusBadge(
          label: 'Matched',
          icon: Icons.people_outline_rounded,
          tone: LLTone.brand,
          dense: dense,
          tooltip: 'Compatible donors have responded or been notified.',
        );
      case 'completed':
      case 'fulfilled':
        return NeumorphicStatusBadge(
          label: 'Completed',
          icon: Icons.task_alt_rounded,
          tone: LLTone.success,
          dense: dense,
          tooltip: 'Required blood units have been collected and confirmed.',
        );
      case 'rejected':
      case 'cancelled':
      case 'canceled':
        return NeumorphicStatusBadge(
          label: 'Rejected',
          icon: Icons.cancel_outlined,
          tone: LLTone.critical,
          dense: dense,
          tooltip: 'Request was rejected or cancelled.',
        );
      default:
        return NeumorphicStatusBadge(
          label: rawStatus?.isNotEmpty == true ? rawStatus! : 'Unknown',
          icon: Icons.info_outline_rounded,
          tone: LLTone.neutral,
          dense: dense,
        );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = FirebaseAuth.instance.currentUser;

    // Safe, non-exposing display name resolution
    final displayName = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : (user?.email != null && user!.email!.contains('@') ? user.email!.split('@').first : 'Recipient');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        titleSpacing: LLSpacing.md,
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LLBrandMark(),
            const SizedBox(width: LLSpacing.sm),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipient Dashboard',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  Text(
                    'Recipient Home',
                    maxLines: 1,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.border),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            color: colors.textSecondary,
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Welcome & Role Header
                  NeumorphicCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        NeumorphicSurface(
                          width: 52,
                          height: 52,
                          borderRadius: BorderRadius.circular(26),
                          elevation: NeumorphicElevationLevel.low,
                          color: colors.critical.withValues(alpha: 0.12),
                          borderColor: colors.critical.withValues(alpha: 0.25),
                          child: Icon(Icons.volunteer_activism_rounded, size: 28, color: colors.critical),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${_getGreeting()}, $displayName',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(LLRadius.pill),
                                      border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'Recipient Area',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage and track your emergency blood requests.',
                                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Primary Emergency Request Action Banner
                  NeumorphicSurface(
                    padding: const EdgeInsets.all(22),
                    elevation: NeumorphicElevationLevel.raised,
                    borderRadius: BorderRadius.circular(LLRadius.card),
                    borderColor: colors.critical.withValues(alpha: 0.4),
                    borderWidth: 1.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.critical.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.critical.withValues(alpha: 0.3)),
                              ),
                              child: Icon(Icons.emergency_rounded, color: colors.critical, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Need Blood Urgently?',
                                style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Submit a verified blood request directly to hospital coordinators and compatible blood donors.',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        NeumorphicButton(
                          onPressed: () => _handleCreateRequestTap(context),
                          isCritical: true,
                          height: 48,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Create Emergency Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Status Lifecycle Presentation Guide
                  NeumorphicCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timeline_rounded, size: 18, color: colors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Request Status Guide',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How your emergency request moves through verification and donor matching:',
                          style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            RecipientHomeScreen.buildStatusBadge(context, 'pending'),
                            RecipientHomeScreen.buildStatusBadge(context, 'verified'),
                            RecipientHomeScreen.buildStatusBadge(context, 'matched'),
                            RecipientHomeScreen.buildStatusBadge(context, 'completed'),
                            RecipientHomeScreen.buildStatusBadge(context, 'rejected'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. "My Requests" Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Requests',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.elevatedSurface,
                          borderRadius: BorderRadius.circular(LLRadius.pill),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          '0 Requests',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 5. "My Requests" Empty State
                  NeumorphicCard(
                    padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeumorphicSurface(
                            width: 64,
                            height: 64,
                            borderRadius: BorderRadius.circular(32),
                            elevation: NeumorphicElevationLevel.low,
                            color: colors.primary.withValues(alpha: 0.08),
                            borderColor: colors.primary.withValues(alpha: 0.2),
                            child: Icon(Icons.assignment_outlined, size: 32, color: colors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No emergency requests yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a request when you need urgent blood support.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.5, color: colors.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          NeumorphicButton(
                            onPressed: () => _handleCreateRequestTap(context),
                            isPrimary: false,
                            height: 44,
                            label: 'Start Request',
                            icon: Icons.add_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 6. Clinical Disclaimer / Notice
                  NeumorphicCard(
                    padding: const EdgeInsets.all(14),
                    elevation: NeumorphicElevationLevel.low,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Requests submitted through LifeLink are verified by hospital staff before notification to eligible donors. For immediate life-threatening emergencies, please notify the on-duty hospital emergency department immediately.',
                            style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
