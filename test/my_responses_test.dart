import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hci/screens/donor/my_responses_screen.dart';

void main() {
  group('MyResponsesScreen Helper Unit Tests', () {
    test('formatResponseDate handles null and valid DateTime', () {
      expect(MyResponsesScreen.formatResponseDate(null), 'Recently submitted');
      expect(MyResponsesScreen.formatResponseDate(DateTime(2026, 8, 31, 15, 45)), '31 Aug 2026 at 15:45');
    });

    test('formatResponseDate handles ISO string format', () {
      expect(MyResponsesScreen.formatResponseDate('2026-11-20T08:30:00.000'), '20 Nov 2026 at 08:30');
    });

    // getStatusConfig now takes a BuildContext, because its colours come
    // from the active theme instead of hard-coded light-mode literals -
    // that is what gives this screen Dark Mode. The label assertions are
    // unchanged; the test just supplies a real context.
    testWidgets('getStatusConfig maps statuses accurately and case-insensitively', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(MyResponsesScreen.getStatusConfig(context, 'pending').label, 'Pending Review');
      expect(MyResponsesScreen.getStatusConfig(context, 'PENDING').label, 'Pending Review');
      expect(MyResponsesScreen.getStatusConfig(context, 'accepted').label, 'Accepted');
      expect(MyResponsesScreen.getStatusConfig(context, 'APPROVED').label, 'Accepted');
      expect(MyResponsesScreen.getStatusConfig(context, 'rejected').label, 'Rejected');
      expect(MyResponsesScreen.getStatusConfig(context, 'DECLINED').label, 'Rejected');
      expect(MyResponsesScreen.getStatusConfig(context, null).label, 'Pending Review');
      expect(MyResponsesScreen.getStatusConfig(context, 'unknown_status').label, 'Pending Review');
    });
  });

  testWidgets('MyResponsesScreen smoke test without authenticated user', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyResponsesScreen()));

    expect(find.text('My Responses'), findsOneWidget);
  });
}
