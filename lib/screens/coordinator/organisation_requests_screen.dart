import 'package:flutter/material.dart';
import 'organisation_requests_details_screen.dart';

class OrganisationRequestsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// Called when the user wants to jump to the donors tab from
  /// inside a request detail screen.
  final VoidCallback? onFindDonors;

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
  // SEARCH
  // ============================================================

  String searchQuery = '';

  // ============================================================
  // TEMPORARY SAMPLE REQUESTS
  // Later we will replace these with Firestore data.
  // ============================================================

  final List<Map<String, String>> requests = [
    {
      'urgency': 'URGENT',
      'bloodType': 'A+',
      'units': '4 units',
      'hospital': 'District General Hospital',
      'distance': '6.2 km',
      'requestId': 'REQ-1048',
      'remaining': '12 min',
      'urgencyType': 'urgent',
    },
    {
      'urgency': 'HIGH',
      'bloodType': 'O-',
      'units': '2 units',
      'hospital': 'Teaching Hospital',
      'distance': '8.4 km',
      'requestId': 'REQ-1049',
      'remaining': '1 hr',
      'urgencyType': 'high',
    },
    {
      'urgency': 'NORMAL',
      'bloodType': 'B+',
      'units': '3 units',
      'hospital': 'Base Hospital',
      'distance': '11 km',
      'requestId': 'REQ-1050',
      'remaining': 'Today',
      'urgencyType': 'normal',
    },
  ];

  // ============================================================
  // FILTER REQUESTS
  // ============================================================

  List<Map<String, String>> get filteredRequests {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return requests;
    }

    return requests.where((request) {
      return request.values.any(
        (value) => value.toLowerCase().contains(query),
      );
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
            child: SingleChildScrollView(
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

                  if (filteredRequests.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredRequests.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 19),
                        child: _buildRequestCard(request),
                      ),
                    ),
                ],
              ),
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

  Widget _buildRequestCard(Map<String, String> request) {
    final urgencyType = request['urgencyType']!;

    Color urgencyColor;
    Color urgencyBackground;

    switch (urgencyType) {
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
                requestId: request['requestId']!,
                bloodType: request['bloodType']!,
                units: request['units']!,
                hospital: request['hospital']!,
                ward: 'Emergency Ward',
                distance: request['distance']!,
                urgency: _formatUrgency(request['urgency']!),
                neededBy: request['remaining'] == '12 min'
                    ? '8:30 PM'
                    : request['remaining']!,
                verificationSource: 'Blood Bank Officer',
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
                    request['urgency']!,
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                Text(
                  request['requestId']!,
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
                        '${request['bloodType']} • ${request['units']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: mainText,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '${request['hospital']} • ${request['distance']}',
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

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      request['remaining']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryMaroon,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'remaining',
                      style: TextStyle(
                        fontSize: 10,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT URGENCY
  // ============================================================

  String _formatUrgency(String urgency) {
    switch (urgency) {
      case 'URGENT':
        return 'Urgent';

      case 'HIGH':
        return 'High';

      case 'NORMAL':
        return 'Normal';

      default:
        return urgency;
    }
  }

  // ============================================================
  // EMPTY SEARCH RESULT
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: secondaryText,
          ),

          SizedBox(height: 12),

          Text(
            'No requests found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainText,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Try searching with another keyword.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}