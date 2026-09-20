import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'urgency_contact_screen.dart';

/// Hospital & location selection screen (HF 05)
class HospitalLocationScreen extends StatefulWidget {
  final bool isEmergency;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientMobileNumber;
  final String bloodGroup;
  final String bloodComponent;
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
    required this.patientMobileNumber,
    required this.bloodGroup,
    required this.bloodComponent,
    required this.unitsNeeded,
    required this.reason,
    required this.requiredBefore,
  });

  @override
  State<HospitalLocationScreen> createState() => _HospitalLocationScreenState();
}

class _HospitalLocationScreenState extends State<HospitalLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedHospitalId;
  String? _selectedHospitalName;
  String? _selectedHospitalLocation;

  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoadingHospitals = true;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchHospitals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Hospital')
          .get();

      if (mounted) {
        setState(() {
          _hospitals = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['fullName'] as String? ?? 'Unknown Hospital',
              'location': data['location'] as String? ?? 'Unknown Location',
            };
          }).toList();
          _isLoadingHospitals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHospitals = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading hospitals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() && _selectedHospitalId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UrgencyContactScreen(
            isEmergency: widget.isEmergency,
            requestingFor: widget.requestingFor,
            patientName: widget.patientName,
            patientAge: widget.patientAge,
            relationship: widget.relationship,
            patientMobileNumber: widget.patientMobileNumber,
            bloodGroup: widget.bloodGroup,
            bloodComponent: widget.bloodComponent,
            unitsNeeded: widget.unitsNeeded,
            reason: widget.reason,
            requiredBefore: widget.requiredBefore,
            hospitalId: _selectedHospitalId!,
            hospitalName: _selectedHospitalName!,
            hospitalLocation: _selectedHospitalLocation!,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Hospital Selection
              const Text(
                'Select Hospital',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoadingHospitals)
                const Center(child: CircularProgressIndicator())
              else if (_hospitals.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.local_hospital_rounded,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'No hospitals available',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _hospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = _hospitals[index];
                    final isSelected = _selectedHospitalId == hospital['id'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedHospitalId = hospital['id'];
                            _selectedHospitalName = hospital['name'];
                            _selectedHospitalLocation = hospital['location'];
                            _locationController.text = hospital['location'];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_hospital_rounded,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hospital['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hospital['location'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: primaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Location Display (auto-filled from hospital)
              if (_selectedHospitalLocation != null) ...[
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Hospital Location',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedHospitalId != null ? _handleContinue : null,
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
