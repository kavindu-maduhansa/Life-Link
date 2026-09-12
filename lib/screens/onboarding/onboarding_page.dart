import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';

/// A single page in the 3-screen LifeLink onboarding experience.
///
/// Designed to be clean, modern, and healthcare-focused. Conforms to the
/// project design system tokens (`AppColors`, `LLSpacing`, `LLRadius`) and
/// ensures accessibility across small, standard, and tablet screens.
class OnboardingPage extends StatelessWidget {
  final String stepTag;
  final String title;
  final String description;
  final Widget visual;

  const OnboardingPage({
    super.key,
    required this.stepTag,
    required this.title,
    required this.description,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 680;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: LLSpacing.pageH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: isCompact ? LLSpacing.xs : LLSpacing.sm),

              // Step Tag Pill (e.g., "STEP 1 OF 3 • CONNECT")
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LLSpacing.md,
                  vertical: LLSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(LLRadius.pill),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  stepTag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colors.primary,
                  ),
                ),
              ),

              SizedBox(height: isCompact ? LLSpacing.md : LLSpacing.lg),

              // Healthcare Illustration / Visual Container
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: visual,
                ),
              ),

              SizedBox(height: isCompact ? LLSpacing.md : LLSpacing.xl),

              // Content Section (Title & Description)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 22 : 25,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: isCompact ? LLSpacing.sm : LLSpacing.md),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 15,
                        height: 1.45,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isCompact ? LLSpacing.md : LLSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
