import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';
import '../recipient_shell.dart';
import 'review_request_screen.dart';

/// Urgency & contact form screen (HF 06)
class UrgencyContactScreen extends StatefulWidget {
  final bool isEmergency;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientId;
  final String gender;
  final String bloodGroup;
  final int unitsNeeded;
  final String reason;
  final String hospitalId;
  final String hospitalName;
  final String hospitalLocation;
  final String wardUnit;
  final String doctorClinic;

  const UrgencyContactScreen({
    super.key,
    required this.isEmergency,
    required this.requestingFor,
    required this.patientName,
    required this.patientAge,
    required this.relationship,
    required this.patientId,
    required this.gender,
    required this.bloodGroup,
    required this.unitsNeeded,
    required this.reason,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalLocation,
    required this.wardUnit,
    required this.doctorClinic,
  });

  @override
  State<UrgencyContactScreen> createState() => _UrgencyContactScreenState();
}

class _UrgencyContactScreenState extends State<UrgencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactNumberController =
      TextEditingController();

  String? _urgency;
  DateTime? _requiredBy;

  final List<String> _urgencyOptions = ['Critical', 'Urgent', 'Normal'];

  @override
  void dispose() {
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _requiredBy = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() &&
        _urgency != null &&
        _requiredBy != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewRequestScreen(
            isEmergency: widget.isEmergency,
            requestingFor: widget.requestingFor,
            patientName: widget.patientName,
            patientAge: widget.patientAge,
            relationship: widget.relationship,
            patientId: widget.patientId,
            gender: widget.gender,
            bloodGroup: widget.bloodGroup,
            unitsNeeded: widget.unitsNeeded,
            reason: widget.reason,
            hospitalId: widget.hospitalId,
            hospitalName: widget.hospitalName,
            hospitalLocation: widget.hospitalLocation,
            wardUnit: widget.wardUnit,
            doctorClinic: widget.doctorClinic,
            urgency: _urgency!,
            bloodNeededBy: _urgency!,
            contactNumber: _contactNumberController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColor = colors.accent;

    return RecipientShell(
      currentNavIndex: 0,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(
            'Urgency & Contact',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: colors.surface,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: colors.border, height: 1),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 6,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step 4 of 4',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Urgency Selection
                Text(
                  'Urgency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _urgencyOptions.map((option) {
                    final isSelected = _urgency == option;
                    IconData icon;
                    Color iconColor;
                    String description;

                    switch (option) {
                      case 'Critical':
                        icon = Icons.error;
                        iconColor = Colors.red;
                        description = 'Required immediately';
                        break;
                      case 'Urgent':
                        icon = Icons.warning;
                        iconColor = Colors.orange;
                        description = 'Required within a few hours';
                        break;
                      case 'Normal':
                        icon = Icons.info;
                        iconColor = Colors.amber;
                        description = 'Required later';
                        break;
                      default:
                        icon = Icons.info;
                        iconColor = Colors.grey;
                        description = '';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _urgency = option;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: NeumorphicSurface(
                          isPressed: isSelected,
                          elevation: isSelected
                              ? NeumorphicElevationLevel.inset
                              : NeumorphicElevationLevel.raised,
                          borderRadius: BorderRadius.circular(12),
                          borderColor: isSelected ? iconColor : colors.border,
                          borderWidth: isSelected ? 1.8 : 1.0,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(icon, color: iconColor, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? iconColor
                                            : colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: iconColor,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Required By Date & Time
                Text(
                  'Required By',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: NeumorphicSurface(
                    elevation: NeumorphicElevationLevel.raised,
                    borderRadius: BorderRadius.circular(12),
                    borderColor: _requiredBy != null
                        ? primaryColor
                        : colors.border,
                    borderWidth: _requiredBy != null ? 1.8 : 1.0,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _requiredBy != null
                              ? primaryColor
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _requiredBy != null
                                ? '${_requiredBy!.day}/${_requiredBy!.month}/${_requiredBy!.year} at ${_requiredBy!.hour.toString().padLeft(2, '0')}:${_requiredBy!.minute.toString().padLeft(2, '0')}'
                                : 'Select date and time',
                            style: TextStyle(
                              fontSize: 16,
                              color: _requiredBy != null
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Number
                Text(
                  'Contact Number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '+94 XX XXX XXXX',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.phone_rounded,
                      color: colors.textSecondary,
                    ),
                    filled: true,
                    fillColor: colors.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1.8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter contact number';
                    }
                    if (value.trim().length < 10) {
                      return 'Please enter a valid mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Review & Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Review & Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}
