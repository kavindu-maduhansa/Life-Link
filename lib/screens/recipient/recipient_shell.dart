import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/appearance_selector_sheet.dart';
import '../../widgets/lifelink/ll_app_shell.dart';
import '../../widgets/lifelink/ll_nav.dart';
import 'recipient_home_tab.dart';
import 'recipient_requests_tab.dart';
import 'recipient_tracking_tab.dart';
import 'recipient_profile_tab.dart';

/// The root navigation shell for the Recipient role.
///
/// Implements the same [LLAppShell] + [LLRoleNav] pattern used by the
/// Donor and Hospital modules so the Recipient experience matches the rest
/// of the app exactly: brand mark in the app bar, responsive bottom nav on
/// mobile and a navigation rail on wide screens.
///
/// All Firebase logic lives in the individual Tab widgets:
///  - [RecipientHomeTab]      → Firestore `users/{uid}` stream (dashboard)
///  - [RecipientRequestsTab]  → Firestore `requests` collection (user's requests)
///  - [RecipientTrackingTab]  → Firestore `requests` collection (tracking status)
///  - [RecipientProfileTab]   → Firestore `users/{uid}` stream (profile)
///
/// This file contains ONLY navigation wiring — no backend code.
class RecipientShell extends StatelessWidget {
  const RecipientShell({super.key});

  @override
  Widget build(BuildContext context) {
    return LLAppShell(
      nav: LLRoleNav(
        roleLabel: 'Recipient',
        destinations: [
          LLNavDestination(
            label: 'Home',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            tooltip: 'Recipient Dashboard',
            builder: (_) => const RecipientHomeTab(),
          ),
          LLNavDestination(
            label: 'Requests',
            icon: Icons.list_alt_outlined,
            selectedIcon: Icons.list_alt_rounded,
            tooltip: 'My Blood Requests',
            builder: (_) => const RecipientRequestsTab(),
          ),
          LLNavDestination(
            label: 'Tracking',
            icon: Icons.track_changes_outlined,
            selectedIcon: Icons.track_changes_rounded,
            tooltip: 'Track Request Status',
            builder: (_) => const RecipientTrackingTab(),
          ),
          LLNavDestination(
            label: 'Profile',
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle_rounded,
            tooltip: 'Recipient Profile',
            builder: (_) => const RecipientProfileTab(),
          ),
        ],
        actions: [
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
