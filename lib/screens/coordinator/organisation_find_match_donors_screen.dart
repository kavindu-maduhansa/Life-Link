import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/blood_request.dart';
import '../../services/coordinator_service.dart';
import '../../utils/donor_availability.dart';

class OrganisationFindMatchDonorsScreen extends StatefulWidget {
  /// The verified request the coordinator is matching donors for.
  /// Null when the tab is opened without choosing a request first.
  final BloodRequest? selectedRequest;

  /// Back button. This screen lives inside the home IndexedStack, so
  /// "back" means returning to the Home tab, not popping a route.
  final VoidCallback? onBack;

  /// Called with a tab index when the user taps a nav item.
  /// Only used when this screen is embedded inside IndexedStack.
  final void Function(int)? onSwitchTab;

  const OrganisationFindMatchDonorsScreen({
    super.key,
    this.selectedRequest,
    this.onBack,
    this.onSwitchTab,
  });

  @override
  State<OrganisationFindMatchDonorsScreen> createState() =>
      _OrganisationFindMatchDonorsScreenState();
}

class _OrganisationFindMatchDonorsScreenState
    extends State<OrganisationFindMatchDonorsScreen> {
  // ============================================================
  // DESIGN COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color navyColor = Color(0xFF101A35);
  static const Color tealCard = Color(0xFFDDF3F3);
  static const Color pinkCard = Color(0xFFFCE8EC);

  // ============================================================
  // DATA
  // ============================================================

  final CoordinatorService _service = CoordinatorService();

  late final Stream<List<CoordinatorDonor>> _donorsStream =
      _service.donors();

  BloodRequest? _request;
  Stream<Map<String, String>>? _notifiedStream;

  /// Donor uids currently being notified (shows a spinner on the button).
  final Set<String> _sending = <String>{};

  // ============================================================
  // FILTER VALUES
  // ============================================================

  /// '' = default: compatible with the selected request, or any group
  /// when no request is selected.
  String selectedBloodType = '';

  /// '' = any location. Matches the donor's free-text location.
  String selectedLocation = '';

  /// Only donors who confirmed they are available. Off by default,
  /// because donors who signed up through the app have no availability
  /// field yet and would otherwise all be hidden.
  bool availableOnly = false;

  /// Lives as long as this screen. It must NOT be disposed when the
  /// filter dialog closes, because the dialog is still animating out
  /// (disposing early caused the red "_dependents.isEmpty" screen).
  final TextEditingController _locationController = TextEditingController();

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _setRequest(widget.selectedRequest);
  }

  @override
  void didUpdateWidget(covariant OrganisationFindMatchDonorsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.selectedRequest;
    if (next != null && next.id != oldWidget.selectedRequest?.id) {
      _setRequest(next);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  /// Sets the active request and resets the blood filter. Callers outside
  /// initState / didUpdateWidget wrap this in setState.
  void _setRequest(BloodRequest? request) {
    _request = request;
    _notifiedStream =
        request == null ? null : _service.notifiedDonors(request.id);
    selectedBloodType = '';
  }

  // ============================================================
  // FILTERING
  // ============================================================

  Set<String>? _allowedGroups() {
    if (selectedBloodType.isNotEmpty) return {selectedBloodType};
    final request = _request;
    if (request == null) return null;
    return BloodCompatibility.donorGroupsFor(request.bloodGroup);
  }

  List<CoordinatorDonor> _applyFilters(List<CoordinatorDonor> all) {
    final allowed = _allowedGroups();
    final location = selectedLocation.trim().toLowerCase();

    final list = all.where((donor) {
      if (!donor.isActive) return false;

      if (allowed != null && !allowed.contains(donor.bloodGroup)) {
        return false;
      }

      if (location.isNotEmpty &&
          !donor.location.toLowerCase().contains(location)) {
        return false;
      }

      if (availableOnly && !donor.availability.isConfirmedAvailable) {
        return false;
      }

      return true;
    }).toList();

    // Confirmed available first, then unknown, then unavailable.
    list.sort((a, b) {
      final byAvailability =
          a.availability.sortWeight.compareTo(b.availability.sortWeight);
      if (byAvailability != 0) return byAvailability;
      return a.code.compareTo(b.code);
    });

    return list;
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
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<CoordinatorDonor>>(
                stream: _donorsStream,
                builder: (context, donorSnapshot) {
                  if (donorSnapshot.hasError) {
                    return _buildCenterMessage(
                      'Could not load donors. Please check your connection '
                      'and try again.',
                    );
                  }
                  if (!donorSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryMaroon),
                    );
                  }

                  final all = donorSnapshot.data!;
                  final filtered = _applyFilters(all);

                  return StreamBuilder<Map<String, String>>(
                    stream: _notifiedStream,
                    builder: (context, notifiedSnapshot) {
                      final notified =
                          notifiedSnapshot.data ?? const <String, String>{};

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(6, 26, 6, 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRequestBanner(),
                            const SizedBox(height: 16),
                            _buildMatchingFilters(filtered.length),
                            const SizedBox(height: 19),
                            if (filtered.isEmpty)
                              _buildNoMatchingDonors(noDonorsAtAll: all.isEmpty)
                            else
                              ...filtered.map(
                                (donor) => Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _buildDonorCard(
                                    donor,
                                    notified[donor.uid],
                                  ),
                                ),
                              ),
                            if (filtered.isNotEmpty) _buildPrivacyCard(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: secondaryText),
        ),
      ),
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
          // ------------------------------------------------------
          // BACK BUTTON
          // ------------------------------------------------------

          GestureDetector(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
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

          // ------------------------------------------------------
          // TITLE
          // ------------------------------------------------------

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find & Match Donors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Search donors using your own filters',
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
  // REQUEST BANNER
  // ============================================================

  Widget _buildRequestBanner() {
    final request = _request;

    if (request == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(17, 14, 12, 14),
        decoration: BoxDecoration(
          color: tealCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8E1E1)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No request selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: mainText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Choose a verified request to notify donors.',
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _showRequestPicker,
              child: const Text(
                'Choose',
                style: TextStyle(
                  color: primaryMaroon,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final unitsText =
        '${request.unitsNeeded} ${request.unitsNeeded == 1 ? 'unit' : 'units'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 14, 12, 14),
      decoration: BoxDecoration(
        color: pinkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAD6DA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Matching donors for',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  '${request.bloodGroup} • $unitsText',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.hospitalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showRequestPicker,
            child: const Text(
              'Change',
              style: TextStyle(
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
  // REQUEST PICKER
  // ============================================================

  void _showRequestPicker() {
    // Created once per picker, so the sheet does not resubscribe
    // every time it rebuilds.
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
  // MATCHING FILTERS
  // ============================================================

  Widget _buildMatchingFilters(int count) {
    final request = _request;
    final usingCompatibility = selectedBloodType.isEmpty && request != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
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
          const Text(
            'Matching filters',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  selectedBloodType.isNotEmpty
                      ? selectedBloodType
                      : (request != null
                          ? '${request.bloodGroup} compatible'
                          : 'Any blood'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  selectedLocation.trim().isEmpty
                      ? 'Any location'
                      : selectedLocation.trim(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  availableOnly ? 'Available only' : 'All donors',
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count == 1
                    ? '1 matching donor found'
                    : '$count matching donors found',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: mainText,
                ),
              ),
              GestureDetector(
                onTap: _showFilterDialog,
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryMaroon,
                  ),
                ),
              ),
            ],
          ),

          if (usingCompatibility) ...[
            const SizedBox(height: 8),
            const Text(
              'Red-cell compatibility. The hospital confirms final '
              'compatibility.',
              style: TextStyle(fontSize: 11, color: secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _buildFilterChip(String text) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: navyColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ============================================================
  // DONOR CARD
  // ============================================================

  Widget _buildDonorCard(CoordinatorDonor donor, String? responseStatus) {
    final availability = donor.availability;

    Color badgeBackground;
    Color badgeBorder;
    Color badgeText;

    switch (availability) {
      case DonorAvailability.available:
        badgeBackground = const Color(0xFFDDF7E9);
        badgeBorder = const Color(0xFF22A866);
        badgeText = const Color(0xFF16824D);
        break;
      case DonorAvailability.unknown:
        badgeBackground = const Color(0xFFFFF3DE);
        badgeBorder = const Color(0xFFD98200);
        badgeText = const Color(0xFF9A5B00);
        break;
      case DonorAvailability.unavailable:
        badgeBackground = const Color(0xFFF1F1F1);
        badgeBorder = const Color(0xFF9CA3AF);
        badgeText = const Color(0xFF6B7280);
        break;
    }

    final alreadyNotified =
        responseStatus != null && responseStatus != 'declined';
    final sending = _sending.contains(donor.uid);
    final canNotify = !availability.isConfirmedUnavailable && !alreadyNotified;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // DONOR CIRCLE
          // ======================================================

          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: navyColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'D',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ======================================================
          // DONOR INFORMATION
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donor.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),

                const SizedBox(height: 6),

                // Availability badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badgeBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    availability.label,
                    style: TextStyle(
                      color: badgeText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _lastDonationText(donor.lastDonationDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ======================================================
          // LOCATION + BLOOD TYPE + NOTIFY
          // ======================================================

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  donor.location.isEmpty ? 'Location not set' : donor.location,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${donor.bloodGroup} blood',
                style: const TextStyle(
                  fontSize: 11,
                  color: secondaryText,
                ),
              ),

              const SizedBox(height: 13),

              SizedBox(
                width: 76,
                height: 30,
                child: ElevatedButton(
                  onPressed: (!canNotify || sending)
                      ? null
                      : () => _notifyDonor(donor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryMaroon,
                    disabledBackgroundColor: const Color(0xFFD5D5D5),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          alreadyNotified ? 'Notified' : 'Notify',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _lastDonationText(DateTime? date) {
    if (date == null) return 'No donation recorded';

    final days = DateTime.now().difference(date).inDays;
    if (days < 1) return 'Donated today';
    if (days < 30) return 'Last donation $days d ago';

    final months = days ~/ 30;
    if (months < 12) return 'Last donation $months mo ago';

    final years = months ~/ 12;
    return 'Last donation $years y ago';
  }

  // ============================================================
  // NOTIFY
  // ============================================================

    Future<void> _notifyDonor(CoordinatorDonor donor) async {
    final request = _request;

    if (request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a verified request first.')),
      );
      _showRequestPicker();
      return;
    }

    setState(() {
      _sending.add(donor.uid);
    });

    try {
      await _service.notifyDonor(request: request, donor: donor);
      if (!mounted) return;
      _showNotificationMessage();
    } on StateError {
      // Already contacted, or the session expired. The service message can
      // contain the donor's name, so a generic message is shown instead.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not send. This donor may already be contacted for this '
            'request, or you may need to sign in again.',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('notify donor failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send the request. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending.remove(donor.uid);
        });
      }
    }
  }

  // ============================================================
  // PRIVACY CARD
  // ============================================================

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
            'Privacy protected',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Names, phone numbers and unnecessary personal details are hidden.',
            style: TextStyle(
              fontSize: 11,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO MATCHING DONORS
  // ============================================================

  Widget _buildNoMatchingDonors({required bool noDonorsAtAll}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_rounded,
            size: 42,
            color: secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            noDonorsAtAll
                ? 'No donors registered yet'
                : 'No matching donors found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noDonorsAtAll
                ? 'Donor accounts will appear here once they sign up.'
                : 'Try changing your filters to find more donors.',
            textAlign: TextAlign.center,
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
  // FILTER POPUP
  // ============================================================

  void _showFilterDialog() {
    String temporaryBloodType = selectedBloodType;
    bool temporaryAvailableOnly = availableOnly;

    // Reuse the screen-level controller (disposed with the screen).
    _locationController.text = selectedLocation;

    final hasRequest = _request != null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Filter donors',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // BLOOD TYPE
                    // ==================================================

                    const Text(
                      'Blood type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mainText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: temporaryBloodType,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(
                                hasRequest
                                    ? 'Compatible with request'
                                    : 'Any blood type',
                              ),
                            ),
                            for (final group in const [
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'O+',
                              'O-',
                              'AB+',
                              'AB-',
                            ])
                              DropdownMenuItem(
                                value: group,
                                child: Text(group),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              temporaryBloodType = value;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // LOCATION
                    // ==================================================

                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mainText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _locationController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: mainText,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Colombo (leave empty for any)',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: secondaryText,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // AVAILABILITY
                    // ==================================================

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Available only',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: mainText,
                        ),
                      ),
                      subtitle: const Text(
                        'Only donors who marked themselves available',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryText,
                        ),
                      ),
                      activeThumbColor: primaryMaroon,
                      value: temporaryAvailableOnly,
                      onChanged: (value) {
                        setDialogState(() {
                          temporaryAvailableOnly = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ========================================================
              // ACTION BUTTONS
              // ========================================================

              actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              actions: [
                Row(
                  children: [
                    // RESET
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedBloodType = '';
                            selectedLocation = '';
                            availableOnly = false;
                          });

                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryMaroon,
                          side: const BorderSide(color: primaryMaroon),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // APPLY
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedBloodType = temporaryBloodType;
                            selectedLocation = _locationController.text.trim();
                            availableOnly = temporaryAvailableOnly;
                          });

                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // REQUEST SENT POP-UP
  // ============================================================

  void _showNotificationMessage() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Request Sent',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return SizedBox.expand(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Center(
              child: _buildNotificationSentCard(dialogContext),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildNotificationSentCard(BuildContext dialogContext) {
    const Color popupMaroon = Color(0xFF8B1538);
    const Color popupInk = Color(0xFF0F172A);
    const Color popupGrey = Color(0xFF64748B);
    const Color popupGreen = Color(0xFF12B981);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with halo rings
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF9F1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  color: Color(0xFFCFF3E1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: popupGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Request Sent',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: popupInk,
              ),
            ),

            const SizedBox(height: 14),
              const Text(
              'Invitation recorded. The donor can find this request under '
              'Requests in their LifeLink app and respond there. Answers '
              'appear in Response Tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: popupGrey,
              ),
            ),

            const SizedBox(height: 26),

            // Got it button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: popupMaroon.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: popupMaroon,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}