import 'package:flutter/material.dart';
import 'organisation_send_donation_request_screen.dart';

class OrganisationDonorDetailsScreen extends StatelessWidget {
  final String requestId;
  final String donorId;
  final String bloodGroup;
  final String distanceText;
  final String lastDonation;
  final bool isAvailable;

  const OrganisationDonorDetailsScreen({
    super.key,
    this.requestId = 'REQ-1048',
    this.donorId = 'D-1042',
    this.bloodGroup = 'A+',
    this.distanceText = '2.1 km away',
    this.lastDonation = '4 months ago',
    this.isAvailable = true,
  });

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

  static const Color bloodRed = Color(0xFFD62839);
  static const Color successGreen = Color(0xFF1E7B4F);
  static const Color successBg = Color(0xFFDDF3E6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(6, 20, 6, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Why this donor matches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: mainText,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMatchCard(),
                    const SizedBox(height: 16),
                    _buildPrivacyCard(),
                    const SizedBox(height: 32),
                    _buildSendButton(context),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Donor Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$requestId Matched donor',
                style: const TextStyle(fontSize: 13, color: secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD (donor id, blood group, distance, last donation)
  // ============================================================

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donorId,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: mainText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      bloodGroup,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: bloodRed,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Blood group',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Last donation',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          ),

          // RIGHT column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvailabilityPill(),
              const SizedBox(height: 14),
              Text(
                distanceText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Location distance',
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
              const SizedBox(height: 10),
              Text(
                lastDonation,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityPill() {
    final Color bg = isAvailable ? successBg : const Color(0xFFEDEDED);
    final Color fg = isAvailable ? successGreen : secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }

  // ============================================================
  // WHY THIS DONOR MATCHES
  // ============================================================

  Widget _buildMatchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildMatchRow('Blood group matches request ($bloodGroup)'),
          const SizedBox(height: 18),
          _buildMatchRow('Within requested 10 km radius'),
          const SizedBox(height: 18),
          _buildMatchRow('Available for emergency donation'),
        ],
      ),
    );
  }

  Widget _buildMatchRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, size: 22, color: successGreen),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mainText,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRIVACY CARD
  // ============================================================

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: tealCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E1E1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact details protected',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: mainText,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Phone number is hidden. Use LifeLink to communicate.',
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEND DONATION REQUEST BUTTON
  // ============================================================

  Widget _buildSendButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganisationSendDonationRequestScreen(
                donorId: donorId,
                requestId: requestId,
                bloodGroup: bloodGroup,
                distanceText: distanceText.replaceAll(' away', ''),
                isAvailable: isAvailable,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Text(
          'Send Donation Request',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}