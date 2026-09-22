import 'package:flutter/material.dart';
import 'review_request_screen.dart';

/// Urgency & contact form screen (HF 06)
class UrgencyContactScreen extends StatefulWidget {
  final bool isEmergency;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientId;
  final String bloodGroup;
  final int unitsNeeded;
  final String reason;
  final DateTime requiredBefore;
  final String hospitalId;
  final String hospitalName;
  final String hospitalLocation;

  const UrgencyContactScreen({
    super.key,
    required this.isEmergency,
    required this.requestingFor,
    required this.patientName,
    required this.patientAge,
    required this.relationship,
    required this.patientId,
    required this.bloodGroup,
    required this.unitsNeeded,
    required this.reason,
    required this.requiredBefore,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalLocation,
  });

  @override
  State<UrgencyContactScreen> createState() => _UrgencyContactScreenState();
}

class _UrgencyContactScreenState extends State<UrgencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactNumberController =
      TextEditingController();

  String? _urgency;
  String? _bloodNeededBy;
  String? _preferredUpdateMethod;

  final List<String> _urgencyOptions = [
    'Within 1 hour',
    'Within 3 hours',
    'Within 6 hours',
    'Within 12 hours',
    'Within 24 hours',
    'Within 48 hours',
  ];

  final List<String> _bloodNeededByOptions = [
    'Immediately',
    'Today',
    'Tomorrow',
    'This week',
  ];

  final List<String> _updateMethodOptions = [
    'SMS',
    'Email',
    'App Notification',
  ];

  @override
  void dispose() {
    _contactNumberController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() &&
        _urgency != null &&
        _bloodNeededBy != null &&
        _preferredUpdateMethod != null) {
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
            bloodGroup: widget.bloodGroup,
            unitsNeeded: widget.unitsNeeded,
            reason: widget.reason,
            requiredBefore: widget.requiredBefore,
            hospitalId: widget.hospitalId,
            hospitalName: widget.hospitalName,
            hospitalLocation: widget.hospitalLocation,
            urgency: _urgency!,
            bloodNeededBy: _bloodNeededBy!,
            contactNumber: _contactNumberController.text.trim(),
            preferredUpdateMethod: _preferredUpdateMethod!,
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
        title: const Text('Urgency & Contact'),
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
                value: 1.0,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 4 of 4',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Urgency Selection
              const Text(
                'Urgency Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _urgency,
                decoration: InputDecoration(
                  hintText: 'Select urgency level',
                  prefixIcon: const Icon(Icons.speed_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _urgencyOptions.map((urgency) {
                  return DropdownMenuItem(value: urgency, child: Text(urgency));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _urgency = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select urgency level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Blood Needed By
              const Text(
                'Blood Needed By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _bloodNeededBy,
                decoration: InputDecoration(
                  hintText: 'Select when blood is needed',
                  prefixIcon: const Icon(Icons.access_time_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _bloodNeededByOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _bloodNeededBy = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select when blood is needed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Number
              TextFormField(
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter your contact number',
                  prefixIcon: const Icon(Icons.phone_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 16),

              // Preferred Update Method
              const Text(
                'Preferred Update Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _preferredUpdateMethod,
                decoration: InputDecoration(
                  hintText: 'Select update method',
                  prefixIcon: const Icon(Icons.notifications_active_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _updateMethodOptions.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _preferredUpdateMethod = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select update method';
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Review & Submit',
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
