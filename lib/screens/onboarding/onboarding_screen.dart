import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import '../auth/auth_gate.dart';
import 'onboarding_page.dart';

/// The 3-screen LifeLink onboarding experience.
///
/// Features:
/// 1. Connect Blood Donors with Those in Need (Healthcare matching illustration)
/// 2. Trusted & Verified Requests (Request card with Blood group, Hospital, Urgency, Verified badge)
/// 3. Respond and Stay Updated (4-step flow: Emergency Request -> Respond -> Status -> History)
///
/// Provides:
/// - Skip button (immediate navigation to AuthGate / Login)
/// - Back button (available on Screen 2 and 3)
/// - Next button (Screen 1 & 2)
/// - Get Started button (Screen 3)
/// - Animated page dot indicators
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const OnboardingScreen({
    super.key,
    this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lifelink_has_seen_onboarding', true);

    if (widget.onFinish != null) {
      widget.onFinish!();
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                color: colors.textPrimary,
                onPressed: _previousPage,
              )
            : const SizedBox.shrink(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop_rounded,
                size: 16,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: LLSpacing.xs),
            Text(
              'LifeLink',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colors.primary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Skip Button
          TextButton(
            onPressed: _completeOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: colors.accent,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: LLSpacing.lg),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          // Screen 1: Connect People
          OnboardingPage(
            stepTag: 'STEP 1 OF 3 • CONNECT',
            title: 'Connect Blood Donors with Those in Need',
            description:
                'Find suitable blood donors faster and help patients receive the blood they urgently need.',
            visual: _buildConnectIllustration(context),
          ),

          // Screen 2: Verified Emergency Requests
          OnboardingPage(
            stepTag: 'STEP 2 OF 3 • TRUST & VERIFICATION',
            title: 'Trusted & Verified Requests',
            description:
                'Receive verified emergency blood requests and easily identify requests that have been confirmed by hospitals or blood banks.',
            visual: _buildVerifiedRequestIllustration(context),
          ),

          // Screen 3: Respond & Track
          OnboardingPage(
            stepTag: 'STEP 3 OF 3 • ACTION & HISTORY',
            title: 'Respond and Stay Updated',
            description:
                'Respond to suitable blood requests and keep track of your responses and donation history in one place.',
            visual: _buildTrackFlowIllustration(context),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LLSpacing.pageH,
            vertical: LLSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(
              top: BorderSide(
                color: colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Navigation Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (Bottom alternative / spacing anchor)
                  if (_currentPage > 0)
                    OutlinedButton.icon(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LLSpacing.md,
                          vertical: LLSpacing.sm,
                        ),
                        side: BorderSide(color: colors.border),
                        foregroundColor: colors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LLRadius.control),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),

                  // Page Dot Indicators
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return GestureDetector(
                        key: ValueKey('dot_indicator_$index'),
                        onTap: () => _goToPage(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isActive ? 26 : 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? colors.primary
                                : colors.border.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(LLRadius.pill),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  if (_currentPage < 2)
                    FilledButton.icon(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: LLSpacing.lg,
                          vertical: LLSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LLRadius.control),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text(
                        'Next',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _completeOnboarding,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: LLSpacing.lg,
                          vertical: LLSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LLRadius.control),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text(
                        'Get Started',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 1 VISUAL: Donor & Recipient Connection
  // ===========================================================================
  Widget _buildConnectIllustration(BuildContext context) {
    final colors = context.colors;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380, maxHeight: 260),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft circles for depth
          Positioned(
            left: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            right: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentContainer.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Central Connecting Flow Line
          Positioned(
            left: 80,
            right: 80,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary,
                    colors.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Central Glowing Heart/Drop Hub
          Positioned(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    size: 26,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accentContainer,
                    borderRadius: BorderRadius.circular(LLRadius.pill),
                  ),
                  child: Text(
                    'Instant Match',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Left Node: Blood Donor Card
          Positioned(
            left: 0,
            child: _buildEntityCard(
              context,
              roleLabel: 'Blood Donor',
              name: 'Active Volunteer',
              bloodGroup: 'O+',
              statusText: 'Available to Donate',
              icon: Icons.person_rounded,
              accentColor: colors.primary,
              containerColor: colors.primaryContainer.withValues(alpha: 0.35),
            ),
          ),

          // Right Node: Patient/Recipient Card
          Positioned(
            right: 0,
            child: _buildEntityCard(
              context,
              roleLabel: 'Recipient Patient',
              name: 'Urgent Care Unit',
              bloodGroup: 'O+',
              statusText: 'Request Matched',
              icon: Icons.local_hospital_rounded,
              accentColor: colors.accent,
              containerColor: colors.accentContainer.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityCard(
    BuildContext context, {
    required String roleLabel,
    required String name,
    required String bloodGroup,
    required String statusText,
    required IconData icon,
    required Color accentColor,
    required Color containerColor,
  }) {
    final colors = context.colors;

    return Container(
      width: 132,
      padding: const EdgeInsets.all(LLSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(LLRadius.card),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: containerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(height: 6),
          Text(
            roleLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              fontSize: 9,
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(LLRadius.pill),
            ),
            child: Text(
              bloodGroup,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2 VISUAL: Verified Emergency Request Card
  // ===========================================================================
  Widget _buildVerifiedRequestIllustration(BuildContext context) {
    final colors = context.colors;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(LLSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(LLRadius.card),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row: Urgency + Units
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: LLSpacing.sm,
            runSpacing: LLSpacing.xs,
            children: [
              // Urgency Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LLSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.criticalContainer,
                  borderRadius: BorderRadius.circular(LLRadius.pill),
                  border: Border.all(color: colors.critical.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emergency_rounded,
                      size: 13,
                      color: colors.critical,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'URGENT EMERGENCY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: colors.critical,
                      ),
                    ),
                  ],
                ),
              ),

              // Units Required
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LLSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.elevatedSurface,
                  borderRadius: BorderRadius.circular(LLRadius.pill),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '2 Units Required',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: LLSpacing.md),

          // Center Row: Large Blood Group + Patient Details
          Row(
            children: [
              // Blood Group Container
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(LLRadius.control),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'A+',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: LLSpacing.md),

              // Request Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Surgery Case',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital_rounded,
                          size: 14,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'City General Hospital',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.accent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trauma Care Wing • 2.4 km away',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: LLSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: LLSpacing.md),

          // Prominent Verified Badge Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LLSpacing.md,
              vertical: LLSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.successContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(LLRadius.control),
              border: Border.all(
                color: colors.success.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: LLSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Hospital Request',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.success,
                        ),
                      ),
                      Text(
                        'Confirmed by Blood Bank Authorization Desk',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: colors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3 VISUAL: Flow (Emergency Request -> Respond -> Status -> History)
  // ===========================================================================
  Widget _buildTrackFlowIllustration(BuildContext context) {
    final colors = context.colors;

    final steps = [
      _FlowStep(
        stepNumber: '1',
        title: 'Emergency Request',
        subtitle: 'Receive instant notification for matched blood groups',
        icon: Icons.emergency_share_rounded,
        accentColor: colors.critical,
        containerColor: colors.criticalContainer,
      ),
      _FlowStep(
        stepNumber: '2',
        title: 'Respond',
        subtitle: 'Confirm your availability in a single tap',
        icon: Icons.touch_app_rounded,
        accentColor: colors.primary,
        containerColor: colors.primaryContainer.withValues(alpha: 0.4),
      ),
      _FlowStep(
        stepNumber: '3',
        title: 'Response Status',
        subtitle: 'Coordinate with hospital staff in real-time',
        icon: Icons.sync_alt_rounded,
        accentColor: colors.accent,
        containerColor: colors.accentContainer,
      ),
      _FlowStep(
        stepNumber: '4',
        title: 'Donation History',
        subtitle: 'Track past donations, badges, and verified impact',
        icon: Icons.history_edu_rounded,
        accentColor: colors.success,
        containerColor: colors.successContainer,
      ),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildFlowStepItem(context, steps[i]),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 2,
                    height: 12,
                    color: colors.border,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlowStepItem(BuildContext context, _FlowStep step) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LLSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(LLRadius.control),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step Icon / Number Indicator
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: step.containerColor,
              borderRadius: BorderRadius.circular(LLRadius.control),
            ),
            child: Center(
              child: Icon(
                step.icon,
                size: 18,
                color: step.accentColor,
              ),
            ),
          ),
          const SizedBox(width: LLSpacing.sm),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(LLRadius.pill),
                      ),
                      child: Text(
                        'Step ${step.stepNumber}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: step.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: colors.textSecondary.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _FlowStep {
  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color containerColor;

  const _FlowStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.containerColor,
  });
}
