import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/appearance_selector_sheet.dart';
import '../../widgets/lifelink/ll_app_shell.dart';
import '../../widgets/lifelink/ll_nav.dart';
import 'donation_history_screen.dart';
import 'donor_home_screen.dart';
import 'donor_profile_screen.dart';
import 'emergency_requests_screen.dart';
import 'my_responses_screen.dart';

/// The root navigation shell for the Donor role.
///
/// Implements the same [LLAppShell] + [LLRoleNav] pattern used by the
/// Hospital module so the Donor experience matches the rest of the app
/// exactly: brand mark in the app bar, 4-destination navigation bar
/// styled with primary color accents, responsive bottom nav on mobile
/// and a navigation rail on wide screens.
///
/// All Firebase logic lives in the individual Tab widgets:
///  - [DonorHomeTab]         → Firestore `users/{uid}` stream (dashboard)
///  - [EmergencyRequestsTab] → Firestore `requests` collection
///  - [MyResponsesTab]       → Firestore `requests/{id}/responses` collection
///  - [DonationHistoryTab]   → Firestore `donation_history` collection
/// Profile is accessible via top AppBar action and Home Quick Actions.
///
/// This file contains ONLY navigation wiring — no backend code.
class DonorShell extends StatelessWidget {
  const DonorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return LLAppShell(
      nav: LLRoleNav(
        roleLabel: 'Donor',
        destinations: [
          LLNavDestination(
            label: 'Home',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            tooltip: 'Donor Dashboard',
            builder: (_) => const DonorHomeTab(),
          ),
          LLNavDestination(
            label: 'Requests',
            icon: Icons.emergency_outlined,
            selectedIcon: Icons.emergency_rounded,
            tooltip: 'Emergency Blood Requests',
            builder: (_) => const EmergencyRequestsTab(),
          ),
          LLNavDestination(
            label: 'My Responses',
            icon: Icons.assignment_turned_in_outlined,
            selectedIcon: Icons.assignment_turned_in_rounded,
            tooltip: 'My Donation Responses',
            builder: (_) => const MyResponsesTab(),
          ),
          LLNavDestination(
            label: 'History',
            icon: Icons.history_rounded,
            selectedIcon: Icons.history_rounded,
            tooltip: 'Donation History',
            builder: (_) => const DonationHistoryTab(),
          ),
        ],
        actions: [
          LLAppBarAction(
            icon: Icons.account_circle_outlined,
            tooltip: 'My Profile',
            isPrimary: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonorProfileScreen()),
              );
            },
          ),
          LLAppBarAction(
            icon: Icons.palette_outlined,
            tooltip: 'Appearance',
            onPressed: () => AppearanceSelectorSheet.show(context),
          ),
          LLAppBarAction(
            icon: Icons.logout_rounded,
            tooltip: 'Sign Out',
            // isPrimary keeps it always visible even on narrow phones
            isPrimary: true,
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }
}
