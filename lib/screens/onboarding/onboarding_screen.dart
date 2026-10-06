import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_gate.dart';

/// LIFE LINK - Premium 3-screen onboarding experience.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  const OnboardingScreen({super.key, this.onFinish});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final AnimationController _rotateController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _rotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat();
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
        CurvedAnimation(parent: _rotateController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
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
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic);
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic);
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic);
  }

  static const _gradients = [
    [Color(0xFF8F1838), Color(0xFF6E1F3A)],
    [Color(0xFF087F8C), Color(0xFF065F6A)],
    [Color(0xFF267A5E), Color(0xFF1A5944)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final g = _gradients[_currentPage];
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            height: size.height * 0.52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [g[0], g[1], colors.background],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -60, right: -60,
            child: AnimatedBuilder(
              animation: _rotateAnim,
              builder: (_, __) => Transform.rotate(
                angle: _rotateAnim.value,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -20, right: -20,
            child: AnimatedBuilder(
              animation: _rotateAnim,
              builder: (_, __) => Transform.rotate(
                angle: -_rotateAnim.value * 0.6,
                child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.13), width: 2),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage > 0
                          ? GestureDetector(
                              onTap: _previousPage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            )
                          : _buildLogoMark(),
                      GestureDetector(
                        onTap: _completeOnboarding,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Skip',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildPage1(context),
                      _buildPage2(context),
                      _buildPage3(context),
                    ],
                  ),
                ),
                _buildBottomControls(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoMark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.water_drop_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Text('LIFE LINK',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5)),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    final colors = context.colors;
    final isLast = _currentPage == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                key: ValueKey('dot_indicator_$index'),
                onTap: () => _goToPage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 28 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primary
                        : colors.border.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLast
                    ? [const Color(0xFF267A5E), const Color(0xFF087F8C)]
                    : [colors.primary, const Color(0xFFC62845)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isLast ? colors.success : colors.primary)
                      .withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _nextPage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 1 - Every Drop Matters
  // ===========================================================================
  Widget _buildPage1(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value * 1.1,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5)
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.water_drop_rounded,
                              size: 52, color: colors.primary),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30, left: 10,
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, -_floatAnim.value * 0.6),
                        child: _buildFloatingBadge(
                            icon: Icons.person_rounded,
                            label: '12.4K Donors',
                            color: Colors.white,
                            textColor: colors.primary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40, right: 10,
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatAnim.value * 0.5),
                        child: _buildFloatingBadge(
                            icon: Icons.local_hospital_rounded,
                            label: '280+ Hospitals',
                            color: Colors.white,
                            textColor: const Color(0xFF087F8C)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, -_floatAnim.value * 0.7),
                        child: _buildFloatingBadge(
                            icon: Icons.favorite_rounded,
                            label: '3,800+ Lives Saved',
                            color: Colors.white,
                            textColor: const Color(0xFF267A5E)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildStepTag('01 / 03  \u2022  CONNECT', colors.primary),
            const SizedBox(height: 14),
            Text(
              'Every Drop\nMatters',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1,
                  color: colors.textPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              'LIFE LINK bridges blood donors with patients in urgent need \u2014 instantly, reliably, and with care.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.55, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: [
                _buildFeaturePill(Icons.bolt_rounded, 'Instant Match', colors),
                _buildFeaturePill(Icons.location_on_rounded, 'Near You', colors),
                _buildFeaturePill(Icons.notifications_active_rounded, 'Live Alerts', colors),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2 - Verified Requests, Real Lives
  // ===========================================================================
  Widget _buildPage2(BuildContext context) {
    final colors = context.colors;
    const teal = Color(0xFF087F8C);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                          colors: [teal.withValues(alpha: 0.18), Colors.transparent]),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    child: Transform.rotate(
                      angle: -0.06,
                      child: _buildRequestCardMini(colors,
                          bloodGroup: 'B+',
                          hospital: 'National Hospital',
                          urgency: 'MODERATE',
                          urgencyColor: colors.warning,
                          isBack: true),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _floatAnim.value * 0.5),
                      child: _buildRequestCardMini(colors,
                          bloodGroup: 'A+',
                          hospital: 'City General Hospital',
                          urgency: 'URGENT',
                          urgencyColor: colors.critical,
                          isBack: false,
                          showVerified: true),
                    ),
                  ),
                  Positioned(
                    top: 14, right: 30,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Transform.scale(
                        scale: 0.95 + (_pulseAnim.value - 0.92) * 0.5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.success,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: colors.success.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text('Verified',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildStepTag('02 / 03  \u2022  TRUST', teal),
            const SizedBox(height: 14),
            Text(
              'Verified Requests,\nReal Lives',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.8,
                  color: colors.textPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              'Every blood request is authenticated by hospitals and blood banks \u2014 so you always know your response saves a real life.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.55, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildTrustRow(
                icon: Icons.shield_rounded,
                color: colors.success,
                label: 'Hospital-Verified',
                sub: 'Confirmed by blood bank authorization',
                colors: colors),
            const SizedBox(height: 10),
            _buildTrustRow(
                icon: Icons.emergency_rounded,
                color: colors.critical,
                label: 'Urgency Levels',
                sub: 'Critical, Urgent and Moderate - always clear',
                colors: colors),
            const SizedBox(height: 10),
            _buildTrustRow(
                icon: Icons.location_on_rounded,
                color: teal,
                label: 'Nearby Matches',
                sub: 'Distance-aware request matching',
                colors: colors),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3 - Be the Link That Saves Lives
  // ===========================================================================
  Widget _buildPage3(BuildContext context) {
    final colors = context.colors;
    const green = Color(0xFF267A5E);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotateAnim,
                    builder: (_, __) => Transform.rotate(
                      angle: _rotateAnim.value * 0.4,
                      child: CustomPaint(
                        size: const Size(220, 220),
                        painter: _DashedCirclePainter(
                            color: green.withValues(alpha: 0.25),
                            dashCount: 20,
                            strokeWidth: 2.5),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: green.withValues(alpha: 0.3),
                                blurRadius: 28,
                                spreadRadius: 4)
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.favorite_rounded,
                              color: Color(0xFF8F1838), size: 46),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      top: 10,
                      child: _buildStatNode('3,800+', 'Lives Saved', green)),
                  Positioned(
                      left: 0,
                      child: _buildStatNode(
                          '12.4K', 'Donors', const Color(0xFF8F1838))),
                  Positioned(
                      right: 0,
                      child: _buildStatNode(
                          '280+', 'Hospitals', const Color(0xFF087F8C))),
                  Positioned(
                      bottom: 10,
                      child: _buildStatNode(
                          '48h', 'Avg. Response', colors.warning)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildStepTag('03 / 03  \u2022  IMPACT', green),
            const SizedBox(height: 14),
            Text(
              'Be the Link\nThat Saves Lives',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.8,
                  color: colors.textPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              'Join thousands of donors making a real difference. Track your impact, earn trust badges, and be a hero for someone today.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.55, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildJourneyStep(
                step: '1',
                icon: Icons.app_registration_rounded,
                title: 'Sign Up in 60 Seconds',
                sub: 'Create your donor profile instantly',
                color: const Color(0xFF8F1838),
                colors: colors),
            const SizedBox(height: 8),
            _buildJourneyStep(
                step: '2',
                icon: Icons.notifications_active_rounded,
                title: 'Get Matched Requests',
                sub: 'Alerts for your blood group and location',
                color: const Color(0xFF087F8C),
                colors: colors),
            const SizedBox(height: 8),
            _buildJourneyStep(
                step: '3',
                icon: Icons.volunteer_activism_rounded,
                title: 'Donate and Track Impact',
                sub: 'See lives you have touched, earn badges',
                color: green,
                colors: colors),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SHARED HELPER WIDGETS
  // ===========================================================================
  Widget _buildStepTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: color)),
    );
  }

  Widget _buildFloatingBadge(
      {required IconData icon,
      required String label,
      required Color color,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primary)),
        ],
      ),
    );
  }

  Widget _buildRequestCardMini(AppColors colors,
      {required String bloodGroup,
      required String hospital,
      required String urgency,
      required Color urgencyColor,
      required bool isBack,
      bool showVerified = false}) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isBack ? colors.surface.withValues(alpha: 0.7) : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isBack
                ? colors.border.withValues(alpha: 0.5)
                : colors.border),
        boxShadow: isBack
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: Text(bloodGroup,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(urgency,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: urgencyColor,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 4),
                Text(hospital,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (showVerified) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 12, color: colors.success),
                      const SizedBox(width: 3),
                      Text('Hospital Verified',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.success)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustRow(
      {required IconData icon,
      required Color color,
      required String label,
      required String sub,
      required AppColors colors}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatNode(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B6064))),
        ],
      ),
    );
  }

  Widget _buildJourneyStep(
      {required String step,
      required IconData icon,
      required String title,
      required String sub,
      required Color color,
      required AppColors colors}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(step,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Dashed Circle Painter for Screen 3 rotating ring
// =============================================================================
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  const _DashedCirclePainter(
      {required this.color,
      required this.dashCount,
      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    const gapAngle = math.pi / 60;
    final dashAngle = (2 * math.pi / dashCount) - gapAngle;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (2 * math.pi / dashCount);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, dashAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color || old.dashCount != dashCount;
}
