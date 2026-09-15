import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../utils/request_status.dart';

/// Donor Profile Screen displaying personal and donation details
/// fetched from Firestore `users/{uid}` with edit capabilities.
class DonorProfileScreen extends StatelessWidget {
  const DonorProfileScreen({super.key});

  /// Helper to format last donation date nicely from Firestore Timestamp, DateTime, or null.
  String _formatLastDonationDate(dynamic value) {
    if (value == null) {
      return 'No donation recorded';
    }

    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return 'No donation recorded';
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final monthStr = months[date.month - 1];
    return '${date.day.toString().padLeft(2, '0')} $monthStr ${date.year}';
  }

  void _showEditProfileModal(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditDonorProfileBottomSheet(initialData: data),
    );
  }

  User? _getCurrentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = _getCurrentUser();

    if (user == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Donor Profile'),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text('User is not signed in.', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Donor Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colors.primary, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('Loading profile...', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: colors.critical),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error?.toString() ?? 'An error occurred.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final doc = snapshot.data;
          final data = doc?.data() ?? <String, dynamic>{};

          final rawFullName = data['fullName'] as String?;
          final fullName = (rawFullName != null && rawFullName.trim().isNotEmpty) ? rawFullName.trim() : 'Not set';

          final email = (data['email'] as String?)?.trim().isNotEmpty == true
              ? (data['email'] as String).trim()
              : (user.email ?? 'Not set');

          final rawPhone = data['phoneNumber'] as String?;
          final phoneNumber = (rawPhone != null && rawPhone.trim().isNotEmpty) ? rawPhone.trim() : 'Not set';

          final rawBloodGroup = data['bloodGroup'] as String?;
          final bloodGroup = (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty)
              ? rawBloodGroup.trim()
              : 'Not set';

          final rawLocation = data['location'] as String?;
          final location = (rawLocation != null && rawLocation.trim().isNotEmpty) ? rawLocation.trim() : 'Not set';

          final isAvailable = (data['isAvailable'] as bool?) ?? false;
          final lastDonationDisplay = _formatLastDonationDate(data['lastDonationDate']);

          DateTime? lastDonationDate;
          final rawDonation = data['lastDonationDate'];
          if (rawDonation is Timestamp) {
            lastDonationDate = rawDonation.toDate();
          } else if (rawDonation is DateTime) {
            lastDonationDate = rawDonation;
          } else if (rawDonation is String) {
            lastDonationDate = DateTime.tryParse(rawDonation);
          }
          final isEligible = DonorEligibility.isEligible(lastDonationDate);
          final daysUntil = DonorEligibility.daysUntilEligible(lastDonationDate);
          final eligibilityDisplay = isEligible
              ? 'Eligible to Donate'
              : 'Eligible in ${daysUntil ?? 0} days (90-day cooldown)';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar & Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: colors.primary.withValues(alpha: 0.12),
                            child: Icon(Icons.person_rounded, size: 52, color: colors.primary),
                          ),
                          if (bloodGroup != 'Not set')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                bloodGroup,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      // Availability Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable ? colors.successContainer : colors.criticalContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isAvailable ? colors.successContainer : colors.criticalContainer),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 16,
                              color: isAvailable ? colors.success : colors.critical,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAvailable ? 'Available to Donate' : 'Currently Unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAvailable ? colors.success : colors.critical,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Details Section Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'DONOR DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Information Details Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoTile(icon: Icons.person_outline_rounded, label: 'Full Name', value: fullName),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                        trailing: Icon(Icons.lock_outline_rounded, size: 16, color: colors.textSecondary),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileInfoTile(icon: Icons.phone_outlined, label: 'Phone Number', value: phoneNumber),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileInfoTile(
                        icon: Icons.bloodtype_outlined,
                        label: 'Blood Group',
                        value: bloodGroup,
                        valueColor: bloodGroup != 'Not set' ? colors.primary : colors.textSecondary,
                        valueBold: bloodGroup != 'Not set',
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileInfoTile(icon: Icons.location_on_outlined, label: 'Location', value: location),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileInfoTile(
                        icon: Icons.event_available_rounded,
                        label: 'Availability Status',
                        value: isAvailable ? 'Available' : 'Unavailable',
                        valueColor: isAvailable ? colors.success : colors.critical,
                        valueBold: true,
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileInfoTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Last Donation Date',
                        value: lastDonationDisplay,
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileInfoTile(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Donation Eligibility',
                        value: eligibilityDisplay,
                        valueColor: isEligible ? colors.success : colors.warning,
                        valueBold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Edit Profile Button
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileModal(context, data),
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Single information row in the profile view
class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Color? valueColor;
  final bool valueBold;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.elevatedSurface, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: colors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: valueBold ? FontWeight.w600 : FontWeight.w500,
                    color: valueColor ?? colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Bottom Sheet modal for updating editable donor profile fields.
class _EditDonorProfileBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const _EditDonorProfileBottomSheet({required this.initialData});

  @override
  State<_EditDonorProfileBottomSheet> createState() => _EditDonorProfileBottomSheetState();
}

class _EditDonorProfileBottomSheetState extends State<_EditDonorProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;

  String? _selectedBloodGroup;
  late bool _isAvailable;
  bool _isSaving = false;

  static const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _nameController = TextEditingController(text: (data['fullName'] as String?) ?? '');
    _phoneController = TextEditingController(text: (data['phoneNumber'] as String?) ?? '');
    _locationController = TextEditingController(text: (data['location'] as String?) ?? '');

    final currentBlood = (data['bloodGroup'] as String?)?.trim();
    if (currentBlood != null && _bloodGroups.contains(currentBlood)) {
      _selectedBloodGroup = currentBlood;
    } else {
      _selectedBloodGroup = null;
    }

    _isAvailable = (data['isAvailable'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final colors = context.colors;
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to identify current user. Please re-login.'),
          backgroundColor: colors.critical,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedFullName = _nameController.text.trim();
    final updatedPhone = _phoneController.text.trim();
    final updatedLocation = _locationController.text.trim();
    final updatedBloodGroup = _selectedBloodGroup ?? (widget.initialData['bloodGroup'] as String?) ?? '';

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': updatedFullName,
        'phoneNumber': updatedPhone,
        'bloodGroup': updatedBloodGroup,
        'location': updatedLocation,
        'isAvailable': _isAvailable,
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: colors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Database error occurred while updating profile.'),
          backgroundColor: colors.critical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: colors.critical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Full Name Input
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number Input
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +94 77 123 4567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Blood Group Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  hint: const Text('Select blood group'),
                  items: _bloodGroups.map((group) {
                    return DropdownMenuItem<String>(value: group, child: Text(group));
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (val) {
                          setState(() {
                            _selectedBloodGroup = val;
                          });
                        },
                ),
                const SizedBox(height: 16),

                // Location Input
                TextFormField(
                  controller: _locationController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: 'Location / City',
                    hintText: 'e.g. Colombo, Kandy, Galle',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Availability Status Toggle Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: SwitchListTile(
                    value: _isAvailable,
                    activeThumbColor: colors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Available to Donate Blood',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      _isAvailable
                          ? 'Other users can contact you for blood donation requests.'
                          : 'You will appear unavailable for urgent donation requests.',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    onChanged: _isSaving
                        ? null
                        : (val) {
                            setState(() {
                              _isAvailable = val;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DonorProfileTab
// ---------------------------------------------------------------------------
// Scaffold-free version of DonorProfileScreen for use inside the DonorShell
// IndexedStack. All Firebase queries (`users/{uid}`), field reads
// (`fullName`, `phoneNumber`, `bloodGroup`, `location`, `isAvailable`,
// `lastDonationDate`) and edit functionality are identical to
// DonorProfileScreen — only the Scaffold/AppBar wrappers are absent.
// Card backgrounds use colors.surface instead of Colors.white so dark
// mode works correctly.
// ---------------------------------------------------------------------------

class DonorProfileTab extends StatelessWidget {
  const DonorProfileTab({super.key});

  String _formatLastDonationDate(dynamic value) {
    if (value == null) return 'No donation recorded';

    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'No donation recorded';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  void _showEditProfileModal(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditDonorProfileBottomSheet(initialData: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle_outlined, size: 56, color: colors.textSecondary),
              const SizedBox(height: 16),
              Text('Please Sign In',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text('Sign in to your donor account to view your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colors.primary, strokeWidth: 3),
                const SizedBox(height: 16),
                Text('Loading profile...', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: colors.critical),
                  const SizedBox(height: 16),
                  Text('Failed to load profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(snapshot.error?.toString() ?? 'An error occurred.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                ],
              ),
            ),
          );
        }

        final doc = snapshot.data;
        final data = doc?.data() ?? <String, dynamic>{};

        final rawFullName = data['fullName'] as String?;
        final fullName =
            (rawFullName != null && rawFullName.trim().isNotEmpty) ? rawFullName.trim() : 'Not set';

        final email = (data['email'] as String?)?.trim().isNotEmpty == true
            ? (data['email'] as String).trim()
            : (user!.email ?? 'Not set');

        final rawPhone = data['phoneNumber'] as String?;
        final phoneNumber =
            (rawPhone != null && rawPhone.trim().isNotEmpty) ? rawPhone.trim() : 'Not set';

        final rawBloodGroup = data['bloodGroup'] as String?;
        final bloodGroup =
            (rawBloodGroup != null && rawBloodGroup.trim().isNotEmpty) ? rawBloodGroup.trim() : 'Not set';

        final rawLocation = data['location'] as String?;
        final location =
            (rawLocation != null && rawLocation.trim().isNotEmpty) ? rawLocation.trim() : 'Not set';

        final isAvailable = (data['isAvailable'] as bool?) ?? false;
        final lastDonationDisplay = _formatLastDonationDate(data['lastDonationDate']);

        DateTime? lastDonationDate;
        final rawDonation = data['lastDonationDate'];
        if (rawDonation is Timestamp) {
          lastDonationDate = rawDonation.toDate();
        } else if (rawDonation is DateTime) {
          lastDonationDate = rawDonation;
        } else if (rawDonation is String) {
          lastDonationDate = DateTime.tryParse(rawDonation);
        }
        final isEligible = DonorEligibility.isEligible(lastDonationDate);
        final daysUntil = DonorEligibility.daysUntilEligible(lastDonationDate);
        final eligibilityDisplay = isEligible
            ? 'Eligible to Donate'
            : 'Eligible in ${daysUntil ?? 0} days (90-day cooldown)';

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Avatar & Header Card (colors.surface for dark mode)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: colors.primary.withValues(alpha: 0.12),
                          child: Icon(Icons.person_rounded, size: 52, color: colors.primary),
                        ),
                        if (bloodGroup != 'Not set')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.surface, width: 2),
                            ),
                            child: Text(
                              bloodGroup,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(email,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable ? colors.successContainer : colors.criticalContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isAvailable ? colors.successContainer : colors.criticalContainer),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 16,
                            color: isAvailable ? colors.success : colors.critical,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable ? 'Available to Donate' : 'Currently Unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? colors.success : colors.critical,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'DONOR DETAILS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colors.textSecondary),
                ),
              ),
              const SizedBox(height: 8),

              // Information Details Card (colors.surface for dark mode)
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileInfoTile(
                        icon: Icons.person_outline_rounded, label: 'Full Name', value: fullName),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _ProfileInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                      trailing: Icon(Icons.lock_outline_rounded, size: 16, color: colors.textSecondary),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _ProfileInfoTile(
                        icon: Icons.phone_outlined, label: 'Phone Number', value: phoneNumber),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _ProfileInfoTile(
                      icon: Icons.bloodtype_outlined,
                      label: 'Blood Group',
                      value: bloodGroup,
                      valueColor: bloodGroup != 'Not set' ? colors.primary : colors.textSecondary,
                      valueBold: bloodGroup != 'Not set',
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _ProfileInfoTile(
                        icon: Icons.location_on_outlined, label: 'Location', value: location),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _ProfileInfoTile(
                      icon: Icons.event_available_rounded,
                      label: 'Availability Status',
                      value: isAvailable ? 'Available' : 'Unavailable',
                      valueColor: isAvailable ? colors.success : colors.critical,
                      valueBold: true,
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _ProfileInfoTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Last Donation Date',
                      value: lastDonationDisplay,
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _ProfileInfoTile(
                      icon: Icons.health_and_safety_outlined,
                      label: 'Donation Eligibility',
                      value: eligibilityDisplay,
                      valueColor: isEligible ? colors.success : colors.warning,
                      valueBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: () => _showEditProfileModal(context, data),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text('Edit Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
