import 'package:flutter/material.dart';

import '../../models/blood_request.dart';
import '../../services/coordinator_service.dart';
import 'organisation_request_sent_screen.dart';

class OrganisationSendDonationRequestScreen extends StatefulWidget {
  /// The verified request the donor is being asked to help with.
  final BloodRequest request;

  /// The donor being contacted (carries no phone number or email).
  final CoordinatorDonor donor;

  const OrganisationSendDonationRequestScreen({
    super.key,
    required this.request,
    required this.donor,
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

  final CoordinatorService _service = CoordinatorService();

  bool _sending = false;

  String get _shortRequestId {
    final id = widget.request.id;
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'REQ-${short.toUpperCase()}';
  }

  bool get _isUrgent =>
      widget.request.urgency == 'Critical' || widget.request.urgency == 'High';

  // ============================================================
  // SEND
  // ============================================================

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      await _service.notifyDonor(
        request: widget.request,
        donor: widget.donor,
      );
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrganisationRequestSentScreen(
            requestId: widget.request.id,
            donorId: widget.donor.code,
            bloodGroup: widget.donor.bloodGroup,
          ),
        ),
      );
    } on StateError {
      // Already notified, or the session expired. The service message can
      // contain the donor's name, so a generic message is shown instead.
      _showMessage(
        'Could not send. This donor may already be contacted for this '
        'request, or you may need to sign in again.',
      );
    } catch (e, st) {
      debugPrint('send donation request failed: $e\n$st');
      _showMessage('Could not send the request. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                    _buildSectionTitle('What happens next'),
                    const SizedBox(height: 12),
                    _buildNextStepCard(),
                    const SizedBox(height: 12),
                    _buildPrivacyCard(),
                    const SizedBox(height: 26),
                    _buildSendButton(),
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
                '$_shortRequestId · Protected communication',
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
    final request = widget.request;
    final units =
        '${request.unitsNeeded} ${request.unitsNeeded == 1 ? 'unit' : 'units'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isUrgent) ...[
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
                  '${request.bloodGroup} • $units',
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
            request.hospitalName,
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
    final donor = widget.donor;
    final location =
        donor.location.isEmpty ? 'Location not set' : donor.location;

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
                  '${donor.code} • ${donor.bloodGroup}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${donor.availability.label} • $location',
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
  // WHAT HAPPENS NEXT
  // ============================================================

  Widget _buildNextStepCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _cardDecoration(),
      child: const Text(
        'The invitation is recorded in LifeLink. The donor can find this '
        'request under Requests in their app and respond there. LifeLink '
        'does not send SMS, email or push messages.',
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: mainText,
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
            'Phone numbers stay hidden.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: mainText,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'The donor responds inside the LifeLink app.',
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _sending ? null : _send,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          disabledBackgroundColor: primaryMaroon.withValues(alpha: 0.6),
          foregroundColor: whiteColor,
          disabledForegroundColor: whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _sending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: whiteColor,
                ),
              )
            : const Text(
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
        onPressed: _sending ? null : () => Navigator.maybePop(context),
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