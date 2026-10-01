import 'dart:ui';
import 'package:flutter/material.dart';

class OrganisationFindMatchDonorsScreen extends StatefulWidget {
  /// Called with a tab index when the user taps a nav item.
  /// Only used when this screen is embedded inside IndexedStack.
  final void Function(int)? onSwitchTab;

  const OrganisationFindMatchDonorsScreen({
    super.key,
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

  // ============================================================
  // FILTER VALUES
  // ============================================================

  String selectedBloodType = '';
  String selectedLocation = 'Any distance';
  bool availableOnly = true;

  // ============================================================
  // TEMPORARY DONOR DATA
  //
  // Later this will come from your team's Firebase backend.
  // ============================================================

  final List<Map<String, dynamic>> donors = [
    {
      'id': 'D-1042',
      'distance': 2.1,
      'bloodType': 'A+',
      'lastDonation': 'Last donation 4 mo ago',
      'available': true,
    },
    {
      'id': 'D-1187',
      'distance': 4.8,
      'bloodType': 'A+',
      'lastDonation': 'Last donation 5 mo ago',
      'available': true,
    },
    {
      'id': 'D-0931',
      'distance': 7.2,
      'bloodType': 'A+',
      'lastDonation': 'Last donation 3 mo ago',
      'available': true,
    },
    {
      'id': 'D-1265',
      'distance': 9.4,
      'bloodType': 'A+',
      'lastDonation': 'Last donation 6 mo ago',
      'available': false,
    },
    {
      'id': 'D-1458',
      'distance': 12.5,
      'bloodType': 'A+',
      'lastDonation': 'Last donation 4 mo ago',
      'available': true,
    },
    {
      'id': 'D-1521',
      'distance': 16.8,
      'bloodType': 'A+',
      'lastDonation': 'Last donation 7 mo ago',
      'available': true,
    },
    {
      'id': 'D-1674',
      'distance': 21.3,
      'bloodType': 'A+',
      'lastDonation': 'Last donation 5 mo ago',
      'available': true,
    },
    {
      'id': 'D-1789',
      'distance': 3.6,
      'bloodType': 'O+',
      'lastDonation': 'Last donation 4 mo ago',
      'available': true,
    },
    {
      'id': 'D-1822',
      'distance': 6.7,
      'bloodType': 'B+',
      'lastDonation': 'Last donation 5 mo ago',
      'available': true,
    },
    {
      'id': 'D-1934',
      'distance': 11.2,
      'bloodType': 'AB+',
      'lastDonation': 'Last donation 6 mo ago',
      'available': false,
    },
  ];

  // ============================================================
  // FILTERED DONORS
  // ============================================================

  List<Map<String, dynamic>> get filteredDonors {
    return donors.where((donor) {
      // ----------------------------------------------------------
      // Blood type
      // ----------------------------------------------------------

      final bloodTypeMatches = selectedBloodType.isEmpty ||
          donor['bloodType'] == selectedBloodType;

      // ----------------------------------------------------------
      // Location
      // ----------------------------------------------------------

      final double distance = donor['distance'];

      bool locationMatches = true;

      switch (selectedLocation) {
        case 'Within 5 km':
          locationMatches = distance <= 5;
          break;

        case 'Within 10 km':
          locationMatches = distance <= 10;
          break;

        case 'Within 20 km':
          locationMatches = distance <= 20;
          break;

        case 'Any distance':
        default:
          locationMatches = true;
      }

      // ----------------------------------------------------------
      // Availability
      // ----------------------------------------------------------

      final availabilityMatches =
          !availableOnly || donor['available'] == true;

      return bloodTypeMatches &&
          locationMatches &&
          availabilityMatches;
    }).toList();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    // No request details are used here.
    // The organisation manually selects the donor filters.
    selectedBloodType = '';
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(6, 40, 6, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMatchingFilters(),

                    const SizedBox(height: 19),

                    if (filteredDonors.isEmpty)
                      _buildNoMatchingDonors()
                    else
                      ...filteredDonors.map(
                        (donor) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _buildDonorCard(donor),
                        ),
                      ),

                    if (filteredDonors.isNotEmpty) _buildPrivacyCard(),
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
          // KEPT AS YOUR ORIGINAL CODE
          // ------------------------------------------------------

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8EC),
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
  // MATCHING FILTERS
  // ============================================================

  Widget _buildMatchingFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        17,
        17,
        16,
      ),
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
                  selectedBloodType.isEmpty
                      ? 'Any blood'
                      : selectedBloodType,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildFilterChip(
                  _getLocationShortText(),
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildFilterChip(
                  availableOnly ? 'Available now' : 'All donors',
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredDonors.length} matching donors found',
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
  // LOCATION SHORT TEXT
  // ============================================================

  String _getLocationShortText() {
    switch (selectedLocation) {
      case 'Within 5 km':
        return '≤ 5 km';

      case 'Within 10 km':
        return '≤ 10 km';

      case 'Within 20 km':
        return '≤ 20 km';

      default:
        return 'Location';
    }
  }

  // ============================================================
  // DONOR CARD
  // ============================================================

  Widget _buildDonorCard(Map<String, dynamic> donor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        16,
        17,
        16,
      ),
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
                  donor['id'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),

                const SizedBox(height: 6),

                // Available badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: donor['available']
                        ? const Color(0xFFDDF7E9)
                        : const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: donor['available']
                          ? const Color(0xFF22A866)
                          : const Color(0xFF9CA3AF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    donor['available']
                        ? 'Available'
                        : 'Unavailable',
                    style: TextStyle(
                      color: donor['available']
                          ? const Color(0xFF16824D)
                          : const Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  donor['lastDonation'],
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
          // DISTANCE + BLOOD TYPE + NOTIFY
          // ======================================================

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${donor['distance'].toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mainText,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${donor['bloodType']} blood',
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
                  onPressed: donor['available']
                      ? () {
                          _showNotificationMessage(
                            donor['id'],
                          );
                        }
                      : null,
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
                  child: const Text(
                    'Notify',
                    style: TextStyle(
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

  // ============================================================
  // PRIVACY CARD
  // ============================================================

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        12,
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
            'Privacy protected',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Phone numbers and unnecessary personal details are hidden.',
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

  Widget _buildNoMatchingDonors() {
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
      child: const Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 42,
            color: secondaryText,
          ),

          SizedBox(height: 12),

          Text(
            'No matching donors found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Try changing your filters to find more donors.',
            textAlign: TextAlign.center,
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
  // FILTER POPUP
  // ============================================================

  void _showFilterDialog() {
    String temporaryBloodType = selectedBloodType;
    String temporaryLocation = selectedLocation;
    bool temporaryAvailableOnly = availableOnly;

    showDialog(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: temporaryBloodType.isEmpty
                              ? null
                              : temporaryBloodType,
                          hint: const Text('Any blood type'),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'A+',
                              child: Text('A+'),
                            ),
                            DropdownMenuItem(
                              value: 'A-',
                              child: Text('A-'),
                            ),
                            DropdownMenuItem(
                              value: 'B+',
                              child: Text('B+'),
                            ),
                            DropdownMenuItem(
                              value: 'B-',
                              child: Text('B-'),
                            ),
                            DropdownMenuItem(
                              value: 'O+',
                              child: Text('O+'),
                            ),
                            DropdownMenuItem(
                              value: 'O-',
                              child: Text('O-'),
                            ),
                            DropdownMenuItem(
                              value: 'AB+',
                              child: Text('AB+'),
                            ),
                            DropdownMenuItem(
                              value: 'AB-',
                              child: Text('AB-'),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: temporaryLocation,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'Any distance',
                              child: Text('Any distance'),
                            ),
                            DropdownMenuItem(
                              value: 'Within 5 km',
                              child: Text('Within 5 km'),
                            ),
                            DropdownMenuItem(
                              value: 'Within 10 km',
                              child: Text('Within 10 km'),
                            ),
                            DropdownMenuItem(
                              value: 'Within 20 km',
                              child: Text('Within 20 km'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              temporaryLocation = value;
                            });
                          },
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
                        'Available now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: mainText,
                        ),
                      ),
                      subtitle: const Text(
                        'Show only donors currently available',
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

              actionsPadding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                18,
              ),

              actions: [
                Row(
                  children: [
                    // RESET
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedBloodType = '';
                            selectedLocation = 'Any distance';
                            availableOnly = true;
                          });

                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryMaroon,
                          side: const BorderSide(
                            color: primaryMaroon,
                          ),
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
                            selectedBloodType =
                                temporaryBloodType;
                            selectedLocation =
                                temporaryLocation;
                            availableOnly =
                                temporaryAvailableOnly;
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
  // NOTIFY POP-UP
  // ============================================================

  void _showNotificationMessage(String donorId) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notification Sent',
      barrierColor: Colors.black.withOpacity(0.12),
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
              color: Colors.black.withOpacity(0.12),
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
              'Notification Sent',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: popupInk,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'The selected donors have been notified successfully about your request.',
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
                    color: popupMaroon.withOpacity(0.28),
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