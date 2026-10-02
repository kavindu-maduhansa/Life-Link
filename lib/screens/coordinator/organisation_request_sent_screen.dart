import 'package:flutter/material.dart';
import 'organisation_home_screen.dart';

class OrganisationRequestSentScreen extends StatelessWidget {
  final String requestId;
  final String donorId;
  final String bloodGroup;

  const OrganisationRequestSentScreen({
    super.key,
    this.requestId = 'REQ-1048',
    this.donorId = 'D-1042',
    this.bloodGroup = 'A+',
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
  static const Color pinkBorder = Color(0xFFF3CCD5);
  static const Color tealCard = Color(0xFFDDF3F3);
  static const Color tealBorder = Color(0xFFC8E1E1);
  static const Color tealButton = Color(0xFF0F7C86);
  static const Color borderColor = Color(0xFFE6DADD);

  static const Color urgentRed = Color(0xFFD62839);
  static const Color successGreen = Color(0xFF1E7B4F);
  static const Color successBg = Color(0xFFE3F4EA);
  static const Color successBorder = Color(0xFFCBE6D6);

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
                    _buildSuccessCard(),
                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'What happens next?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: mainText,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNextStepsCard(),
                    const SizedBox(height: 32),
                    _buildTrackButton(context),
                    const SizedBox(height: 12),
                    _buildBackButton(context),
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
                'Request Sent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$requestId Donor notification',
                style: const TextStyle(fontSize: 13, color: secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS CARD
  // ============================================================

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 22),
      decoration: BoxDecoration(
        color: pinkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pinkBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_rounded, size: 56, color: successGreen),
          const SizedBox(height: 12),
          const Text(
            'Request sent successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: mainText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$donorId has been notified of the verified\n'
            '$bloodGroup emergency blood request.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: successBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: successBorder),
            ),
            child: const Text(
              'Phone number remains protected',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHAT HAPPENS NEXT
  // ============================================================

  Widget _buildNextStepsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        color: tealCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tealBorder),
      ),
      child: Column(
        children: [
          _buildStepRow('1', 'Donor receives an in-app notification'),
          const SizedBox(height: 18),
          _buildStepRow('2', 'Track the response from Response Tracking'),
          const SizedBox(height: 18),
          _buildStepRow('3', 'Message the donor without sharing phone numbers'),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: urgentRed,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mainText,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildTrackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          // TODO: replace with your Response Tracking screen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => const OrganisationResponseTrackingScreen(),
          //   ),
          // );
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
          'Track Response',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const OrganisationHomeScreen(initialIndex: 1),
            ),
            (route) => false,
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: tealButton,
          backgroundColor: whiteColor,
          side: const BorderSide(color: tealButton, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Text(
          'Back to Request',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}