import 'package:flutter/material.dart';
import 'organisation_request_sent_screen.dart';

class OrganisationSendDonationRequestScreen extends StatefulWidget {
  final String requestId;
  final String donorId;
  final String bloodGroup;
  final int units;
  final String hospitalName;
  final String distanceText;
  final bool isUrgent;
  final bool isAvailable;

  const OrganisationSendDonationRequestScreen({
    super.key,
    this.requestId = 'REQ-1048',
    this.donorId = 'D-1042',
    this.bloodGroup = 'A+',
    this.units = 4,
    this.hospitalName = 'District General Hospital',
    this.distanceText = '2.1 km',
    this.isUrgent = true,
    this.isAvailable = true,
  });

  @override
  State<OrganisationSendDonationRequestScreen> createState() =>
      _OrganisationSendDonationRequestScreenState();
}

class _OrganisationSendDonationRequestScreenState
    extends State<OrganisationSendDonationRequestScreen> {
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
  static const Color tealButton = Color(0xFF0F7C86);
  static const Color borderColor = Color(0xFFE6DADD);

  static const Color urgentRed = Color(0xFFD62839);
  static const Color successGreen = Color(0xFF1E7B4F);

  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: 'A verified emergency blood request matches your blood group '
          'and availability. Would you be available to donate?',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(6, 20, 6, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Request summary'),
                    const SizedBox(height: 12),
                    _buildRequestSummaryCard(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('Donor selected'),
                    const SizedBox(height: 12),
                    _buildDonorSelectedCard(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('Message to donor'),
                    const SizedBox(height: 12),
                    _buildMessageCard(),
                    const SizedBox(height: 12),
                    _buildPrivacyCard(),
                    const SizedBox(height: 26),
                    _buildSendButton(context),
                    const SizedBox(height: 12),
                    _buildCancelButton(context),
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
                'Donation Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${widget.requestId} Protected communication',
                style: const TextStyle(fontSize: 13, color: secondaryText),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
  // REQUEST SUMMARY CARD
  // ============================================================

  Widget _buildRequestSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isUrgent) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: urgentRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'URGENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: whiteColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${widget.bloodGroup} • ${widget.units} units',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: mainText,
                  ),
                ),
              ),
              const Text(
                'Verified by hospital',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.hospitalName,
            style: const TextStyle(fontSize: 13, color: secondaryText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DONOR SELECTED CARD
  // ============================================================

  Widget _buildDonorSelectedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.donorId} • ${widget.bloodGroup}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.isAvailable ? 'Available now' : 'Unavailable'}'
                  ' • ${widget.distanceText}',
                  style: const TextStyle(fontSize: 13, color: secondaryText),
                ),
              ],
            ),
          ),
          const Text(
            'Phone hidden',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: successGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE TO DONOR
  // ============================================================

  Widget _buildMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: _cardDecoration(),
      child: TextField(
        controller: _messageController,
        maxLines: 4,
        minLines: 4,
        style: const TextStyle(
          fontSize: 14,
          height: 1.7,
          color: mainText,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Write a message to the donor',
          hintStyle: TextStyle(color: secondaryText),
        ),
      ),
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
        border: Border.all(color: tealBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your phone number is not shared.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: mainText,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Communication stays securely inside LifeLink.',
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildSendButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrganisationRequestSentScreen(
                requestId: widget.requestId,
                donorId: widget.donorId,
                bloodGroup: widget.bloodGroup,
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
          'Send Request',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.maybePop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: tealButton,
          backgroundColor: whiteColor,
          side: const BorderSide(color: tealButton, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ============================================================
  // SHARED CARD STYLE
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: whiteColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
    );
  }
}