// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hci/screens/auth/register_screen.dart';
import 'package:hci/screens/donor/donor_home_screen.dart';
import 'package:hci/screens/recipient/recipient_home_screen.dart';
import 'package:hci/screens/hospital/hospital_home_screen.dart';
import 'package:hci/screens/coordinator/organisation_home_screen.dart';

void main() {
  // The Recipient, Hospital and Organisation home screens read
  // FirebaseAuth.instance.currentUser while building, which throws
  // [core/no-app] unless a Firebase app exists. These mocks stand a default
  // app up in-process so the screens can be pumped; they do not talk to any
  // real Firebase project and assert nothing about backend behaviour.
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('RegisterScreen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Select your role'), findsOneWidget);
    expect(find.text('Donor'), findsOneWidget);
    expect(find.text('Recipient'), findsOneWidget);
    expect(find.text('Doctor / Blood Bank'), findsOneWidget);
    expect(find.text('Organization Coordinator'), findsOneWidget);
  });

  testWidgets('DonorHomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DonorHomeScreen(),
      ),
    );
    expect(find.text('Donor Dashboard'), findsOneWidget);
    expect(find.text('Your Donation Profile'), findsOneWidget);
  });

  testWidgets('RecipientHomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RecipientHomeScreen(),
      ),
    );
    expect(find.text('Recipient Home'), findsOneWidget);
    expect(find.text('Recipient Area'), findsOneWidget);
  });

  testWidgets('HospitalHomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HospitalHomeScreen(),
      ),
    );
    // The placeholder 'Hospital Home' / 'Hospital Area' card was replaced by
    // the real Doctor / Blood Bank shell, so this asserts the shell that is
    // actually built now: a 'Dashboard' app bar title plus the four
    // navigation destinations.
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Verify Requests'), findsOneWidget);
    expect(find.text('Donor Search'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('OrganisationHomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrganisationHomeScreen(),
      ),
    );
    expect(find.text('Organisation Home'), findsOneWidget);
    expect(find.text('Organisation Area'), findsOneWidget);
  });
}
