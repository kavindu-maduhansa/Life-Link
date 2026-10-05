import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/blood_request.dart';
import '../../services/coordinator_service.dart';
import 'organisation_alerts_notifications_screen.dart';
import 'organisation_find_match_donors_screen.dart';
import 'organisation_profile_screen.dart';
import 'organisation_requests_screen.dart';
import 'organisation_response_tracking_screen.dart';

class OrganisationHomeScreen extends StatefulWidget {
  final int initialIndex;

  const OrganisationHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<OrganisationHomeScreen> createState() =>
      _OrganisationHomeScreenState();
}

class _OrganisationHomeScreenState extends State<OrganisationHomeScreen> {
  late int _selectedIndex;

  final CoordinatorService _service = CoordinatorService();

  // Kept in a field so the stream is created once, not on every rebuild.
  late final Stream<List<BloodRequest>> _requestsStream =
      _service.verifiedRequests();

  /// The verified request the coordinator chose to find donors for.
  /// Kept here so the Donors tab knows which request it is matching.
  BloodRequest? _selectedRequest;

  /// The tab that was active before switching to the Donors tab.
  /// Used so the back button returns to the correct previous tab.
  int _previousIndex = 0;
  
  /// Accepted donor responses across the open requests. Counted from the
  /// responses themselves, because the counter stored on each request is
  /// not updated when a donor accepts from the donor app.
  int? _acceptedCount;

  /// Last tab shown. Used to refresh the count when returning to Home.
  int _lastIndex = -1;

    @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _lastIndex = widget.initialIndex;
    _refreshAcceptedCount();
  }

  Future<void> _refreshAcceptedCount() async {
    try {
      final events = await _service.recentResponses();
      if (!mounted) return;
      setState(() {
        _acceptedCount = events.where((e) => e.isAccepted).length;
      });
    } catch (_) {
      // Keep the previous value; the card falls back to the stored counter.
    }
  }

  /// Switches to the Donors tab. Passing a request selects it; passing
  /// null keeps whichever request was selected before.
  void _openDonors([BloodRequest? request]) {
    setState(() {
      _previousIndex = _selectedIndex;
      if (request != null) {
        _selectedRequest = request;
      }
      _selectedIndex = 2;
    });
  }

  // ============================================================
  // DESIGN COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color tealCard = Color(0xFFDDF3F3);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color greenDot = Color(0xFF2D9974);

  @override
  Widget build(BuildContext context) {
      // Re-count when the coordinator returns to the Home tab.
    if (_selectedIndex == 0 && _lastIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshAcceptedCount();
      });
    }
    _lastIndex = _selectedIndex;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeScreen(),
            OrganisationRequestsScreen(
              onBack: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              onFindDonors: (request) {
                _openDonors(request);
              },
            ),
            OrganisationFindMatchDonorsScreen(
              selectedRequest: _selectedRequest,
              onBack: () {
                setState(() {
                  _selectedIndex = _previousIndex;
                });
              },
            ),
            OrganisationResponseTrackingScreen(
              selectedRequest: _selectedRequest,
            
              onBack: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              onTrackResponders: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const OrganisationAlertsNotificationsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // HOME (live data from Firestore)
  // ============================================================

  Widget _buildHomeScreen() {
    return StreamBuilder<List<BloodRequest>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <BloodRequest>[];
        final hasError = snapshot.hasError;
        final loading = !snapshot.hasData && !hasError;

        // Counted from the responses themselves. Until the first count
        // arrives, fall back to the counter stored on the requests.
        final acceptedCount = _acceptedCount ??
            requests.fold<int>(0, (sum, r) => sum + r.donorsAcceptedCount);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildEmergencyCoordinationCard(
                count: requests.length,
                loading: loading,
              ),
              const SizedBox(height: 28),
              _buildSectionTitle('Quick actions'),
              const SizedBox(height: 14),
              _buildQuickActions(acceptedCount),
              const SizedBox(height: 20),
              _buildSectionTitle('Verified requests'),
              const SizedBox(height: 14),
              _buildVerifiedRequestsSection(
                requests: requests,
                loading: loading,
                hasError: hasError,
              ),
              const SizedBox(height: 28),
              _buildPrivacyReminder(),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 13, 17, 14),
      decoration: const BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: greenDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Organization Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: mainText,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 13),
                  child: Text(
                    'Welcome back, ${_getUserName(user)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile icon
          InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrganisationProfileScreen(),
                ),
              );
            },
            child: Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F0F0),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: const Color(0xFFDAD6D7),
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserName(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Coordinator';
  }

  // ============================================================
  // EMERGENCY COORDINATION
  // ============================================================

  Widget _buildEmergencyCoordinationCard({
    required int count,
    required bool loading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        height: 112,
        padding: const EdgeInsets.fromLTRB(18, 17, 14, 15),
        decoration: BoxDecoration(
          color: pinkCard,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFFEAD6DA),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency coordination',
              style: TextStyle(
                fontSize: 14,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  loading ? '–' : '$count',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                    height: 0.95,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    count == 1
                        ? 'active verified request'
                        : 'active verified requests',
                    style: const TextStyle(
                      fontSize: 14,
                      color: secondaryText,
                      height: 1.15,
                    ),
                  ),
                ),
                _buildPrimaryButton(
                  text: 'View requests',
                  width: 119,
                  height: 29,
                  fontSize: 11,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: mainText,
          height: 1.1,
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(int acceptedCount) {
        final responsesText = acceptedCount == 0
        ? 'No accepted donor\nresponses yet'
        : acceptedCount == 1
            ? '1 accepted donor\nresponse'
            : '$acceptedCount accepted donor\nresponses';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              title: 'Find donors',
              description: 'Match a verified\nrequest to your network',
              buttonText: 'Start matching',
              buttonWidth: 126,
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildQuickActionCard(
              title: 'Responses',
              description: responsesText,
              buttonText: 'Track',
              buttonWidth: 75,
              outlinedButton: true,
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String description,
    required String buttonText,
    required double buttonWidth,
    required VoidCallback onPressed,
    bool outlinedButton = false,
  }) {
    return Container(
      height: 124,
      padding: const EdgeInsets.fromLTRB(19, 17, 15, 12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: secondaryText,
                height: 1.25,
              ),
            ),
          ),
          outlinedButton
              ? _buildOutlinedButton(
                  text: buttonText,
                  width: buttonWidth,
                  height: 30,
                  onPressed: onPressed,
                )
              : _buildPrimaryButton(
                  text: buttonText,
                  width: buttonWidth,
                  height: 30,
                  fontSize: 11,
                  onPressed: onPressed,
                ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFIED REQUESTS (live)
  // ============================================================

  Widget _buildVerifiedRequestsSection({
    required List<BloodRequest> requests,
    required bool loading,
    required bool hasError,
  }) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: primaryMaroon),
        ),
      );
    }

    if (hasError) {
      return _buildMessageCard(
        'Could not load verified requests. Please check your connection '
        'and try again.',
      );
    }

    if (requests.isEmpty) {
      return _buildMessageCard(
        'No verified requests right now. Requests appear here once a '
        'hospital has verified them.',
      );
    }

    // Home shows the three most urgent; the Requests tab shows them all.
    final shown = requests.take(3).toList();

    return Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          _buildVerifiedRequestCard(shown[i]),
          if (i != shown.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildMessageCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: secondaryText,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedRequestCard(BloodRequest r) {
    final hasLocation = r.location.isNotEmpty && r.location != '-';
    final place =
        hasLocation ? '${r.hospitalName} • ${r.location}' : r.hospitalName;
    final remaining = _remainingLabel(r.requiredAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(17, 16, 17, 14),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgency badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: pinkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryMaroon,
                ),
              ),
              child: Text(
                r.urgency.toUpperCase(),
                style: const TextStyle(
                  color: primaryMaroon,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.bloodGroup} • ${r.unitsNeeded} '
                        '${r.unitsNeeded == 1 ? 'unit' : 'units'}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: mainText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 11),
                      _buildPrimaryButton(
                        text: 'Find donors',
                        width: 103,
                        height: 27,
                        fontSize: 11,
                        onPressed: () => _openDonors(r),
                      ),
                    ],
                  ),
                ),
                if (remaining != null) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        remaining.$1,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryMaroon,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        remaining.$2,
                        style: const TextStyle(
                          fontSize: 11,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Time left until the blood is needed. Returns null when the request
  /// has no required-by time recorded, so nothing is invented.
  (String, String)? _remainingLabel(DateTime? requiredAt) {
    if (requiredAt == null) return null;

    final diff = requiredAt.difference(DateTime.now());

    if (diff.isNegative) {
      return ('Overdue', 'past required time');
    }
    if (diff.inMinutes < 60) {
      return ('${diff.inMinutes} min', 'remaining');
    }
    if (diff.inHours < 24) {
      return ('${diff.inHours} h', 'remaining');
    }
    return ('${diff.inDays} d', 'remaining');
  }

  // ============================================================
  // PRIVACY REMINDER
  // ============================================================

  Widget _buildPrivacyReminder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        height: 65,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: tealCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFC8E1E1),
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy reminder',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Only share the information required for donor coordination.',
              style: TextStyle(
                fontSize: 12,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _buildPrimaryButton({
    required String text,
    required double width,
    required double height,
    required VoidCallback onPressed,
    double fontSize = 12,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OUTLINED BUTTON
  // ============================================================

  Widget _buildOutlinedButton({
    required String text,
    required double width,
    required double height,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF008DA3),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          side: const BorderSide(
            color: Color(0xFF008DA3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 67,
      decoration: const BoxDecoration(
        color: whiteColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.indeterminate_check_box_outlined,
            selectedIcon: Icons.indeterminate_check_box_rounded,
            label: 'Requests',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.diamond_outlined,
            selectedIcon: Icons.diamond_outlined,
            label: 'Donors',
            index: 2,
          ),
          _buildNavItem(
            icon: Icons.notifications_none_rounded,
            selectedIcon: Icons.notifications_rounded,
            label: 'Alerts',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 23,
              color: selected ? primaryMaroon : const Color(0xFF6D7A8C),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? primaryMaroon : const Color(0xFF6D7A8C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// flutter run -d emulator-5554