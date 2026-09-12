import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hci/screens/donor/donation_history_screen.dart';

void main() {
  group('DonationHistoryScreen Helper Unit Tests', () {
    test('formatDonationDate handles null and valid DateTime', () {
      expect(DonationHistoryScreen.formatDonationDate(null), 'Date not available');
      expect(DonationHistoryScreen.formatDonationDate(DateTime(2026, 8, 15, 10, 0)), '15 Aug 2026');
    });

    test('formatDonationDate handles ISO string format', () {
      expect(DonationHistoryScreen.formatDonationDate('2026-05-20T14:30:00.000'), '20 May 2026');
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

      expect(DonationHistoryScreen.getStatusConfig(context, 'completed').label, 'Completed');
      expect(DonationHistoryScreen.getStatusConfig(context, 'COMPLETED').label, 'Completed');
      expect(DonationHistoryScreen.getStatusConfig(context, 'verified').label, 'Verified');
      expect(DonationHistoryScreen.getStatusConfig(context, 'approved').label, 'Verified');
      expect(DonationHistoryScreen.getStatusConfig(context, 'pending').label, 'Pending');
      expect(DonationHistoryScreen.getStatusConfig(context, 'cancelled').label, 'Cancelled');
      expect(DonationHistoryScreen.getStatusConfig(context, 'CANCELED').label, 'Cancelled');
      expect(DonationHistoryScreen.getStatusConfig(context, null).label, 'Unknown');
      expect(DonationHistoryScreen.getStatusConfig(context, 'custom_status').label, 'custom_status');
    });
  });

  testWidgets('DonationHistoryScreen smoke test without authenticated user', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DonationHistoryScreen()));

    expect(find.text('Donation History'), findsOneWidget);
  });
}
