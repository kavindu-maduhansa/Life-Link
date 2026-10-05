import 'package:flutter/material.dart';

import '../../services/coordinator_service.dart';
import 'organisation_home_screen.dart';
import 'organisation_follow_up_card.dart';

class OrganisationAlertsNotifications2Screen extends StatelessWidget {
  /// Anonymous donor code shown in the header, e.g. "D-5CSP".
  final String donorId;

  /// This donor's responses, newest first.
  final List<CoordinatorResponseEvent> events;

  const OrganisationAlertsNotifications2Screen({
    super.key,
    required this.donorId,
    required this.events,
  });

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
  static const Color pendingColor = Color(0xFFD98A1B);
  static const Color alertRed = Color(0xFFD92D20);

  void _backToRequest(BuildContext context) {
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
    final today = events.where((e) => e.isToday).toList();
    final earlier = events.where((e) => !e.isToday).toList();

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
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'No responses recorded for this donor yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryText,
                          ),
                        ),
                      ),
                    if (today.isNotEmpty) ...[
                      _buildSectionTitle('Today'),
                      const SizedBox(height: 12),
                      for (final e in today) _buildAlertCard(e),
                      const SizedBox(height: 16),
                    ],
                    if (earlier.isNotEmpty) ...[
                      _buildSectionTitle('Earlier'),
                      const SizedBox(height: 12),
                      for (final e in earlier) _buildAlertCard(e),
                      const SizedBox(height: 16),
                    ],
                       if (events.isNotEmpty)
                        OrganisationFollowUpCard(
                          donorUid: events.first.donorUid,
                          donorCode: donorId,
                        ),
                    const SizedBox(height: 4),
                    _buildPrivacyCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(context),
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
                  '$donorId · Stay updated on donor responses',
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

  String _titleFor(CoordinatorResponseEvent e) {
    if (e.isAccepted) return 'Donor $donorId accepted';
    if (e.isPending) return 'Donor response pending';
    if (e.status == 'withdrawn') return 'Donor withdrew the offer';
    return 'Donation request declined';
  }

  Widget _buildStatusIcon(CoordinatorResponseEvent e) {
    if (e.isAccepted) {
      return const Icon(Icons.check_rounded, size: 22, color: successGreen);
    }
    if (e.isPending) {
      return const Text(
        '!',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: pendingColor,
          height: 1,
        ),
      );
    }
    return const Icon(Icons.close_rounded, size: 20, color: alertRed);
  }

  Widget _buildAlertCard(CoordinatorResponseEvent e) {
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
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: _buildStatusIcon(e)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleFor(e),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: mainText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${e.bloodGroup} request • ${e.hospitalName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                e.timeAgo,
                style: const TextStyle(fontSize: 11, color: secondaryText),
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

    Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 16),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton(
          onPressed: () => _backToRequest(context),
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
    );
  }
}