import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/blood_request.dart';
import '../../utils/donor_availability.dart';
import 'organisation_send_donation_request_screen.dart';
import '../../services/coordinator_service.dart';

class OrganisationDonorDetailsScreen extends StatefulWidget {
  /// Real Firestore request document ID.
  final String requestId;

  /// Real Firestore UID of the donor (used to fetch user doc + response doc).
  final String donorUid;

  /// Anonymous display code shown in the UI, e.g. "D-5CSP".
  final String donorCode;

  const OrganisationDonorDetailsScreen({
    super.key,
    required this.requestId,
    required this.donorUid,
    required this.donorCode,
  });

  @override
  State<OrganisationDonorDetailsScreen> createState() =>
      _OrganisationDonorDetailsScreenState();
}

class _OrganisationDonorDetailsScreenState
    extends State<OrganisationDonorDetailsScreen> {
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
  static const Color bloodRed = Color(0xFFD62839);
  static const Color successGreen = Color(0xFF1E7B4F);
  static const Color successBg = Color(0xFFDDF3E6);

  // ============================================================
  // DATA
  // ============================================================

  bool _loading = true;
  String? _error;

  // From users/{donorUid}
  String _bloodGroup = '-';
  String _location = '';
    DonorAvailability _availability = DonorAvailability.unknown;
  DateTime? _lastDonationDate;

  // From requests/{requestId}/responses where donorId == donorUid
  DonorResponseRecord? _response;

  // From requests/{requestId}
  BloodRequest? _request;

    // The donor as the coordinator module sees it (no phone, no email).
  CoordinatorDonor? _donor;

  @override
  void initState() {
    super.initState();
    _load();
  }

      Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Guard against being opened with missing IDs.
    if (widget.donorUid.isEmpty || widget.requestId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing donor or request information.';
      });
      return;
    }

    final db = FirebaseFirestore.instance;

    // Runs one read; on failure logs which one and returns null.
    Future<T?> guarded<T>(String label, Future<T> Function() run) async {
      try {
        return await run();
      } catch (e, st) {
        debugPrint('donor details: $label failed: $e\n$st');
        return null;
      }
    }

    // Start all three together so they still load in parallel.
    final userFuture = guarded(
      'users/${widget.donorUid}',
      () => db.collection('users').doc(widget.donorUid).get(),
    );
    final responseFuture = guarded(
      'requests/${widget.requestId}/responses',
      () => db
          .collection('requests')
          .doc(widget.requestId)
          .collection('responses')
          .get(),
    );
    final requestFuture = guarded(
      'requests/${widget.requestId}',
      () => db.collection('requests').doc(widget.requestId).get(),
    );

    final userDoc = await userFuture;
    final responsesSnap = await responseFuture;
    final requestDoc = await requestFuture;

    if (!mounted) return;

    // Without the donor document there is nothing useful to show.
    if (userDoc == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load donor details. Please try again.';
      });
      return;
    }

    // ---- donor fields ----
    final data = userDoc.data() ?? {};
    final last = data['lastDonationDate'];
    _bloodGroup =
        ((data['bloodGroup'] as String?) ?? '-').trim().toUpperCase();
    _location =
        (data['location'] is String) ? (data['location'] as String).trim() : '';
    _availability = DonorAvailabilityReader.read(data);
     _donor = CoordinatorDonor.fromDoc(userDoc);
    _lastDonationDate = last is Timestamp ? last.toDate() : null;

    // ---- response record (optional): this donor's own response only ----
        if (responsesSnap != null) {
      final mine = responsesSnap.docs
          .where((d) => d.data()['donorId'] == widget.donorUid)
          .map(DonorResponseRecord.fromDoc)
          .toList();
      final merged = CoordinatorService.mergeByDonor(mine);
      if (merged.isNotEmpty) {
        _response = merged.first;
      }
    }

    // ---- request (optional) ----
    if (requestDoc != null && requestDoc.exists) {
      _request = BloodRequest.fromDoc(requestDoc);
    }

    setState(() {
      _loading = false;
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Human-readable last donation label.
  String get _lastDonationText {
    final date = _lastDonationDate;
    if (date == null) return 'No record';
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
    final years = (months / 12).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }

  String get _shortRequestId {
    final id = widget.requestId;
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'REQ-${short.toUpperCase()}';
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
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryMaroon),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 40, color: secondaryText),
              const SizedBox(height: 12),
              Text(
                _error!.startsWith('[') || _error!.startsWith('Exception')
                    ? 'Could not load donor details. Please try again.'
                    : _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: secondaryText),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _load,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                      color: primaryMaroon, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(6, 20, 6, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 22),
          if (_response != null) ...[
            _buildResponseCard(_response!),
            const SizedBox(height: 22),
          ],
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
                '$_shortRequestId · Matched donor',
                style: const TextStyle(fontSize: 13, color: secondaryText),
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
                  widget.donorCode,
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
                      _bloodGroup,
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
              if (_location.isNotEmpty) ...[
                Text(
                  _location,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                _lastDonationText,
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
    final a = _availability;
    final Color bg;
    final Color fg;

    if (a.isConfirmedAvailable) {
      bg = successBg;
      fg = successGreen;
    } else if (a.isConfirmedUnavailable) {
      bg = const Color(0xFFEDEDED);
      fg = secondaryText;
    } else {
      bg = const Color(0xFFFFF3DE);
      fg = const Color(0xFF9A5B00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        a.label.toUpperCase(),
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
  // RESPONSE STATUS CARD
  // ============================================================

  Widget _buildResponseCard(DonorResponseRecord response) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (response.status) {
      case 'accepted':
      case 'completed':
        statusColor = successGreen;
        statusLabel = 'Accepted';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'declined':
        statusColor = bloodRed;
        statusLabel = 'Declined';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFFD98A1B);
        statusLabel = 'Pending response';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 22, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (response.respondedAt != null)
                  Text(
                    'Responded ${_formatDate(response.respondedAt!)}',
                    style: const TextStyle(
                        fontSize: 12, color: secondaryText),
                  )
                else if (response.notifiedAt != null)
                  Text(
                    'Notified ${_formatDate(response.notifiedAt!)}',
                    style: const TextStyle(
                        fontSize: 12, color: secondaryText),
                  ),
              ],
            ),
          ),
          Text(
            '${response.unitsPledged} ${response.unitsPledged == 1 ? 'unit' : 'units'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  // ============================================================
  // WHY THIS DONOR MATCHES
  // ============================================================

    Widget _buildMatchCard() {
    final request = _request;
    final a = _availability;

    // null = request or its blood group is unknown, so compatibility
    // can't be judged.
        final bool bloodKnown = _bloodGroup.isNotEmpty && _bloodGroup != '-';
    final groups = request == null
        ? null
        : BloodCompatibility.donorGroupsFor(request.bloodGroup);
    final bool? compatible =
        (groups == null || !bloodKnown) ? null : groups.contains(_bloodGroup);

    final String bloodText;
    if (!bloodKnown) {
      bloodText = 'Blood group not recorded. Compatibility cannot be checked.';
    } else if (request == null || compatible == null) {
      bloodText = 'Blood group $_bloodGroup';
    } else if (compatible) {
      bloodText = request.bloodGroup == _bloodGroup
          ? 'Blood group matches request ($_bloodGroup)'
          : 'Red-cell compatible with ${request.bloodGroup} request';
    } else {
      bloodText = 'Blood group $_bloodGroup is not compatible with '
          '${request.bloodGroup}';
    }

    final String availabilityText = a.isConfirmedAvailable
        ? 'Marked available for donation'
        : a.isConfirmedUnavailable
            ? 'Marked as unavailable — verify before relying on this donor'
            : 'Availability not confirmed — verify before relying on this donor';

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
          _buildMatchRow(bloodText, success: bloodKnown && compatible != false),
          const SizedBox(height: 18),
          _buildMatchRow(availabilityText, success: a.isConfirmedAvailable),
        ],
      ),
    );
  }

  Widget _buildMatchRow(String text, {bool success = true}) {
    return Row(
      children: [
        Icon(
          success ? Icons.check_rounded : Icons.info_outline_rounded,
          size: 22,
          color: success ? successGreen : const Color(0xFFD98A1B),
        ),
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
    final request = _request;
    final donor = _donor;

    // A donor who was already contacted (and has not declined) cannot be
    // contacted again for this request.
    final status = _response?.status;
    final alreadyContacted = status != null && status != 'declined';
    final canSend = request != null && donor != null && !alreadyContacted;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canSend
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrganisationSendDonationRequestScreen(
                      request: request,
                      donor: donor,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          disabledBackgroundColor: const Color(0xFFD5D5D5),
          foregroundColor: whiteColor,
          disabledForegroundColor: whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          (status == 'accepted' || status == 'completed')
              ? 'Donor already accepted this request'
              : alreadyContacted
                  ? 'Already contacted for this request'
                  : 'Send Donation Request',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
  }
