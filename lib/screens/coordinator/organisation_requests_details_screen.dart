import 'package:flutter/material.dart';

import '../../models/blood_request.dart';
import '../../services/coordinator_service.dart';

class OrganisationRequestsDetailsScreen extends StatefulWidget {
  /// The real Firestore document id of the request (not the short code).
  final String requestId;

  /// Called with this request when the user taps "Find Suitable Donors".
  /// The caller should switch the parent tab to the donors tab.
  final ValueChanged<BloodRequest>? onFindDonors;

  const OrganisationRequestsDetailsScreen({
    super.key,
    required this.requestId,
    this.onFindDonors,
  });

  @override
  State<OrganisationRequestsDetailsScreen> createState() =>
      _OrganisationRequestsDetailsScreenState();
}

class _OrganisationRequestsDetailsScreenState
    extends State<OrganisationRequestsDetailsScreen> {
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

  // ============================================================
  // DATA (live, so counts update while the screen is open)
  // ============================================================

  final CoordinatorService _service = CoordinatorService();

  late final Stream<BloodRequest?> _requestStream =
      _service.request(widget.requestId);
  late final Stream<List<DonorResponseRecord>> _responsesStream =
      _service.responses(widget.requestId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<BloodRequest?>(
          stream: _requestStream,
          builder: (context, snapshot) {
            final request = snapshot.data;
            final hasError = snapshot.hasError;
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

            return Column(
              children: [
                _buildHeader(context, request),
                Expanded(
                  child: _buildBody(
                    request: request,
                    loading: loading,
                    hasError: hasError,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required BloodRequest? request,
    required bool loading,
    required bool hasError,
  }) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryMaroon),
      );
    }

    if (hasError) {
      return _buildMessage('Could not load this request. Please try again.');
    }

    if (request == null) {
      return _buildMessage('This request is no longer available.');
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(6, 39, 6, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerifiedRequestCard(request),
          const SizedBox(height: 24),
          _buildSectionTitle('Coordination goal'),
          const SizedBox(height: 10),
          _buildCoordinationGoal(),
          const SizedBox(height: 24),
          _buildFindDonorsButton(context, request),
          const SizedBox(height: 25),
          _buildSectionTitle('Request information'),
          const SizedBox(height: 10),
                    StreamBuilder<List<DonorResponseRecord>>(
            stream: _responsesStream,
            builder: (context, snapshot) {
              var accepted = request.donorsAcceptedCount;
              var remaining = request.unitsRemaining;

              final data = snapshot.data;
              if (data != null) {
                final yes = CoordinatorService.mergeByDonor(data)
                    .where((r) =>
                        r.status == 'accepted' || r.status == 'completed')
                    .toList();
                final pledged =
                    yes.fold<int>(0, (sum, r) => sum + r.unitsPledged);
                accepted = yes.length;
                remaining = pledged >= request.unitsNeeded
                    ? 0
                    : request.unitsNeeded - pledged;
              }

              return _buildRequestInformation(
                request,
                acceptedCount: accepted,
                unitsRemaining: remaining,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: secondaryText,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context, BloodRequest? request) {
    final subtitle = request == null
        ? 'Request details'
        : '${_shortId(request.id)} • Verified';

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verified Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
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

  Widget _buildVerifiedRequestCard(BloodRequest r) {
    final hasLocation = r.location.isNotEmpty && r.location != '-';
    final wardLine = [
      r.ward ?? 'Ward not recorded',
      if (hasLocation) r.location,
    ].join(' • ');

    final unitsText = '${r.unitsNeeded} ${r.unitsNeeded == 1 ? 'unit' : 'units'}';

    final verifiedAt = r.verifiedAt;
    final verificationLine = verifiedAt != null
        ? 'Verified by hospital / blood bank • ${_formatDateTime(verifiedAt)}'
        : 'Verified by hospital / blood bank';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
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
            '${r.bloodGroup} blood • $unitsText',
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
            r.hospitalName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),

          const SizedBox(height: 5),

          // Ward + location
          Text(
            wardLine,
            style: const TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 13),

          // Verification source
          Text(
            verificationLine,
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
      padding: const EdgeInsets.all(17),
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

  Widget _buildFindDonorsButton(BuildContext context, BloodRequest request) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          if (widget.onFindDonors != null) {
            // Pop back to the requests screen, then switch the
            // parent IndexedStack to the donors tab.
            Navigator.pop(context);
            widget.onFindDonors!(request);
          }
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

    Widget _buildRequestInformation(
    BloodRequest r, {
    required int acceptedCount,
    required int unitsRemaining,
  }) {
    final neededBy =
        r.requiredAt != null ? _formatDateTime(r.requiredAt!) : 'Not recorded';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
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
            value: r.urgency,
          ),
          const SizedBox(height: 13),
          _buildInformationRow(
            label: 'Needed by',
            value: neededBy,
          ),
          const SizedBox(height: 13),
          _buildInformationRow(
            label: 'Units still needed',
            value: '$unitsRemaining',
          ),
          const SizedBox(height: 13),
          _buildInformationRow(
            label: 'Donors accepted',
            value: '$acceptedCount',
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: mainText,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Short readable code (first 6 characters of the Firestore id).
  String _shortId(String id) {
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'REQ-${short.toUpperCase()}';
  }

  /// e.g. "Today, 8:30 PM" or "4 Oct, 8:30 PM".
  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour12:$minute $period';

    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) return 'Today, $time';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]}, $time';
  }
}