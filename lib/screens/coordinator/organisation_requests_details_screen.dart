import 'package:flutter/material.dart';

class OrganisationRequestsDetailsScreen extends StatelessWidget {
  final String requestId;
  final String bloodType;
  final String units;
  final String hospital;
  final String ward;
  final String distance;
  final String urgency;
  final String neededBy;
  final String verificationSource;

  const OrganisationRequestsDetailsScreen({
    super.key,
    required this.requestId,
    required this.bloodType,
    required this.units,
    required this.hospital,
    required this.ward,
    required this.distance,
    required this.urgency,
    required this.neededBy,
    required this.verificationSource,
  });

  // ============================================================
  // DESIGN COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color tealCard = Color(0xFFDDF3F3);
  static const Color borderColor = Color(0xFFE6DADD);

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
                padding: const EdgeInsets.fromLTRB(6, 39, 6, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVerifiedRequestCard(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Coordination goal'),

                    const SizedBox(height: 10),

                    _buildCoordinationGoal(),

                    const SizedBox(height: 24),

                    _buildFindDonorsButton(context),

                    const SizedBox(height: 25),

                    _buildSectionTitle('Request information'),

                    const SizedBox(height: 10),

                    _buildRequestInformation(),
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
      padding: const EdgeInsets.fromLTRB(15, 14, 17, 14),
      decoration: const BoxDecoration(
        color: whiteColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: pinkCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: primaryMaroon,
                size: 25,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Request #REQ-1048 • Verified',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFIED REQUEST CARD
  // ============================================================

  Widget _buildVerifiedRequestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        17,
        17,
        17,
      ),
      decoration: BoxDecoration(
        color: pinkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAD6DA),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hospital verified badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE8EC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFDFA5B5),
                width: 1,
              ),
            ),
            child: const Text(
              'HOSPITAL VERIFIED',
              style: TextStyle(
                color: Color(0xFF9B4660),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Blood requirement
          Text(
            '$bloodType blood • $units',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: mainText,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          // Hospital
          Text(
            hospital,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),

          const SizedBox(height: 5),

          // Ward + distance
          Text(
            '$ward • $distance from you',
            style: const TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 13),

          // Verification source
          Text(
            'Verification source: $verificationSource',
            style: const TextStyle(
              fontSize: 12,
              color: secondaryText,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: mainText,
        ),
      ),
    );
  }

  // ============================================================
  // COORDINATION GOAL
  // ============================================================

  Widget _buildCoordinationGoal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        18,
        17,
        18,
      ),
      decoration: BoxDecoration(
        color: tealCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC8E1E1),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find suitable donors in your organization network.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: mainText,
            ),
          ),

          SizedBox(height: 9),

          Text(
            'Patient identity is hidden to protect privacy.',
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIND SUITABLE DONORS BUTTON
  // ============================================================

  Widget _buildFindDonorsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          // Find & Match Donors screen will be connected here next.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Find & Match Donors screen will be connected next.',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Find Suitable Donors',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REQUEST INFORMATION
  // ============================================================

  Widget _buildRequestInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        18,
        17,
        18,
      ),
      decoration: BoxDecoration(
        color: pinkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAD6DA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInformationRow(
            label: 'Urgency',
            value: urgency,
          ),

          const SizedBox(height: 13),

          _buildInformationRow(
            label: 'Needed by',
            value: neededBy,
          ),

          const SizedBox(height: 13),

          _buildInformationRow(
            label: 'Units still needed',
            value: units.replaceAll(' units', ''),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInformationRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: secondaryText,
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: mainText,
          ),
        ),
      ],
    );
  }
}