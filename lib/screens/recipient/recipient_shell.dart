import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'recipient_bottom_navbar.dart';
import 'recipient_home_screen.dart';

/// Shell wrapper that keeps the navbar permanently visible for all recipient screens
class RecipientShell extends StatelessWidget {
  final Widget child;
  final int currentNavIndex;

  const RecipientShell({
    super.key,
    required this.child,
    this.currentNavIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: child,
      bottomNavigationBar: RecipientBottomNavbar(
        currentIndex: currentNavIndex,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => RecipientHomeScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
    );
  }
}
