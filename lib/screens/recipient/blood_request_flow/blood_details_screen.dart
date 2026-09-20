import 'package:flutter/material.dart';
import 'hospital_location_screen.dart';

/// Blood details form screen (HF 04)
class BloodDetailsScreen extends StatefulWidget {
  final bool isEmergency;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientMobileNumber;

  const BloodDetailsScreen({
    super.key,
    required this.isEmergency,
    required this.requestingFor,
    required this.patientName,
    required this.patientAge,
    required this.relationship,
    required this.patientMobileNumber,
  });

  @override
  State<BloodDetailsScreen> createState() => _BloodDetailsScreenState();
}

class _BloodDetailsScreenState extends State<BloodDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _requiredBeforeController = TextEditingController();

  String? _bloodGroup;
  String? _bloodComponent;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _bloodComponents = [
    'Whole Blood',
    'Red Blood Cells',
    'Platelets',
    'Plasma',
  ];

  DateTime? _selectedDate;

  @override
  void dispose() {
    _unitsController.dispose();
    _reasonController.dispose();
    _requiredBeforeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _requiredBeforeController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() &&
        _bloodGroup != null &&
        _bloodComponent != null &&
        _selectedDate != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HospitalLocationScreen(
            isEmergency: widget.isEmergency,
            requestingFor: widget.requestingFor,
            patientName: widget.patientName,
            patientAge: widget.patientAge,
            relationship: widget.relationship,
            patientMobileNumber: widget.patientMobileNumber,
            bloodGroup: _bloodGroup!,
            bloodComponent: _bloodComponent!,
            unitsNeeded: int.parse(_unitsController.text.trim()),
            reason: _reasonController.text.trim(),
            requiredBefore: _selectedDate!,
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
        title: const Text('Blood Details'),
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
                value: 0.5,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 2 of 4',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Blood Group Selection
              const Text(
                'Blood Group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.2,
                ),
                itemCount: _bloodGroups.length,
                itemBuilder: (context, index) {
                  final group = _bloodGroups[index];
                  final isSelected = _bloodGroup == group;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _bloodGroup = group;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Blood Component
              const Text(
                'Blood Component',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _bloodComponent,
                decoration: InputDecoration(
                  hintText: 'Select blood component',
                  prefixIcon: const Icon(Icons.bloodtype_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _bloodComponents.map((component) {
                  return DropdownMenuItem(
                    value: component,
                    child: Text(component),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _bloodComponent = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select blood component';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Units Needed
              TextFormField(
                controller: _unitsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Units Needed',
                  hintText: 'Enter number of units',
                  prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter units needed';
                  }
                  final units = int.tryParse(value.trim());
                  if (units == null || units < 1) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Describe the reason for blood request',
                  prefixIcon: const Icon(Icons.description_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Required Before Date
              TextFormField(
                controller: _requiredBeforeController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  labelText: 'Required Before',
                  hintText: 'Select date',
                  prefixIcon: const Icon(Icons.calendar_today_rounded),
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select required date';
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
