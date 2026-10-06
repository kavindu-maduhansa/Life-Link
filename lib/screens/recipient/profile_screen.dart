import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../widgets/appearance_selector_sheet.dart';
import '../../widgets/neumorphic/neumorphic_widgets.dart';

/// Profile screen for recipient
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColor = colors.accent;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Neumorphic custom header
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: colors.darkShadow.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Appearance',
                    icon: const Icon(Icons.palette_outlined),
                    color: colors.textSecondary,
                    onPressed: () => AppearanceSelectorSheet.show(context),
                  ),
                ],
              ),
            ),
          ),
          // Profile content
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: user?.uid != null
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData &&
                    !snapshot.hasError) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final userData = snapshot.data?.data();
                final fullName = userData?['fullName'] as String? ??
                    (user?.displayName?.trim().isNotEmpty == true
                        ? user!.displayName!.trim()
                        : (user?.email != null && user!.email!.contains('@')
                            ? user.email!.split('@').first
                            : 'Recipient User'));
                final email = userData?['email'] as String? ?? user?.email ?? 'Not available';
                final phoneNumber =
                    userData?['phoneNumber'] as String? ?? 'Not provided';
                final role = userData?['role'] as String? ?? 'Recipient';
                final createdAt = userData?['createdAt'] as Timestamp?;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.highlightShadow,
                                    offset: const Offset(-3, -3),
                                    blurRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: colors.darkShadow,
                                    offset: const Offset(3, 3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fullName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                role[0].toUpperCase() + role.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profile Details Card
                      NeumorphicCard(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildProfileItem(
                              context: context,
                              icon: Icons.person_outline_rounded,
                              label: 'Full Name',
                              value: fullName,
                            ),
                            Divider(height: 32, color: colors.border),
                            _buildProfileItem(
                              context: context,
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: email,
                            ),
                            Divider(height: 32, color: colors.border),
                            _buildProfileItem(
                              context: context,
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: phoneNumber,
                            ),
                            if (createdAt != null) ...[
                              Divider(height: 32, color: colors.border),
                              _buildProfileItem(
                                context: context,
                                icon: Icons.calendar_today_outlined,
                                label: 'Member Since',
                                value: _formatDate(createdAt.toDate()),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSignOut(context),
                          icon: Icon(Icons.logout_rounded, color: primaryColor),
                          label: Text(
                            'Sign Out',
                            style: TextStyle(color: primaryColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, color: colors.textSecondary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
