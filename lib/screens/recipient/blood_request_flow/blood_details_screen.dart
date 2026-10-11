import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';
import '../recipient_shell.dart';
import 'hospital_location_screen.dart';

/// Blood details form screen (HF 04)
class BloodDetailsScreen extends StatefulWidget {
  final bool isEmergency;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String relationship;
  final String patientId;
  final String gender;

  const BloodDetailsScreen({
    super.key,
    required this.isEmergency,
    required this.requestingFor,
    required this.patientName,
    required this.patientAge,
    required this.relationship,
    required this.patientId,
    required this.gender,
  });

  @override
  State<BloodDetailsScreen> createState() => _BloodDetailsScreenState();
}

class _BloodDetailsScreenState extends State<BloodDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  int _unitsNeeded = 1;
  String? _bloodGroup;
  String? _reason;

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

  final List<String> _reasonOptions = [
    'Surgery',
    'Accident',
    'Medical treatment',
    'Other',
  ];

  @override
  void dispose() {
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() &&
        _bloodGroup != null &&
        _reason != null) {
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
            gender: widget.gender,
            bloodGroup: _bloodGroup!,
            unitsNeeded: _unitsNeeded,
            reason: _reason!,
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
                Text(
                  'Units Needed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_unitsNeeded > 1) {
                            setState(() {
                              _unitsNeeded--;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: _unitsNeeded > 1
                              ? primaryColor
                              : colors.textSecondary,
                        ),
                        iconSize: 32,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          '$_unitsNeeded',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_unitsNeeded < 20) {
                            setState(() {
                              _unitsNeeded++;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: _unitsNeeded < 20
                              ? primaryColor
                              : colors.textSecondary,
                        ),
                        iconSize: 32,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reason
                Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _reason,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Select reason',
                          style: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: colors.textSecondary,
                      ),
                      items: _reasonOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _reason = newValue;
                        });
                      },
                    ),
                  ),
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
