import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'organisation_requests_screen.dart';
import 'organisation_find_match_donors_screen.dart';
import 'organisation_response_tracking_screen.dart';
import 'organisation_alerts_notifications_screen.dart';

class OrganisationHomeScreen extends StatefulWidget {
  final int initialIndex;

  const OrganisationHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<OrganisationHomeScreen> createState() =>
      _OrganisationHomeScreenState();
}

class _OrganisationHomeScreenState extends State<OrganisationHomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
              onFindDonors: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),

            const OrganisationFindMatchDonorsScreen(),

            OrganisationResponseTrackingScreen(
              onBack: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              onTrackResponders: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrganisationAlertsNotificationsScreen(),
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
  // HOME
  // ============================================================

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 28),

          _buildEmergencyCoordinationCard(),

          const SizedBox(height: 28),

          _buildSectionTitle('Quick actions'),

          const SizedBox(height: 14),

          _buildQuickActions(),

          const SizedBox(height: 20),

          _buildSectionTitle('Verified requests'),

          const SizedBox(height: 14),

          _buildVerifiedRequestCard(),

          const SizedBox(height: 28),

          _buildPrivacyReminder(),

          const SizedBox(height: 30),
        ],
      ),
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
          Container(
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
        ],
      ),
    );
  }

  String _getUserName(User? user) {
    if (user == null) {
      return 'Isiwara';
    }

    if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    return 'Isiwara';
  }

  // ============================================================
  // EMERGENCY COORDINATION
  // ============================================================

  Widget _buildEmergencyCoordinationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),

      child: Container(
        width: double.infinity,
        height: 112,

        padding: const EdgeInsets.fromLTRB(
          18,
          17,
          14,
          15,
        ),

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
                const Text(
                  '3',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                    height: 0.95,
                  ),
                ),

                const SizedBox(width: 13),

                const Expanded(
                  child: Text(
                    'active verified requests',
                    style: TextStyle(
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

  Widget _buildQuickActions() {
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
              description: '8 donor responses\nneed attention',
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

      padding: const EdgeInsets.fromLTRB(
        19,
        17,
        15,
        12,
      ),

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
  // VERIFIED REQUEST
  // ============================================================

  Widget _buildVerifiedRequestCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),

      child: Container(
        width: double.infinity,
        height: 155,

        padding: const EdgeInsets.fromLTRB(
          17,
          16,
          17,
          14,
        ),

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
            // URGENT
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

              child: const Text(
                'URGENT',
                style: TextStyle(
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A+ • 4 units',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: mainText,
                        ),
                      ),

                      const SizedBox(height: 3),

                      const Text(
                        'District General Hospital • 6.2 km',
                        style: TextStyle(
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
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      '12 min',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryMaroon,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'remaining',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

        padding: const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          8,
        ),

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
            selectedIcon:
                Icons.indeterminate_check_box_rounded,
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
              color: selected
                  ? primaryMaroon
                  : const Color(0xFF6D7A8C),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: selected
                    ? primaryMaroon
                    : const Color(0xFF6D7A8C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  // ============================================================
  // DONORS PLACEHOLDER
  // ============================================================

  Widget _buildDonorsScreen() {
    return _buildPlaceholderScreen(
      icon: Icons.people_outline_rounded,
      title: 'Donors',
      subtitle: 'Find and match suitable donors',
    );
  }

  // ============================================================
  // ALERTS PLACEHOLDER
  // ============================================================

  Widget _buildAlertsScreen() {
    return _buildPlaceholderScreen(
      icon: Icons.notifications_none_rounded,
      title: 'Alerts',
      subtitle: 'Donor responses and notifications',
    );
  }

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _buildPlaceholderScreen({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: primaryMaroon,
          ),

          const SizedBox(height: 15),

          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: mainText,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}


// flutter run -d emulator-5554