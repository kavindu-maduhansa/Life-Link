import 'package:flutter/material.dart';
import 'blood_details_screen.dart';

/// Patient details form screen (HF 03)
class PatientDetailsScreen extends StatefulWidget {
  final bool isEmergency;

  const PatientDetailsScreen({
    super.key,
    required this.isEmergency,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

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
    _mobileNumberController.dispose();
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
            patientMobileNumber: _mobileNumberController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: 0.25,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 1 of 4',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Requesting For Section
              const Text(
                'Requesting For',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
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
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? primaryColor : const Color(0xFF374151),
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

              // Patient Name
              TextFormField(
                controller: _patientNameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Patient Name',
                  hintText: 'Enter patient name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter age',
                  prefixIcon: const Icon(Icons.cake_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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

              // Relationship (only show if requesting for other)
              if (_requestingFor == 'Other') ...[
                const Text(
                  'Relationship',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _relationship,
                  decoration: InputDecoration(
                    hintText: 'Select relationship',
                    prefixIcon: const Icon(Icons.people_outline_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _relationshipOptions.map((relationship) {
                    return DropdownMenuItem(
                      value: relationship,
                      child: Text(relationship),
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

              // Mobile Number
              TextFormField(
                controller: _mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Patient Mobile Number',
                  hintText: 'Enter mobile number',
                  prefixIcon: const Icon(Icons.phone_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid mobile number';
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
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
    );
  }
}
