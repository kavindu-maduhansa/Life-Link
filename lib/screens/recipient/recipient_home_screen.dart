import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import '../../widgets/appearance_selector_sheet.dart';
import '../../widgets/lifelink/ll_brand.dart';
import '../../widgets/neumorphic/neumorphic_widgets.dart';
import '../../widgets/offline_banner.dart';
import 'blood_request_flow/my_requests_screen.dart';
import 'blood_request_flow/notifications_screen.dart';
import 'blood_request_flow/patient_details_screen.dart';
import 'blood_request_flow/request_status_screen.dart';
import 'profile_screen.dart';

/// Recipient Module Shell & Dashboard for managing emergency and scheduled blood requests.
///
/// Designed as part of the LifeLink HCI high-fidelity prototype (FR01/FR06).
/// Unified with modern LifeLink navigation (responsive Material 3 NavigationBar on mobile
/// and NavigationRail on wide desktop/tablet screens), tactile Neumorphic Soft UI components,
/// dual-shadow raised cards, and clear emergency actions while maintaining 100% functional
/// integrity, routing safety, and Firebase persistence.
class RecipientHomeScreen extends StatefulWidget {
  final int initialIndex;

  const RecipientHomeScreen({super.key, this.initialIndex = 0});

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

  @override
  State<RecipientHomeScreen> createState() => _RecipientHomeScreenState();
}

class _RecipientHomeScreenState extends State<RecipientHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
  }

  void _onSelectTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = FirebaseAuth.instance.currentUser;
    final isWide = LLBreakpoints.isWide(context);

    final screens = <Widget>[
      _RecipientHomeTab(
        onNavigateToRequests: () => _onSelectTab(1),
        onNavigateToAlerts: () => _onSelectTab(2),
      ),
      const MyRequestsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    final content = Column(
      children: [
        const OfflineBanner(),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onSelectTab,
                  backgroundColor: colors.surface,
                  indicatorColor: colors.primaryContainer,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(color: colors.primary),
                  unselectedIconTheme: IconThemeData(color: colors.textSecondary),
                  selectedLabelTextStyle: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: colors.textSecondary,
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: _buildRequestsBadge(user?.uid, selected: false),
                      selectedIcon: _buildRequestsBadge(user?.uid, selected: true),
                      label: const Text('Requests'),
                    ),
                    NavigationRailDestination(
                      icon: _buildAlertsBadge(user?.uid, selected: false),
                      selectedIcon: _buildAlertsBadge(user?.uid, selected: true),
                      label: const Text('Alerts'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                VerticalDivider(width: 1, thickness: 1, color: colors.border),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.5)
                        : colors.darkShadow.withValues(alpha: 0.08),
                    offset: const Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: colors.surface,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: colors.primaryContainer,
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 12,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: states.contains(WidgetState.selected)
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onSelectTab,
                  backgroundColor: colors.surface,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: colors.primaryContainer,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                      tooltip: 'Recipient Dashboard',
                    ),
                    NavigationDestination(
                      icon: _buildRequestsBadge(user?.uid, selected: false),
                      selectedIcon: _buildRequestsBadge(user?.uid, selected: true),
                      label: 'Requests',
                      tooltip: 'My Blood Requests',
                    ),
                    NavigationDestination(
                      icon: _buildAlertsBadge(user?.uid, selected: false),
                      selectedIcon: _buildAlertsBadge(user?.uid, selected: true),
                      label: 'Alerts',
                      tooltip: 'Notifications & Alerts',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                      tooltip: 'Recipient Profile',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRequestsBadge(String? uid, {required bool selected}) {
    final colors = context.colors;
    final baseIcon = Icon(
      selected ? Icons.list_alt_rounded : Icons.list_alt_outlined,
      color: selected ? colors.primary : colors.textSecondary,
    );

    if (uid == null) return baseIcon;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('createdBy', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) return baseIcon;
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return baseIcon;
        return Badge(
          label: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: colors.primary,
          child: baseIcon,
        );
      },
    );
  }

  Widget _buildAlertsBadge(String? uid, {required bool selected}) {
    final colors = context.colors;
    final baseIcon = Icon(
      selected ? Icons.notifications_rounded : Icons.notifications_none_rounded,
      color: selected ? colors.primary : colors.textSecondary,
    );

    if (uid == null) return baseIcon;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .where('recipientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) return baseIcon;
        final docs = snapshot.data?.docs ?? const [];
        final unreadCount = docs.where((d) => d.data()['isRead'] != true).length;
        if (unreadCount == 0) return baseIcon;
        return Badge(
          label: Text('$unreadCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: colors.critical,
          child: baseIcon,
        );
      },
    );
  }
}

/// Home dashboard tab content
class _RecipientHomeTab extends StatelessWidget {
  final VoidCallback onNavigateToRequests;
  final VoidCallback onNavigateToAlerts;

  const _RecipientHomeTab({
    required this.onNavigateToRequests,
    required this.onNavigateToAlerts,
  });

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  void _handleCreateRequestTap(BuildContext context, {required bool isEmergency}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(isEmergency: isEmergency),
      ),
    );
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Recipient Home',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
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
            tooltip: 'Alerts',
            icon: const Icon(Icons.notifications_outlined),
            color: colors.textSecondary,
            onPressed: onNavigateToAlerts,
          ),
          IconButton(
            tooltip: 'Appearance',
            icon: const Icon(Icons.palette_outlined),
            color: colors.textSecondary,
            onPressed: () => AppearanceSelectorSheet.show(context),
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
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
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
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage and track your emergency and scheduled blood requests.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                  height: 1.3,
                                ),
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
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Submit a verified blood request directly to hospital coordinators and compatible blood donors.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        NeumorphicButton(
                          onPressed: () => _handleCreateRequestTap(context, isEmergency: true),
                          isCritical: true,
                          height: 48,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Create Emergency Request',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2b. Scheduled / Non-Emergency Request Option
                  NeumorphicCard(
                    onTap: () => _handleCreateRequestTap(context, isEmergency: false),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(LLRadius.control),
                            border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
                          ),
                          child: Icon(Icons.calendar_today_rounded, size: 24, color: colors.accent),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule Non-Emergency Request',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Plan blood requirement in advance for surgeries and treatments.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colors.textSecondary,
                          size: 15,
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
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How your emergency request moves through verification and donor matching:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
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

                  // 4. "My Requests" Section Header with Live Count & View All
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: user?.uid != null
                        ? FirebaseFirestore.instance
                            .collection('requests')
                            .where('createdBy', isEqualTo: user!.uid)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      final requests = (snapshot.hasError || !snapshot.hasData)
                          ? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]
                          : snapshot.data!.docs;
                      final count = requests.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Requests',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              InkWell(
                                onTap: onNavigateToRequests,
                                borderRadius: BorderRadius.circular(LLRadius.pill),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.elevatedSurface,
                                    borderRadius: BorderRadius.circular(LLRadius.pill),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$count ${count == 1 ? 'Request' : 'Requests'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 14,
                                        color: colors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 5. My Requests preview / empty state
                          if (requests.isEmpty)
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
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create a request when you need urgent blood support.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: colors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    NeumorphicButton(
                                      onPressed: () => _handleCreateRequestTap(context, isEmergency: true),
                                      isPrimary: false,
                                      height: 44,
                                      label: 'Start Request',
                                      icon: Icons.add_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...requests.take(2).map((doc) {
                              final data = doc.data();
                              final status = data['status'] as String? ?? 'pending';
                              final bloodGroup = data['bloodGroup'] as String? ?? 'Unknown';
                              final unitsNeeded = data['unitsNeeded'] as int? ?? 1;
                              final hospitalName = data['hospitalName'] as String? ?? 'Unknown Hospital';
                              final isEmergency = data['requestType'] == 'emergency';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: NeumorphicCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RequestStatusScreen(requestId: doc.id),
                                      ),
                                    );
                                  },
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isEmergency ? colors.critical : colors.accent).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: (isEmergency ? colors.critical : colors.accent).withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isEmergency ? Icons.emergency_rounded : Icons.calendar_today_rounded,
                                                  size: 13,
                                                  color: isEmergency ? colors.critical : colors.accent,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isEmergency ? 'Emergency' : 'Scheduled',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isEmergency ? colors.critical : colors.accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          RecipientHomeScreen.buildStatusBadge(context, status, dense: true),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: colors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
                                            ),
                                            child: Text(
                                              bloodGroup,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: colors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  hospitalName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: colors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '$unitsNeeded unit${unitsNeeded == 1 ? '' : 's'} needed',
                                                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: colors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                    },
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
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
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
