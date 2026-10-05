import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/neumorphic/neumorphic_widgets.dart';

/// Error screen (HF 13)
class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const ErrorScreen({
    super.key,
    this.title = 'Error',
    this.message = 'An error occurred. Please try again.',
    this.onRetry,
    this.onBack,
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
                // Error Icon with soft neumorphic surface
                NeumorphicSurface(
                  borderRadius: BorderRadius.circular(60),
                  elevation: NeumorphicElevationLevel.raised,
                  padding: const EdgeInsets.all(32),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 80,
                    color: colors.critical,
                  ),
                ),
                const SizedBox(height: 32),

                // Error Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Error Message
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

                // Retry Button
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: NeumorphicButton(
                      onPressed: onRetry,
                      isPrimary: true,
                      height: 52,
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (onRetry != null) const SizedBox(height: 14),

                // Back Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onBack ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
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
