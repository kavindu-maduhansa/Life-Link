import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_gate.dart';
import 'onboarding_screen.dart';

/// Routes new users through the 3-screen onboarding experience on first launch.
///
/// If onboarding has already been completed or skipped, it routes directly to
/// [AuthGate], which preserves the entire existing Firebase authentication
/// and role-based application logic.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  /// Preference key used to persist whether onboarding has been completed.
  static const String prefsKey = 'lifelink_has_seen_onboarding';

  /// Helper to check whether onboarding has already been seen.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  /// Helper for user testing and prototype demonstrations to reset the onboarding state.
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }

  /// Helper to mark onboarding as completed.
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(OnboardingGate.prefsKey) ?? false;

    if (mounted) {
      setState(() {
        _hasSeenOnboarding = seen;
        _isLoading = false;
      });
    }
  }

  void _onOnboardingComplete() {
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F6),
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF8F1838),
            ),
          ),
        ),
      );
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        onFinish: _onOnboardingComplete,
      );
    }

    return const AuthGate();
  }
}
