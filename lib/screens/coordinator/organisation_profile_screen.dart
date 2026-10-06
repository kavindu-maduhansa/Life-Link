import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganisationProfileScreen extends StatefulWidget {
  const OrganisationProfileScreen({super.key});

  @override
  State<OrganisationProfileScreen> createState() =>
      _OrganisationProfileScreenState();
}

class _OrganisationProfileScreenState
    extends State<OrganisationProfileScreen> {
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
  static const Color successGreen = Color(0xFF1F7A4D);
  static const Color avatarBg = Color(0xFFDDE3EE);

  // ============================================================
  // EDIT CONTROLLERS
  // ============================================================

  final TextEditingController _fullNameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _controllersLoaded = false;

  // ============================================================
  // CURRENT USER DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>>? get _userDocument {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.fromLTRB(6, 30, 6, 30),
                child: _buildProfileContent(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isEditing) {
                _cancelEditing();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Icon(
                _isEditing
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: mainText,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Edit Profile'
                      : 'Organization Profile',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isEditing
                      ? 'Update your account information'
                      : 'Account & privacy settings',
                  style: const TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),

          if (!_isEditing)
            GestureDetector(
              onTap: _startEditing,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: pinkCard,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: primaryMaroon,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CONTENT
  // ============================================================

  Widget _buildProfileContent() {
    final userDocument = _userDocument;

    if (userDocument == null) {
      return const Center(
        child: Text(
          'No signed-in user found.',
          style: TextStyle(
            color: secondaryText,
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocument.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        final data = snapshot.data?.data() ?? {};

        final String fullName =
            _readString(data['fullName']);

        final String email =
            _readString(data['email']);

        final String phoneNumber =
            _readString(data['phoneNumber']);

        final String role =
            _readString(data['role']);

        final bool isActive =
            data['isActive'] == true;

        // Load the editable fields only once.
        if (!_controllersLoaded) {
          _fullNameController.text =
              fullName == 'Not recorded' ? '' : fullName;

          _phoneController.text =
              phoneNumber == 'Not recorded' ? '' : phoneNumber;

          _controllersLoaded = true;
        }

        if (_isEditing) {
          return _buildEditContent(
            email: email,
            role: role,
            isActive: isActive,
          );
        }

        return _buildViewContent(
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
          isActive: isActive,
        );
      },
    );
  }

  // ============================================================
  // NORMAL VIEW
  // ============================================================

  Widget _buildViewContent({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileCard(
          fullName: fullName,
          role: role,
          isActive: isActive,
        ),

        const SizedBox(height: 28),

        _buildSectionTitle('Organization details'),

        const SizedBox(height: 14),

        _buildDetailsCard(
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
          isActive: isActive,
        ),

        const SizedBox(height: 30),

        _buildSectionTitle('Privacy & security'),

        const SizedBox(height: 4),

        _buildStatusRow(
          'Role-based data access',
          'Enabled',
        ),

        const SizedBox(height: 12),

        _buildStatusRow(
          'Emergency request access',
          'Enabled',
        ),

        const SizedBox(height: 14),

        _buildSignOutButton(context),
      ],
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard({
    required String fullName,
    required String role,
    required bool isActive,
  }) {
    final initials = _getInitials(fullName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: primaryMaroon,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: mainText,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.cancel_outlined,
                      size: 16,
                      color: isActive
                          ? successGreen
                          : secondaryText,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      isActive
                          ? 'Active account'
                          : 'Inactive account',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? successGreen
                            : secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS CARD
  // ============================================================

  Widget _buildDetailsCard({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Full name',
            value: fullName,
          ),

          _buildDivider(),

          _buildDetailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),

          _buildDivider(),

          _buildDetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            value: phoneNumber,
          ),

          _buildDivider(),

          _buildDetailRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: role,
          ),

          _buildDivider(),

          _buildDetailRow(
            icon: isActive
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            label: 'Account status',
            value: isActive
                ? 'Active'
                : 'Inactive',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT CONTENT
  // ============================================================

  Widget _buildEditContent({
    required String email,
    required String role,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Edit account information'),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Column(
            children: [
              _buildEditField(
                controller: _fullNameController,
                label: 'Full name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 18),

              _buildReadOnlyField(
                label: 'Email',
                value: email,
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 18),

              _buildEditField(
                controller: _phoneController,
                label: 'Phone number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 18),

              _buildReadOnlyField(
                label: 'Role',
                value: role,
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 18),

              _buildReadOnlyField(
                label: 'Account status',
                value: isActive
                    ? 'Active'
                    : 'Inactive',
                icon: isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMaroon,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  primaryMaroon.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : _cancelEditing,
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryMaroon,
              side: const BorderSide(
                color: primaryMaroon,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDITABLE FIELD
  // ============================================================

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: mainText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: primaryMaroon,
          size: 20,
        ),
        labelStyle: const TextStyle(
          color: secondaryText,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFADB4C0),
          fontSize: 13,
        ),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryMaroon,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // READ ONLY FIELD
  // ============================================================

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextField(
      controller: TextEditingController(
        text: value,
      ),
      readOnly: true,
      enabled: false,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: mainText,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: secondaryText,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F1F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // START EDITING
  // ============================================================

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  // ============================================================
  // CANCEL EDITING
  // ============================================================

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controllersLoaded = false;
    });
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final userDocument = _userDocument;

    if (userDocument == null) {
      _showMessage(
        'No signed-in user found.',
        isError: true,
      );
      return;
    }

    final fullName =
        _fullNameController.text.trim();

    final phoneNumber =
        _phoneController.text.trim();

    if (fullName.isEmpty) {
      _showMessage(
        'Please enter your full name.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await userDocument.update({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _isEditing = false;
        _controllersLoaded = false;
      });

      _showMessage(
        'Profile updated successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to update your profile. Please try again.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: mainText,
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: pinkCard,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: primaryMaroon,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: mainText,
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
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.7,
      color: borderColor,
    );
  }

  // ============================================================
  // PRIVACY / SECURITY
  // ============================================================

  Widget _buildStatusRow(
    String title,
    String status,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: successGreen,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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

  Widget _buildSignOutButton(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () {
            _showSignOutDialog(context);
          },
          icon: const Icon(
            Icons.logout_rounded,
            size: 19,
          ),
          label: const Text(
            'Sign out',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryMaroon,
            side: const BorderSide(
              color: primaryMaroon,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIGN OUT DIALOG
  // ============================================================

  Future<void> _showSignOutDialog(
    BuildContext context,
  ) async {
    final shouldSignOut =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Sign out?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: mainText,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out of your organization account?',
            style: TextStyle(
              color: secondaryText,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Sign out',
                style: TextStyle(
                  color: primaryMaroon,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

  Navigator.popUntil(
  context,
  (route) => route.isFirst,
);
  }

  // ============================================================
  // LOADING CARD
  // ============================================================

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: primaryMaroon,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: const Text(
        'Unable to load profile information.',
        style: TextStyle(
          color: secondaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? primaryMaroon
              : successGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // FIRESTORE STRING HELPER
  // ============================================================

  String _readString(dynamic value) {
    if (value == null) {
      return 'Not recorded';
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return 'Not recorded';
    }

    return result;
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _getInitials(String name) {
    if (name.trim().isEmpty ||
        name == 'Not recorded') {
      return 'O';
    }

    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.length == 1) {
      final word = words.first;

      if (word.length == 1) {
        return word.toUpperCase();
      }

      return word
          .substring(0, 2)
          .toUpperCase();
    }

    return (
      words.first[0] +
      words.last[0]
    ).toUpperCase();
  }
}