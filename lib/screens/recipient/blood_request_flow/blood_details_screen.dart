import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';
import 'hospital_location_screen.dart';

/// Blood details form screen (HF 04)
class BloodDetailsScreen extends StatefulWidget {
  final bool isEmergency;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientId;

  const BloodDetailsScreen({
    super.key,
    required this.isEmergency,
    required this.requestingFor,
    required this.patientName,
    required this.patientAge,
    required this.relationship,
    required this.patientId,
  });

  @override
  State<BloodDetailsScreen> createState() => _BloodDetailsScreenState();
}

class _BloodDetailsScreenState extends State<BloodDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _requiredBeforeController =
      TextEditingController();

  String? _bloodGroup;

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
            patientId: widget.patientId,
            bloodGroup: _bloodGroup!,
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
    final colors = context.colors;
    final primaryColor = colors.accent;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Blood Details',
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
                  value: 0.5,
                  minHeight: 6,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 2 of 4',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Blood Group Selection
              Text(
                'Blood Group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
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
                    child: NeumorphicSurface(
                      isPressed: isSelected,
                      elevation: isSelected
                          ? NeumorphicElevationLevel.inset
                          : NeumorphicElevationLevel.raised,
                      borderRadius: BorderRadius.circular(12),
                      borderColor: isSelected ? primaryColor : colors.border,
                      borderWidth: isSelected ? 1.8 : 1.0,
                      child: Center(
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? primaryColor
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Units Needed
              TextFormField(
                controller: _unitsController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Units Needed',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: 'Enter number of units',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.format_list_numbered_rounded,
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
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: 'Describe the reason for blood request',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.description_rounded,
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
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Required Before',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: 'Select date',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.calendar_today_rounded,
                    color: colors.textSecondary,
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down_rounded,
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
