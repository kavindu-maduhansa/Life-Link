import 'package:flutter/material.dart';
import 'recipient_home_screen.dart';
import 'blood_request_flow/my_requests_screen.dart';
import 'blood_request_flow/notifications_screen.dart';
import 'profile_screen.dart';

/// Wrapper that adds a bottom navigation bar to the recipient screens.
///
/// This wraps the existing recipient screens and adds navigation between:
/// - Home (existing RecipientHomeScreen)
/// - Requests (MyRequestsScreen)
/// - Tracking (NotificationsScreen - repurposed for tracking)
/// - Profile (ProfileScreen)
class RecipientNavbarWrapper extends StatefulWidget {
  final int initialIndex;
  const RecipientNavbarWrapper({super.key, this.initialIndex = 0});

  @override
  State<RecipientNavbarWrapper> createState() => _RecipientNavbarWrapperState();
}

class _RecipientNavbarWrapperState extends State<RecipientNavbarWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const RecipientHomeScreen(),
    const MyRequestsScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFC62828),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox_rounded),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes_rounded),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
