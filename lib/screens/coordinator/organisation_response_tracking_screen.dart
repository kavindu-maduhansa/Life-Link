import 'package:flutter/material.dart';

import '../../models/blood_request.dart';
import '../../services/coordinator_service.dart';
import 'organisation_donor_details_screen.dart';

enum DonorResponseStatus { accepted, pending, declined }

class DonorResponseItem {
  final String donorId;   // anonymous display code, e.g. "D-5CSP"
  final String donorUid;  // real Firestore UID, used to fetch details
  final DonorResponseStatus status;
  final String units;

  const DonorResponseItem({
    required this.donorId,
    required this.donorUid,
    required this.status,
    required this.units,
  });
}

class OrganisationResponseTrackingScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onTrackResponders;

  /// The request to track. When null, the most urgent verified request
  /// is picked automatically and the coordinator can change it.
  final BloodRequest? selectedRequest;

  const OrganisationResponseTrackingScreen({
    super.key,
    this.onBack,
    this.onTrackResponders,
    this.selectedRequest,
  });

  @override
  State<OrganisationResponseTrackingScreen> createState() =>
      _OrganisationResponseTrackingScreenState();
}

class _OrganisationResponseTrackingScreenState
    extends State<OrganisationResponseTrackingScreen> {
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

  // ============================================================
  // DATA (live from Firestore)
  // ============================================================

  final CoordinatorService _service = CoordinatorService();

  BloodRequest? _request;
  Stream<List<DonorResponseRecord>>? _responsesStream;

  /// True while the most urgent request is being picked automatically.
  bool _autoSelecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedRequest != null) {
      _setRequest(widget.selectedRequest);
    } else {
      _autoSelectMostUrgent();
    }
  }

  @override
  void didUpdateWidget(
      covariant OrganisationResponseTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.selectedRequest;
    if (next != null && next.id != oldWidget.selectedRequest?.id) {
      _setRequest(next);
    }
  }

  /// Sets the active request. Callers outside initState / didUpdateWidget
  /// wrap this in setState.
  void _setRequest(BloodRequest? request) {
    _request = request;
    _responsesStream =
        request == null ? null : _service.responses(request.id);
  }

  Future<void> _autoSelectMostUrgent() async {
    setState(() {
      _autoSelecting = true;
    });

    try {
      final list = await _service.verifiedRequests().first;
      if (!mounted) return;
      if (_request == null && list.isNotEmpty) {
        setState(() {
          _setRequest(list.first);
        });
      }
    } catch (_) {
      // Falls through to the "choose a request" state.
    } finally {
      if (mounted) {
        setState(() {
          _autoSelecting = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_autoSelecting) {
      return const Center(
        child: CircularProgressIndicator(color: primaryMaroon),
      );
    }

    final request = _request;
    final stream = _responsesStream;

    if (request == null || stream == null) {
      return _buildMessageState(
        icon: Icons.inbox_outlined,
        title: 'No request selected',
        message: 'Choose a verified request to see donor responses.',
        action: TextButton(
          onPressed: _showRequestPicker,
          child: const Text(
            'Choose a request',
            style: TextStyle(
              color: primaryMaroon,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<DonorResponseRecord>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMessageState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load responses',
            message: 'Please check your connection and try again.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: primaryMaroon),
          );
        }

        final records =
        _sorted(CoordinatorService.mergeByDonor(snapshot.data!));
        final items = records.map(_toItem).toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSummaryCard(request, records, items),
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
              if (items.isEmpty)
                _buildMessageCard(
                  'No donors have been notified for this request yet. '
                  'Use Find donors to notify matching donors.',
                )
              else
                for (final item in items) _buildDonorCard(context, item),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MAPPING
  // ============================================================

  /// Accepted first, then pending, then declined; newest first inside
  /// each group.
  List<DonorResponseRecord> _sorted(List<DonorResponseRecord> records) {
    int weight(DonorResponseRecord r) {
      switch (r.status) {
        case 'accepted':
        case 'completed':
          return 0;
        case 'declined':
        case 'withdrawn':
          return 2;
        default:
          return 1;
      }
    }

    DateTime stamp(DonorResponseRecord r) =>
        r.respondedAt ??
        r.notifiedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final list = List<DonorResponseRecord>.from(records);
    list.sort((a, b) {
      final byWeight = weight(a).compareTo(weight(b));
      if (byWeight != 0) return byWeight;
      return stamp(b).compareTo(stamp(a));
    });
    return list;
  }

  DonorResponseItem _toItem(DonorResponseRecord r) {
    final DonorResponseStatus status;
    switch (r.status) {
      case 'accepted':
      case 'completed':
        status = DonorResponseStatus.accepted;
        break;
      case 'declined':
      case 'withdrawn':
        status = DonorResponseStatus.declined;
        break;
      default:
        status = DonorResponseStatus.pending;
    }

    final units = status == DonorResponseStatus.accepted
        ? '${r.unitsPledged} ${r.unitsPledged == 1 ? 'unit' : 'units'}'
        : '—';

    return DonorResponseItem(
      donorId: _donorCode(r.donorId),
      donorUid: r.donorId,
      status: status,
      units: units,
    );
  }

  /// Anonymous display code, same format as the Find Donors screen.
  /// Donor names and phone numbers are never shown here.
  String _donorCode(String uid) {
    final short = uid.length >= 4 ? uid.substring(0, 4) : uid;
    return 'D-${short.toUpperCase()}';
  }

  String _shortId(String id) {
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'REQ-${short.toUpperCase()}';
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final request = _request;

    final subtitle = request == null
        ? 'Choose a request'
        : '${_shortId(request.id)} • ${request.bloodGroup} • '
            '${request.unitsNeeded} ${request.unitsNeeded == 1 ? 'unit' : 'units'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 13, 10, 14),
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
            onTap: widget.onBack,
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
          Expanded(
            child: Column(
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
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showRequestPicker,
            child: Text(
              request == null ? 'Choose' : 'Change',
              style: const TextStyle(
                color: primaryMaroon,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard(
    BloodRequest request,
    List<DonorResponseRecord> records,
    List<DonorResponseItem> items,
  ) {
    final accepted =
        items.where((i) => i.status == DonorResponseStatus.accepted).length;
    final pending =
        items.where((i) => i.status == DonorResponseStatus.pending).length;
    final declined =
        items.where((i) => i.status == DonorResponseStatus.declined).length;

    final notified = items.length;

    final unitsPledged = records
        .where((r) => r.status == 'accepted' || r.status == 'completed')
        .fold<int>(0, (sum, r) => sum + r.unitsPledged);

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
              children: [
                Text(
                  '$notified',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 22),
                Text(
                  '$unitsPledged of ${request.unitsNeeded} units pledged',
                  style: const TextStyle(fontSize: 14, color: secondaryText),
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
    final request = _request;

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
                  requestId: request?.id ?? '',
                  donorUid: item.donorUid,
                  donorCode: item.donorId,
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
                    textAlign: TextAlign.right,
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
  // EMPTY / ERROR STATES
  // ============================================================

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

  Widget _buildMessageCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: secondaryText,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REQUEST PICKER
  // ============================================================

  void _showRequestPicker() {
    // Created once per picker so the sheet does not resubscribe on rebuild.
    final requestsStream = _service.verifiedRequests();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StreamBuilder<List<BloodRequest>>(
            stream: requestsStream,
            builder: (context, snapshot) {
              Widget content;

              if (snapshot.hasError) {
                content = const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load requests.',
                    style: TextStyle(color: secondaryText),
                  ),
                );
              } else if (!snapshot.hasData) {
                content = const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: primaryMaroon),
                );
              } else if (snapshot.data!.isEmpty) {
                content = const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No verified requests right now.',
                    style: TextStyle(color: secondaryText),
                  ),
                );
              } else {
                final requests = snapshot.data!;
                content = ListView.separated(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final r = requests[index];
                    return ListTile(
                      title: Text(
                        '${r.bloodGroup} • ${r.unitsNeeded} '
                        '${r.unitsNeeded == 1 ? 'unit' : 'units'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: mainText,
                        ),
                      ),
                      subtitle: Text(
                        '${r.hospitalName} • ${r.urgency}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: secondaryText,
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        setState(() {
                          _setRequest(r);
                        });
                      },
                    );
                  },
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'Choose a verified request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: mainText,
                      ),
                    ),
                  ),
                  Flexible(child: content),
                ],
              );
            },
          ),
        );
      },
    );
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
              onPressed: widget.onTrackResponders,
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