import 'package:flutter/material.dart';
import 'organisation_donor_details_screen.dart';

enum DonorResponseStatus { accepted, pending, declined }

class DonorResponseItem {
  final String donorId;
  final DonorResponseStatus status;
  final String units; // "2 units", "1 unit" or "—"

  const DonorResponseItem({
    required this.donorId,
    required this.status,
    required this.units,
  });
}

class OrganisationResponseTrackingScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onTrackResponders;

  final String requestId;
  final String bloodType;
  final int unitsNeeded;

  const OrganisationResponseTrackingScreen({
    super.key,
    this.onBack,
    this.onTrackResponders,
    this.requestId = 'REQ-1048',
    this.bloodType = 'A+',
    this.unitsNeeded = 4,
  });

  // ============================================================
  // DESIGN COLORS (same as OrganisationHomeScreen)
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color acceptedColor = Color(0xFF2D9974);
  static const Color pendingColor = Color(0xFFD98A1B);
  static const Color declinedColor = Color(0xFF971B3E);

  // TODO: replace with real data (Firestore) later
  static const List<DonorResponseItem> _responses = [
    DonorResponseItem(
      donorId: 'D-1042',
      status: DonorResponseStatus.accepted,
      units: '2 units',
    ),
    DonorResponseItem(
      donorId: 'D-1187',
      status: DonorResponseStatus.accepted,
      units: '1 unit',
    ),
    DonorResponseItem(
      donorId: 'D-0931',
      status: DonorResponseStatus.pending,
      units: '—',
    ),
    DonorResponseItem(
      donorId: 'D-1210',
      status: DonorResponseStatus.declined,
      units: '—',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  _buildSummaryCard(),

                  const SizedBox(height: 28),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Donor responses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: mainText,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  for (final item in _responses) _buildDonorCard(context, item),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          _buildBottomAction(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
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
            onTap: onBack,
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

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Response Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '$requestId • $bloodType • $unitsNeeded units',
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    final accepted = _responses
        .where((r) => r.status == DonorResponseStatus.accepted)
        .length;
    final declined = _responses
        .where((r) => r.status == DonorResponseStatus.declined)
        .length;

    // Static numbers from the design (6 of 8 notified, 3 pending).
    // Replace with real counts when data is connected.
    const notified = 6;
    const totalDonors = 8;
    const pending = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
        decoration: BoxDecoration(
          color: pinkCard,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFEAD6DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donors notified',
              style: TextStyle(fontSize: 14, color: secondaryText),
            ),

            const SizedBox(height: 5),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  '$notified',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                    height: 1.0,
                  ),
                ),
                SizedBox(width: 22),
                Text(
                  'of $totalDonors',
                  style: TextStyle(fontSize: 14, color: secondaryText),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              '$accepted accepted • $pending pending • $declined declined',
              style: const TextStyle(fontSize: 12, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DONOR CARD
  // ============================================================

  Widget _buildDonorCard(BuildContext context, DonorResponseItem item) {
  final color = _statusColor(item.status);

  return Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
    child: Material(
      color: whiteColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganisationDonorDetailsScreen(
                requestId: 'REQ-1048',
                donorId: item.donorId,
              ),
            ),
          );
        },
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  item.donorId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: 60,
                child: Text(
                  item.units,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: mainText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Color _statusColor(DonorResponseStatus status) {
    switch (status) {
      case DonorResponseStatus.accepted:
        return acceptedColor;
      case DonorResponseStatus.pending:
        return pendingColor;
      case DonorResponseStatus.declined:
        return declinedColor;
    }
  }

  String _statusLabel(DonorResponseStatus status) {
    switch (status) {
      case DonorResponseStatus.accepted:
        return 'Accepted';
      case DonorResponseStatus.pending:
        return 'Pending';
      case DonorResponseStatus.declined:
        return 'Declined';
    }
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onTrackResponders,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Track responders',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Contact is protected — communication stays in-app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: secondaryText),
          ),
        ],
      ),
    );
  }
}