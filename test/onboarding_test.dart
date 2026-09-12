import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hci/theme/app_theme.dart';
import 'package:hci/screens/onboarding/onboarding_screen.dart';
import 'package:hci/screens/onboarding/onboarding_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Screen 1 renders with correct title, description, and controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Screen 1 content
      expect(find.text('Connect Blood Donors with Those in Need'), findsOneWidget);
      expect(
        find.text(
            'Find suitable blood donors faster and help patients receive the blood they urgently need.'),
        findsOneWidget,
      );
      expect(find.text('STEP 1 OF 3 • CONNECT'), findsOneWidget);

      // Healthcare illustration details
      expect(find.text('Active Volunteer'), findsOneWidget);
      expect(find.text('Urgent Care Unit'), findsOneWidget);
      expect(find.text('Instant Match'), findsOneWidget);

      // Controls
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('LifeLink'), findsOneWidget);
    });

    testWidgets('Next button navigates through all 3 screens, then Get Started triggers onFinish',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool finishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: OnboardingScreen(
            onFinish: () {
              finishedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen 1 is active
      expect(find.text('Connect Blood Donors with Those in Need'), findsOneWidget);

      // Tap Next to navigate to Screen 2
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      // Screen 2 content (Trusted & Verified Requests)
      expect(find.text('Trusted & Verified Requests'), findsOneWidget);
      expect(
        find.text(
            'Receive verified emergency blood requests and easily identify requests that have been confirmed by hospitals or blood banks.'),
        findsOneWidget,
      );
      expect(find.text('STEP 2 OF 3 • TRUST & VERIFICATION'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);
      expect(find.text('City General Hospital'), findsOneWidget);
      expect(find.text('URGENT EMERGENCY'), findsOneWidget);
      expect(find.text('Verified Hospital Request'), findsOneWidget);

      // Tap Next to navigate to Screen 3
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();

      // Screen 3 content (Respond & Track)
      expect(find.text('Respond and Stay Updated'), findsOneWidget);
      expect(
        find.text(
            'Respond to suitable blood requests and keep track of your responses and donation history in one place.'),
        findsOneWidget,
      );
      expect(find.text('STEP 3 OF 3 • ACTION & HISTORY'), findsOneWidget);
      expect(find.text('Emergency Request'), findsOneWidget);
      expect(find.text('Respond'), findsOneWidget);
      expect(find.text('Response Status'), findsOneWidget);
      expect(find.text('Donation History'), findsOneWidget);

      // Prominent Get Started button appears on Screen 3
      expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);

      // Tap Get Started
      await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
      await tester.pumpAndSettle();

      expect(finishedCalled, isTrue);

      // Verify SharedPreferences flag was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('lifelink_has_seen_onboarding'), isTrue);
    });

    testWidgets('Back button navigates backwards properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Screen 2
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Trusted & Verified Requests'), findsOneWidget);

      // Tap Back button in bottom controls
      await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
      await tester.pumpAndSettle();
      expect(find.text('Connect Blood Donors with Those in Need'), findsOneWidget);

      // Advance to Screen 3
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Respond and Stay Updated'), findsOneWidget);

      // Tap Back button in AppBar
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Trusted & Verified Requests'), findsOneWidget);
    });

    testWidgets('Skip button immediately triggers onFinish and persists seen flag',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool finishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: OnboardingScreen(
            onFinish: () {
              finishedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Skip from Screen 1
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(finishedCalled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('lifelink_has_seen_onboarding'), isTrue);
    });

    testWidgets('Page indicator dots allow direct tapping to switch screens',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on third dot indicator directly by key
      await tester.tap(find.byKey(const ValueKey('dot_indicator_2')));
      await tester.pumpAndSettle();

      expect(find.text('Respond and Stay Updated'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);
    });
  });

  group('OnboardingGate Unit & State Tests', () {
    test('OnboardingGate helper methods set and reset preference', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await OnboardingGate.hasSeenOnboarding(), isFalse);

      await OnboardingGate.markCompleted();
      expect(await OnboardingGate.hasSeenOnboarding(), isTrue);

      await OnboardingGate.resetForTesting();
      expect(await OnboardingGate.hasSeenOnboarding(), isFalse);
    });
  });
}
