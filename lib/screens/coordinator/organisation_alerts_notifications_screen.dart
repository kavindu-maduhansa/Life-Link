import 'package:flutter/material.dart';

import '../../services/coordinator_service.dart';
import 'organisation_alerts_notifications_2_screen.dart';

class OrganisationAlertsNotificationsScreen extends StatefulWidget {
  const OrganisationAlertsNotificationsScreen({super.key});

  @override
  State<OrganisationAlertsNotificationsScreen> createState() =>
      _OrganisationAlertsNotificationsScreenState();
}

class _OrganisationAlertsNotificationsScreenState
    extends State<OrganisationAlertsNotificationsScreen> {
  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color tealCard = Color(0xFFDDF3F3);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color acceptedColor = Color(0xFF2D9974);
  static const Color pendingColor = Color(0xFFD98A1B);
  static const Color declinedColor = Color(0xFF971B3E);

  final CoordinatorService _service = CoordinatorService();

  late Future<List<CoordinatorResponseEvent>> _future =
      _service.recentResponses();

  Future<void> _reload() async {
    final next = _service.recentResponses();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<List<CoordinatorResponseEvent>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryMaroon),
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildMessageState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load responses',
                      message: 'Please check your connection and try again.',
                      action: TextButton(
                        onPressed: _reload,
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: primaryMaroon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  final events =
                      snapshot.data ?? const <CoordinatorResponseEvent>[];
                  return RefreshIndicator(
                    color: primaryMaroon,
                    onRefresh: _reload,
                    child: _buildList(events),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<CoordinatorResponseEvent> events) {
    final today = events.where((e) => e.isToday).toList();
    final earlier = events.where((e) => !e.isToday).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 28, bottom: 30),
      children: [
        if (events.isEmpty) _buildEmptyState(),
        if (today.isNotEmpty) ...[
          _buildSectionTitle('Today'),
          const SizedBox(height: 12),
          for (final e in today) _buildCard(e, events),
          const SizedBox(height: 16),
        ],
        if (earlier.isNotEmpty) ...[
          _buildSectionTitle('Earlier'),
          const SizedBox(height: 12),
          for (final e in earlier) _buildCard(e, events),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 4),
        _buildPrivacyCard(),
      ],
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
  // RESPONSE CARD
  // ============================================================

  Widget _buildCard(
    CoordinatorResponseEvent e,
    List<CoordinatorResponseEvent> all,
  ) {
    final color = e.isAccepted
        ? acceptedColor
        : e.isPending
            ? pendingColor
            : declinedColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganisationAlertsNotifications2Screen(
                donorId: e.donorCode,
                events: all.where((x) => x.donorUid == e.donorUid).toList(),
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
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
                      'Donor ${e.donorCode} • ${e.statusLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: mainText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${e.bloodGroup} request • ${e.hospitalName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  e.timeAgo,
                  style: const TextStyle(fontSize: 11, color: secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY / ERROR STATES
  // ============================================================

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 30, bottom: 10),
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
              'No donor responses yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: mainText,
              ),
            ),
            SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Invite donors from Find & Match Donors. Their answers '
                'appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: secondaryText),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: mainText,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: secondaryText),
            ),
            if (action != null) ...[
              const SizedBox(height: 8),
              action,
            ],
          ],
        ),
      ),
    );
  }

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
              'Names and contact details stay hidden.',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}