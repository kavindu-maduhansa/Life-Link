import 'package:flutter/material.dart';

import '../../models/blood_request.dart';
import '../../services/coordinator_service.dart';
import 'organisation_requests_details_screen.dart';

class OrganisationRequestsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// Called when the user wants to jump to the donors tab from
  /// inside a request detail screen.
  final ValueChanged<BloodRequest>? onFindDonors;

  const OrganisationRequestsScreen({
    super.key,
    this.onBack,
    this.onFindDonors,
  });

  @override
  State<OrganisationRequestsScreen> createState() =>
      _OrganisationRequestsScreenState();
}

class _OrganisationRequestsScreenState
    extends State<OrganisationRequestsScreen> {
  // ============================================================
  // DESIGN COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color borderColor = Color(0xFFE6DADD);

  // ============================================================
  // DATA (live from Firestore)
  // ============================================================

  final CoordinatorService _service = CoordinatorService();

  // Created once so the stream is not re-subscribed on every rebuild.
  late final Stream<List<BloodRequest>> _requestsStream =
      _service.verifiedRequests();

  // ============================================================
  // SEARCH
  // ============================================================

  String searchQuery = '';

  List<BloodRequest> _filter(List<BloodRequest> requests) {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return requests;
    }

    return requests.where((r) {
      final fields = <String>[
        r.bloodGroup,
        r.hospitalName,
        r.location,
        r.urgency,
        r.ward ?? '',
        _shortId(r.id),
      ];
      return fields.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            color: backgroundColor,
            child: StreamBuilder<List<BloodRequest>>(
              stream: _requestsStream,
              builder: (context, snapshot) {
                final all = snapshot.data ?? const <BloodRequest>[];
                final hasError = snapshot.hasError;
                final loading = !snapshot.hasData && !hasError;
                final filtered = _filter(all);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(6, 39, 6, 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBox(),
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: mainText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryMaroon,
                            ),
                          ),
                        )
                      else if (hasError)
                        _buildMessageState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load requests',
                          message:
                              'Please check your connection and try again.',
                        )
                      else if (all.isEmpty)
                        _buildMessageState(
                          icon: Icons.inbox_outlined,
                          title: 'No verified requests',
                          message:
                              'Requests appear here once a hospital has '
                              'verified them.',
                        )
                      else if (filtered.isEmpty)
                        _buildMessageState(
                          icon: Icons.search_off_rounded,
                          title: 'No requests found',
                          message: 'Try searching with another keyword.',
                        )
                      else
                        ...filtered.map(
                          (request) => Padding(
                            padding: const EdgeInsets.only(bottom: 19),
                            child: _buildRequestCard(request),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
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
            onTap: widget.onBack,
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
                  'Verified Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Only hospital-verified requests',
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
  // SEARCH BOX
  // ============================================================

  Widget _buildSearchBox() {
    return Container(
      height: 56,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: const TextStyle(
          fontSize: 14,
          color: mainText,
        ),
        decoration: const InputDecoration(
          hintText: 'Search requests',
          hintStyle: TextStyle(
            fontSize: 14,
            color: secondaryText,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.search_rounded,
            size: 21,
            color: secondaryText,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(BloodRequest request) {
    Color urgencyColor;
    Color urgencyBackground;

    switch (request.urgency.toLowerCase()) {
      case 'critical':
      case 'urgent':
        urgencyColor = primaryMaroon;
        urgencyBackground = const Color(0xFFFCE8EC);
        break;

      case 'high':
        urgencyColor = const Color(0xFFD98200);
        urgencyBackground = const Color(0xFFFFF3DE);
        break;

      default:
        urgencyColor = const Color(0xFF008DA3);
        urgencyBackground = const Color(0xFFE3F6F8);
    }

    final unitsText =
        '${request.unitsNeeded} ${request.unitsNeeded == 1 ? 'unit' : 'units'}';
    final hasLocation = request.location.isNotEmpty && request.location != '-';
    final place = hasLocation
        ? '${request.hospitalName} • ${request.location}'
        : request.hospitalName;
    final remaining = _remainingLabel(request.requiredAt);

    // ==========================================================
    // CLICKABLE REQUEST CARD
    // ==========================================================

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return OrganisationRequestsDetailsScreen(
                requestId: request.id,
                onFindDonors: widget.onFindDonors,
              );
            },
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 13),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // URGENCY + REQUEST ID
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: urgencyColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    request.urgency.toUpperCase(),
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Text(
                  _shortId(request.id),
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            // ==================================================
            // BLOOD DETAILS + REMAINING TIME
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.bloodGroup} • $unitsText',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: mainText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place,
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (remaining != null) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        remaining.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryMaroon,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining.$2,
                        style: const TextStyle(
                          fontSize: 10,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Short, readable code for a request. The full Firestore document id
  /// is long, so only the first 6 characters are shown to the user.
  String _shortId(String id) {
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'REQ-${short.toUpperCase()}';
  }

  /// Time left until the blood is needed, or null when the request has
  /// no required-by time recorded (nothing is invented).
  (String, String)? _remainingLabel(DateTime? requiredAt) {
    if (requiredAt == null) return null;

    final diff = requiredAt.difference(DateTime.now());

    if (diff.isNegative) {
      return ('Overdue', 'past required time');
    }
    if (diff.inMinutes < 60) {
      return ('${diff.inMinutes} min', 'remaining');
    }
    if (diff.inHours < 24) {
      return ('${diff.inHours} h', 'remaining');
    }
    return ('${diff.inDays} d', 'remaining');
  }

  // ============================================================
  // EMPTY / ERROR STATES
  // ============================================================

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: secondaryText,
          ),
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
            style: const TextStyle(
              fontSize: 13,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}