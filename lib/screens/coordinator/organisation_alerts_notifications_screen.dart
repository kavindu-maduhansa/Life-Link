import 'package:flutter/material.dart';

enum NotificationGroup { today, yesterday }

class DonorNotificationItem {
  final String id;
  final String donorId;
  final String details; // e.g. "A+ emergency request • 2.1 km"
  final NotificationGroup group;

  const DonorNotificationItem({
    required this.id,
    required this.donorId,
    required this.details,
    required this.group,
  });
}

class OrganisationAlertsNotificationsScreen extends StatefulWidget {
  const OrganisationAlertsNotificationsScreen({super.key});

  @override
  State<OrganisationAlertsNotificationsScreen> createState() =>
      _OrganisationAlertsNotificationsScreenState();
}

class _OrganisationAlertsNotificationsScreenState
    extends State<OrganisationAlertsNotificationsScreen> {
  // ============================================================
  // DESIGN COLORS (same as the other coordinator screens)
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color tealCard = Color(0xFFDDF3F3);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color mutedIcon = Color(0xFFB8BEC8);

  // TODO: replace with real data (Firestore) later
  final List<DonorNotificationItem> _notifications = [
    const DonorNotificationItem(
      id: 'n1',
      donorId: 'D-1042',
      details: 'A+ emergency request • 2.1 km',
      group: NotificationGroup.today,
    ),
    const DonorNotificationItem(
      id: 'n2',
      donorId: 'D-1020',
      details: 'O+ emergency request • 2.1 km',
      group: NotificationGroup.yesterday,
    ),
  ];

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _notifications
        .where((n) => n.group == NotificationGroup.today)
        .toList();
    final yesterday = _notifications
        .where((n) => n.group == NotificationGroup.yesterday)
        .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    if (today.isNotEmpty) ...[
                      _buildSectionTitle('Today'),
                      const SizedBox(height: 12),
                      for (final n in today) _buildNotificationCard(n),
                      const SizedBox(height: 16),
                    ],

                    if (yesterday.isNotEmpty) ...[
                      _buildSectionTitle('Yesterday'),
                      const SizedBox(height: 12),
                      for (final n in yesterday) _buildNotificationCard(n),
                      const SizedBox(height: 16),
                    ],

                    if (_notifications.isEmpty) _buildEmptyState(),

                    const SizedBox(height: 20),

                    _buildPrivacyCard(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 13, 17, 14),
      decoration: const BoxDecoration(
        color: whiteColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 36,
              decoration: BoxDecoration(
                color: pinkCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: primaryMaroon,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Responders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Stay updated on donor responses',
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard(DonorNotificationItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: mainText,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donor ${item.donorId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: mainText,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item.details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Delete
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _deleteNotification(item.id),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: mutedIcon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 30),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: primaryMaroon,
            ),
            SizedBox(height: 10),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: mainText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Donor responses will appear here.',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRIVACY CARD
  // ============================================================

  Widget _buildPrivacyCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: BoxDecoration(
          color: tealCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8E1E1)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy protected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Personal contact details stay hidden.',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}