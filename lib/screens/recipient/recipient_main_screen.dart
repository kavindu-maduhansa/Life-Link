import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'blood_request_flow/patient_details_screen.dart';
import 'blood_request_flow/my_requests_screen.dart';
import 'blood_request_flow/notifications_screen.dart';
import 'profile_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import '../../widgets/appearance_selector_sheet.dart';
import '../../widgets/lifelink/ll_brand.dart';
import '../../widgets/neumorphic/neumorphic_widgets.dart';

/// Main recipient screen with unified Neumorphic bottom navigation bar
class RecipientMainScreen extends StatefulWidget {
  const RecipientMainScreen({super.key});

  @override
  State<RecipientMainScreen> createState() => _RecipientMainScreenState();
}

class _RecipientMainScreenState extends State<RecipientMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const MyRequestsScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
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
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: colors.surface,
          elevation: 0,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Home tab content
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Future<void> _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
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
        actions: [
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data();
          final userName = userData?['fullName'] as String? ?? 'User';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Section
                Text(
                  '${_getGreeting()}, $userName',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'What would you like to do today?',
                  style: TextStyle(fontSize: 15, color: colors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Request Options Cards
                _buildRequestOptionCard(
                  context,
                  icon: Icons.emergency_rounded,
                  title: 'Emergency Request',
                  description: 'Urgent blood request for critical situations',
                  color: colors.critical,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PatientDetailsScreen(isEmergency: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildRequestOptionCard(
                  context,
                  icon: Icons.calendar_today_rounded,
                  title: 'Non-Emergency Request',
                  description: 'Schedule blood request in advance',
                  color: colors.accent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PatientDetailsScreen(isEmergency: false),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return NeumorphicCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(LLRadius.control),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: colors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
