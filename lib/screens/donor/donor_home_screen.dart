import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import '../../widgets/lifelink/ll_brand.dart';
import '../../widgets/lifelink/ll_components.dart';
import '../../widgets/lifelink/ll_states.dart';
import 'donation_history_screen.dart';
import 'donor_profile_screen.dart';
import 'emergency_requests_screen.dart';
import 'my_responses_screen.dart';

/// Blood Donor dashboard.
///
/// MIGRATED to the shared LifeLink design system: it now reads every
/// colour from [AppColors] through `context.colors`, uses the shared
/// [LLCard] / [LLStatusBadge] / [LLSectionHeader] primitives, and gains
/// Dark Mode - which this screen previously had no support for at all,
/// because all 16 of its colours were hard-coded light-mode literals.
///
/// NOTHING about its behaviour changed. The Firestore stream, the
/// `users/{uid}` document read, every field name (`fullName`,
/// `isAvailable`, `bloodGroup`, `location`, `lastDonationDate`), the four
/// navigation destinations, the greeting logic and the date formatting
/// are all exactly as they were.
class DonorHomeScreen extends StatelessWidget {
  const DonorHomeScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DonorProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      // Shared app-bar treatment: brand mark + role label, on the surface
      // tone rather than a full-width red header - the same bar the
      // Doctor module uses.
      appBar: AppBar(
        titleSpacing: LLSpacing.md,
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
                    'Donor Dashboard',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  Text(
                    'Donor',
                    maxLines: 1,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => _navigateToProfile(context),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: const DonorHomeTab(),
    );
  }
}

class DonorHomeTab extends StatelessWidget {
  const DonorHomeTab({super.key});

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _getUserStream(String uid) {
    try {
      return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    } catch (_) {
      return null;
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DonorProfileScreen()));
  }

  void _navigateToEmergencyRequests(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyRequestsScreen()));
  }

  void _navigateToMyResponses(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyResponsesScreen()));
  }

  void _navigateToDonationHistory(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DonationHistoryScreen()));
  }

  /// Extracts user's first name safely from fullName.
  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Donor';
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Donor';
  }

  /// Generates a friendly greeting based on local device time.
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  /// Formats last donation date safely.
  String _formatLastDonationDate(dynamic value) {
    if (value == null) return 'No record';

    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'No record';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final monthStr = months[date.month - 1];
    return '${date.day} $monthStr ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return user == null
        ? _buildDashboardContent(context, null)
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _getUserStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return LLErrorState(error: snapshot.error!, whatFailed: 'your donor profile');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LLLoadingState(message: 'Loading dashboard...');
              }

              final data = snapshot.data?.data();
              return _buildDashboardContent(context, data);
            },
          );
  }

  /// Builds main dashboard scrollable content using user profile data.
  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic>? data) {
    final fullName = data?['fullName'] as String?;
    final firstName = _getFirstName(fullName);
    final isAvailable = (data?['isAvailable'] as bool?) ?? false;

    final rawBloodGroup = data?['bloodGroup'] as String?;
    final bloodGroup = (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty) ? rawBloodGroup.trim() : 'Not set';

    final rawLocation = data?['location'] as String?;
    final location = (rawLocation != null && rawLocation.trim().isNotEmpty) ? rawLocation.trim() : 'Not set';

    final lastDonation = _formatLastDonationDate(data?['lastDonationDate']);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: LLSpacing.xl, vertical: LLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeSection(context, firstName),
          const SizedBox(height: 18),
          _buildAvailabilityCard(context, isAvailable),
          const SizedBox(height: LLSpacing.xxl),
          _buildProfileSummary(context, bloodGroup, location, lastDonation),
          const SizedBox(height: LLSpacing.xxl),
          _buildQuickActions(context),
          const SizedBox(height: LLSpacing.xxl),
          _buildEmergencyCTA(context),
          const SizedBox(height: LLSpacing.lg),
        ],
      ),
    );
  }

  /// 1. Personalized Welcome Section
  Widget _buildWelcomeSection(BuildContext context, String firstName) {
    final colors = context.colors;
    final greeting = _getTimeGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $firstName',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: -0.3),
        ),
        const SizedBox(height: LLSpacing.xs),
        Text(
          'Your small act of kindness can save a life.',
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
      ],
    );
  }

  /// 2. Availability Status Card
  ///
  /// Availability is a *donor* state, so it uses the shared success and
  /// warning tones - not critical red. Being unavailable is not an
  /// emergency, and colouring it red was overstating it.
  Widget _buildAvailabilityCard(BuildContext context, bool isAvailable) {
    final colors = context.colors;
    final tone = isAvailable ? LLTone.success : LLTone.warning;
    final (fg, bg) = tone.resolve(context);

    final title = isAvailable ? 'Available to Donate' : 'Currently Unavailable';
    final subtitle = isAvailable
        ? 'You are currently available to help save lives.'
        : 'You are currently not available for donation.';
    final icon = isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_rounded;

    return Container(
      padding: const EdgeInsets.all(LLSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LLRadius.card),
        border: Border.all(color: fg.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: fg.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, color: fg, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status is icon + text + colour, never colour alone.
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: fg),
                ),
                const SizedBox(height: LLSpacing.xxs),
                Text(subtitle, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Donor Information Summary
  Widget _buildProfileSummary(BuildContext context, String bloodGroup, String location, String lastDonation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LLSectionHeader(icon: Icons.badge_outlined, title: 'Your Donation Profile'),
        const SizedBox(height: LLSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                context: context,
                icon: Icons.water_drop_rounded,
                tone: LLTone.brand,
                label: 'Blood Group',
                value: bloodGroup,
                isHighlighted: bloodGroup != 'Not set',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoCard(
                context: context,
                icon: Icons.location_on_rounded,
                tone: LLTone.operational,
                label: 'Location',
                value: location,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoCard(
                context: context,
                icon: Icons.calendar_today_rounded,
                tone: LLTone.success,
                label: 'Last Donation',
                value: lastDonation,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Single compact info summary card
  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required LLTone tone,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final colors = context.colors;
    final (fg, bg) = tone.resolve(context);

    return LLCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: LLIconSize.action, color: fg),
          ),
          const SizedBox(height: LLSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Quick Actions Grid - the Donor module's own destinations,
  /// unchanged. Only their presentation is now shared.
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LLSectionHeader(icon: Icons.grid_view_rounded, title: 'Quick Actions'),
        const SizedBox(height: LLSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: LLSpacing.md,
          mainAxisSpacing: LLSpacing.md,
          childAspectRatio: 1.35,
          children: [
            _buildActionCard(
              context: context,
              icon: Icons.emergency_rounded,
              tone: LLTone.critical,
              title: 'Emergency Requests',
              description: 'View urgent blood requests',
              onTap: () => _navigateToEmergencyRequests(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.person_outline_rounded,
              tone: LLTone.operational,
              title: 'My Profile',
              description: 'View and update your profile',
              onTap: () => _navigateToProfile(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.assignment_turned_in_outlined,
              tone: LLTone.analytics,
              title: 'My Responses',
              description: 'Track your responses',
              onTap: () => _navigateToMyResponses(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.history_rounded,
              tone: LLTone.success,
              title: 'Donation History',
              description: 'View your donation records',
              onTap: () => _navigateToDonationHistory(context),
            ),
          ],
        ),
      ],
    );
  }

  /// Single clickable action card
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required LLTone tone,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final (fg, bg) = tone.resolve(context);

    return LLCard(
      onTap: onTap,
      padding: const EdgeInsets.all(LLSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(LLSpacing.sm),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(LLRadius.chip)),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(height: LLSpacing.sm),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: LLSpacing.xxs),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 5. Emergency Request Call-to-Action
  ///
  /// Previously a solid red gradient block. The shared system reserves
  /// saturated red for genuine emergency *content*, and calls for a
  /// tinted container with a saturated icon, border and action instead of
  /// a large filled red area - so this now reads as urgent without
  /// shouting, and works in Dark Mode.
  Widget _buildEmergencyCTA(BuildContext context) {
    final colors = context.colors;
    final (fg, bg) = LLTone.critical.resolve(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LLRadius.sheet),
        border: Border.all(color: fg.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: fg, size: 22),
              const SizedBox(width: LLSpacing.sm),
              Expanded(
                child: Text(
                  'Emergency Blood Requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Someone may need your help right now. Check active requests in your area.',
            style: TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _navigateToEmergencyRequests(context),
              style: FilledButton.styleFrom(
                backgroundColor: fg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: LLSpacing.md),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: LLIconSize.action),
              label: const Text('View Emergency Requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
