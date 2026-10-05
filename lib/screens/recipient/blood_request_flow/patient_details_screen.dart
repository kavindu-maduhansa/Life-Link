import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';
import 'blood_details_screen.dart';

/// Patient details form screen (HF 03)
class PatientDetailsScreen extends StatefulWidget {
  final bool isEmergency;

  const PatientDetailsScreen({super.key, required this.isEmergency});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();

  String? _requestingFor;
  String? _relationship;

  final List<String> _requestingForOptions = ['Self', 'Other'];
  final List<String> _relationshipOptions = [
    'Parent',
    'Child',
    'Spouse',
    'Sibling',
    'Friend',
    'Relative',
    'Other',
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() && _requestingFor != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BloodDetailsScreen(
            isEmergency: widget.isEmergency,
            requestingFor: _requestingFor!,
            patientName: _patientNameController.text.trim(),
            patientAge: int.parse(_ageController.text.trim()),
            relationship: _relationship ?? 'Self',
            patientId: _patientIdController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColor = colors.accent;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Patient Details',
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
                  value: 0.25,
                  minHeight: 6,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 1 of 4',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Requesting For Section
              Text(
                'Requesting For',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _requestingForOptions.map((option) {
                  final isSelected = _requestingFor == option;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option == _requestingForOptions.last ? 0 : 8,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _requestingFor = option;
                            if (option == 'Self') {
                              _relationship = 'Self';
                            } else if (_relationship == 'Self') {
                              _relationship = null;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: NeumorphicSurface(
                          isPressed: isSelected,
                          elevation: isSelected
                              ? NeumorphicElevationLevel.inset
                              : NeumorphicElevationLevel.raised,
                          borderRadius: BorderRadius.circular(12),
                          borderColor: isSelected
                              ? primaryColor
                              : colors.border,
                          borderWidth: isSelected ? 1.8 : 1.0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? primaryColor
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Relationship (only show if requesting for other)
              if (_requestingFor == 'Other') ...[
                Text(
                  'Relationship',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _relationshipOptions.contains(_relationship)
                      ? _relationship
                      : null,
                  style: TextStyle(color: colors.textPrimary),
                  dropdownColor: colors.surface,
                  decoration: InputDecoration(
                    hintText: 'Select relationship',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.people_outline_rounded,
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
                  items: _relationshipOptions.map((relationship) {
                    return DropdownMenuItem(
                      value: relationship,
                      child: Text(
                        relationship,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _relationship = value;
                    });
                  },
                  validator: (value) {
                    if (_requestingFor == 'Other' && value == null) {
                      return 'Please select relationship';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Patient Name
              TextFormField(
                controller: _patientNameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: _requestingFor == 'Self'
                      ? 'Your Name'
                      : 'Patient\'s Full Name',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: _requestingFor == 'Self'
                      ? 'Enter your name'
                      : 'Enter patient\'s full name',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
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
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: _requestingFor == 'Self'
                      ? 'Your Age'
                      : 'Patient\'s Age',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: _requestingFor == 'Self'
                      ? 'Enter your age'
                      : 'Enter patient\'s age',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.cake_rounded,
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
                    return 'Please enter age';
                  }
                  final age = int.tryParse(value.trim());
                  if (age == null || age < 0 || age > 120) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Patient ID / Hospital Number
              TextFormField(
                controller: _patientIdController,
                keyboardType: TextInputType.text,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Patient ID / Hospital Number',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: 'Enter patient ID or hospital number',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.badge_rounded,
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
                    return 'Please enter patient ID / hospital number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Continue Button
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
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
