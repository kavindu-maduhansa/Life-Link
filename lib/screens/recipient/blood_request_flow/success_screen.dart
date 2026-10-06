import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';

/// Success screen (HF 12)
class SuccessScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onContinue;

  const SuccessScreen({
    super.key,
    this.message = 'Request completed successfully!',
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon with soft neumorphic surface
                NeumorphicSurface(
                  borderRadius: BorderRadius.circular(60),
                  elevation: NeumorphicElevationLevel.raised,
                  padding: const EdgeInsets.all(32),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: colors.success,
                  ),
                ),
                const SizedBox(height: 32),

                // Success Message
                Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: NeumorphicButton(
                    onPressed: onContinue ?? () => Navigator.pop(context),
                    isPrimary: true,
                    height: 52,
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
