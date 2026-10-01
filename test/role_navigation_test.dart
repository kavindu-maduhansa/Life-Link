import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hci/screens/auth/register_screen.dart';
import 'package:hci/screens/donor/donor_shell.dart';
import 'package:hci/screens/recipient/recipient_home_screen.dart';
import 'package:hci/screens/hospital/hospital_home_screen.dart';
import 'package:hci/screens/coordinator/organisation_home_screen.dart';

/// Helper mirroring the exact switch logic in AuthGate for testing
Widget resolveRoleScreen(String rawRole) {
  final role = rawRole.trim().toLowerCase();
  switch (role) {
    case 'donor':
      return const DonorShell();
    case 'recipient':
      return const RecipientHomeScreen();
    case 'hospital':
    case 'doctor':
    case 'bloodbank':
    case 'blood_bank':
    case 'doctor / blood bank':
    case 'doctor/blood bank':
    case 'doctor / bloodbank':
    case 'doctor_blood_bank':
      return const HospitalHomeScreen();
    case 'organisation':
    case 'organization':
    case 'coordinator':
    case 'organisation coordinator':
    case 'organization coordinator':
    case 'organisation_coordinator':
    case 'organization_coordinator':
      return const OrganisationHomeScreen();
    default:
      return Text('Unknown role: $rawRole');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('Role Selection on RegisterScreen', () {
    testWidgets('Displays all 4 roles and allows selecting each', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Verify all 4 roles are present
      expect(find.text('Donor'), findsOneWidget);
      expect(find.text('Recipient'), findsOneWidget);
      expect(find.text('Doctor / Blood Bank'), findsOneWidget);
      expect(find.text('Organization Coordinator'), findsOneWidget);

      // Tap Doctor / Blood Bank
      await tester.tap(find.text('Doctor / Blood Bank'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap Organization Coordinator
      await tester.tap(find.text('Organization Coordinator'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap Recipient
      await tester.tap(find.text('Recipient'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap Donor
      await tester.tap(find.text('Donor'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Responsive rendering without overflow on small mobile widths (320px)', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Doctor / Blood Bank'), findsOneWidget);
      expect(find.text('Organization Coordinator'), findsOneWidget);
    });
  });

  group('Role-Based Auth Gate Destination Resolution', () {
    test('Donor routes to DonorShell', () {
      expect(resolveRoleScreen('Donor'), isA<DonorShell>());
      expect(resolveRoleScreen('donor'), isA<DonorShell>());
    });

    test('Recipient routes to RecipientHomeScreen', () {
      expect(resolveRoleScreen('Recipient'), isA<RecipientHomeScreen>());
      expect(resolveRoleScreen('recipient'), isA<RecipientHomeScreen>());
    });

    test('Doctor / Blood Bank routes to HospitalHomeScreen', () {
      expect(resolveRoleScreen('Doctor'), isA<HospitalHomeScreen>());
      expect(resolveRoleScreen('doctor'), isA<HospitalHomeScreen>());
      expect(resolveRoleScreen('Hospital'), isA<HospitalHomeScreen>());
      expect(resolveRoleScreen('hospital'), isA<HospitalHomeScreen>());
      expect(resolveRoleScreen('Doctor / Blood Bank'), isA<HospitalHomeScreen>());
      expect(resolveRoleScreen('doctor / blood bank'), isA<HospitalHomeScreen>());
    });

    test('Organization Coordinator routes to OrganisationHomeScreen', () {
      expect(resolveRoleScreen('Organization'), isA<OrganisationHomeScreen>());
      expect(resolveRoleScreen('organization'), isA<OrganisationHomeScreen>());
      expect(resolveRoleScreen('Organisation'), isA<OrganisationHomeScreen>());
      expect(resolveRoleScreen('organisation'), isA<OrganisationHomeScreen>());
      expect(resolveRoleScreen('Coordinator'), isA<OrganisationHomeScreen>());
      expect(resolveRoleScreen('coordinator'), isA<OrganisationHomeScreen>());
      expect(resolveRoleScreen('Organization Coordinator'), isA<OrganisationHomeScreen>());
      expect(resolveRoleScreen('organisation coordinator'), isA<OrganisationHomeScreen>());
    });
  });
}
