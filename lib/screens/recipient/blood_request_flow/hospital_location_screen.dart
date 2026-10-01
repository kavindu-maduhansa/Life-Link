import 'package:flutter/material.dart';
import 'urgency_contact_screen.dart';

/// Hospital & location selection screen (HF 05)
class HospitalLocationScreen extends StatefulWidget {
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

  const HospitalLocationScreen({
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
  });

  @override
  State<HospitalLocationScreen> createState() => _HospitalLocationScreenState();
}

class _HospitalLocationScreenState extends State<HospitalLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _wardUnitController = TextEditingController();
  final TextEditingController _doctorClinicController = TextEditingController();

  @override
  void dispose() {
    _hospitalController.dispose();
    _wardUnitController.dispose();
    _doctorClinicController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UrgencyContactScreen(
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
            hospitalId: '',
            hospitalName: _hospitalController.text.trim(),
            hospitalLocation: '',
            wardUnit: _wardUnitController.text.trim(),
            doctorClinic: _doctorClinicController.text.trim(),
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
        title: const Text('Hospital & Location'),
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
                value: 0.75,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 3 of 4',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Hospital Field
              TextFormField(
                controller: _hospitalController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Hospital',
                  hintText: 'Enter hospital name',
                  prefixIcon: const Icon(Icons.local_hospital_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter hospital name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ward/Unit
              TextFormField(
                controller: _wardUnitController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Ward / Unit',
                  hintText: 'Enter ward or unit number',
                  prefixIcon: const Icon(Icons.meeting_room_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter ward/unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Doctor or Clinic
              TextFormField(
                controller: _doctorClinicController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Doctor or Clinic',
                  hintText: 'Enter doctor name or clinic name',
                  prefixIcon: const Icon(Icons.person_search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter doctor or clinic name';
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
