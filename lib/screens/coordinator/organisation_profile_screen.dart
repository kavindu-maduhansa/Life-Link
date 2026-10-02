import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganisationProfileScreen extends StatelessWidget {
  const OrganisationProfileScreen({super.key});

  // ============================================================
  // DESIGN COLORS (same as the Home screen)
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color successGreen = Color(0xFF1F7A4D);
  static const Color avatarBg = Color(0xFFDDE3EE);

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
                padding: const EdgeInsets.fromLTRB(6, 30, 6, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Organization details'),
                    const SizedBox(height: 14),
                    _buildDetailsCard(),

                    const SizedBox(height: 30),

                    _buildSectionTitle('Privacy & security'),
                    const SizedBox(height: 4),
                    _buildStatusRow('Role-based data access', 'Enabled'),
                    const SizedBox(height: 12),
                    _buildStatusRow('Emergency notifications', 'Enabled'),

                    const SizedBox(height: 14),

                    _buildSignOutButton(context),
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
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: pinkCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: primaryMaroon,
              ),
            ),
          ),

          const SizedBox(width: 18),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organization Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Account & privacy settings',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Edit icon (disabled look, as in the design)
          const Icon(
            Icons.edit_outlined,
            size: 20,
            color: Color(0xFFB9C0CB),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'O\nW',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: mainText,
                height: 1.0,
              ),
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BloodCare Sri Lanka',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Organization Coordinator',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Verified organization',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: successGreen,
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
  // ORGANIZATION DETAILS
  // ============================================================

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildDetailRow('Coordinator', 'Isiwara Wijesinghe'),
          const SizedBox(height: 22),
          _buildDetailRow('Organization ID', 'ORG-0248'),
          const SizedBox(height: 22),
          _buildDetailRow('Coverage area', 'Western Province'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 122,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
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
  // PRIVACY & SECURITY ROWS
  // ============================================================

  Widget _buildStatusRow(String title, String status) {
    return Container(
      width: double.infinity,
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: mainText,
              ),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: successGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => _signOut(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryMaroon,
          backgroundColor: whiteColor,
          elevation: 0,
          side: const BorderSide(color: primaryMaroon, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: const Text(
          'Sign out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);

    await FirebaseAuth.instance.signOut();

    // TODO: replace with your login screen, e.g.
    // navigator.pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => const LoginScreen()),
    //   (route) => false,
    // );
    navigator.popUntil((route) => route.isFirst);
  }
}