import 'package:flutter/material.dart';
import 'organisation_home_screen.dart';
import 'organisation_protected_conversation_screen.dart';

enum AlertStatus { accepted, pending, declined }

class DonorAlertItem {
  final String id;
  final String title;
  final String details;
  final String time;
  final AlertStatus status;
  final bool isToday;

  const DonorAlertItem({
    required this.id,
    required this.title,
    required this.details,
    required this.time,
    required this.status,
    required this.isToday,
  });
}

class OrganisationAlertsNotifications2Screen extends StatefulWidget {
  /// Donor shown in the header subtitle (e.g. "D-1042")
  final String donorId;

  const OrganisationAlertsNotifications2Screen({
    super.key,
    this.donorId = 'D-1042',
  });

  @override
  State<OrganisationAlertsNotifications2Screen> createState() =>
      _OrganisationAlertsNotifications2ScreenState();
}

class _OrganisationAlertsNotifications2ScreenState
    extends State<OrganisationAlertsNotifications2Screen> {
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
  static const Color tealBorder = Color(0xFFC8E1E1);
  static const Color tealText = Color(0xFF0F7F86);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color successGreen = Color(0xFF1E8A4C);
  static const Color alertRed = Color(0xFFD92D20);

  // TODO: replace with real data (Firestore) later
  final List<DonorAlertItem> _alerts = const [
    DonorAlertItem(
      id: 'a1',
      title: 'Donor D-1042 accepted',
      details: 'A+ emergency request • 2.1 km',
      time: '2 min ago',
      status: AlertStatus.accepted,
      isToday: true,
    ),
    DonorAlertItem(
      id: 'a2',
      title: 'Donor response pending',
      details: 'D-1187 • A+ • notified 10 min ago',
      time: '10 min ago',
      status: AlertStatus.pending,
      isToday: true,
    ),
    DonorAlertItem(
      id: 'a3',
      title: 'Donation request declined',
      details: 'D-1091 • Consider another matched donor',
      time: '1 hr ago',
      status: AlertStatus.declined,
      isToday: false,
    ),
  ];

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openMessage() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OrganisationProtectedConversationScreen(
        donorId: widget.donorId,
      ),
    ),
  );
}

  void _backToRequest() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const OrganisationHomeScreen(initialIndex: 1),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _alerts.where((a) => a.isToday).toList();
    final earlier = _alerts.where((a) => !a.isToday).toList();

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
                      for (final a in today) _buildAlertCard(a),
                      const SizedBox(height: 16),
                    ],

                    if (earlier.isNotEmpty) ...[
                      _buildSectionTitle('Earlier'),
                      const SizedBox(height: 12),
                      for (final a in earlier) _buildAlertCard(a),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 4),

                    _buildPrivacyCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            _buildBottomButtons(),
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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alerts & Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.donorId} - Stay updated on donor responses',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: secondaryText),
                ),
              ],
            ),
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
  // ALERT CARD
  // ============================================================

  Widget _buildStatusIcon(AlertStatus status) {
    switch (status) {
      case AlertStatus.accepted:
        return const Icon(Icons.check_rounded, size: 22, color: successGreen);
      case AlertStatus.pending:
        return const Text(
          '!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: alertRed,
            height: 1,
          ),
        );
      case AlertStatus.declined:
        return const Icon(Icons.close_rounded, size: 20, color: alertRed);
    }
  }

  Widget _buildAlertCard(DonorAlertItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: _buildStatusIcon(item.status)),
            ),

            const SizedBox(width: 12),

            // Title + details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: mainText,
                    ),
                  ),
                  const SizedBox(height: 6),
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

            const SizedBox(width: 8),

            // Time
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.time,
                style: const TextStyle(
                  fontSize: 11,
                  color: secondaryText,
                ),
              ),
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
          border: Border.all(color: tealBorder),
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

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message (filled)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _openMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: whiteColor,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Message',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Back to Request (outlined)
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: _backToRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: tealText,
                side: const BorderSide(color: tealText, width: 1.2),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Back to Request',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}