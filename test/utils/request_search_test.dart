import 'package:flutter_test/flutter_test.dart';

import 'package:hci/models/blood_request.dart';
import 'package:hci/utils/request_search.dart';

/// Tests for the Verify Requests queue search.
void main() {
  BloodRequest request({
    String id = 'req-abc123',
    String? patientReference,
    String patientName = 'A. Perera',
    String bloodGroup = 'O+',
    String hospitalName = 'General Hospital',
    String? ward,
    String? officer,
  }) {
    return BloodRequest.fromMap(id, {
      'patientName': patientName,
      'bloodGroup': bloodGroup,
      'hospitalName': hospitalName,
      'unitsNeeded': 2,
      'urgency': 'High',
      'status': 'pending',
      'patientReference': ?patientReference,
      'ward': ?ward,
      'requestingOfficerName': ?officer,
    });
  }

  group('matchField - which field matched', () {
    test('matches a request id fragment', () {
      expect(RequestSearch.matchField(request(), 'abc'), RequestSearchField.requestId);
    });

    test('matches a patient reference', () {
      expect(RequestSearch.matchField(request(patientReference: 'MRN-88213'), '88213'), RequestSearchField.patientReference);
    });

    test('matches a patient name', () {
      expect(RequestSearch.matchField(request(), 'perera'), RequestSearchField.patientName);
    });

    test('matches a blood group', () {
      expect(RequestSearch.matchField(request(id: 'r1', bloodGroup: 'AB-'), 'ab-'), RequestSearchField.bloodGroup);
    });

    test('matches a hospital name', () {
      expect(RequestSearch.matchField(request(id: 'r1'), 'general'), RequestSearchField.hospital);
    });

    test('matches a ward', () {
      expect(RequestSearch.matchField(request(id: 'r1', ward: 'ICU 2'), 'icu'), RequestSearchField.ward);
    });

    test('matches a requesting officer', () {
      expect(RequestSearch.matchField(request(id: 'r1', officer: 'Dr. N. Fernando'), 'fernando'), RequestSearchField.requestingOfficer);
    });

    test('returns null when nothing matches', () {
      expect(RequestSearch.matchField(request(), 'zzzz'), isNull);
    });

    test('an empty query matches no specific field', () {
      expect(RequestSearch.matchField(request(), '   '), isNull);
    });

    test('search is case-insensitive and ignores surrounding whitespace', () {
      expect(RequestSearch.matchField(request(), '  PERERA  '), RequestSearchField.patientName);
    });

    test('a field that is not recorded is skipped rather than matching empty', () {
      // No ward recorded; a query for a blank-ish string must not match it.
      final r = request(id: 'r1');
      expect(r.ward, isNull);
      expect(RequestSearch.matchField(r, 'icu'), isNull);
    });
  });

  group('matches', () {
    test('an empty query matches everything, so clearing restores the queue', () {
      expect(RequestSearch.matches(request(), ''), isTrue);
      expect(RequestSearch.matches(request(), '    '), isTrue);
    });

    test('a non-matching query excludes the request', () {
      expect(RequestSearch.matches(request(), 'nothing-like-this'), isFalse);
    });
  });

  group('filter', () {
    final all = [
      request(id: 'req-1', patientName: 'A. Perera', bloodGroup: 'O+'),
      request(id: 'req-2', patientName: 'B. Silva', bloodGroup: 'O-'),
      request(id: 'req-3', patientName: 'C. Jayasuriya', bloodGroup: 'AB+', ward: 'ICU 2'),
    ];

    test('returns the same list instance semantics for an empty query', () {
      expect(RequestSearch.filter(all, '').length, all.length);
    });

    test('narrows to matching requests only', () {
      final result = RequestSearch.filter(all, 'silva');
      expect(result.length, 1);
      expect(result.single.id, 'req-2');
    });

    test('preserves the caller\'s ordering', () {
      final result = RequestSearch.filter(all, 'o');
      expect(result.map((r) => r.id).toList(), ['req-1', 'req-2', 'req-3']);
    });

    test('an unmatched query yields an empty list, not an error', () {
      expect(RequestSearch.filter(all, 'qqq'), isEmpty);
    });
  });

  group('resultCountLabel', () {
    test('shows a plain total when there is no query', () {
      expect(RequestSearch.resultCountLabel(shown: 18, total: 18, query: ''), '18 requests');
    });

    test('uses the singular for one request', () {
      expect(RequestSearch.resultCountLabel(shown: 1, total: 1, query: ''), '1 request');
    });

    test('shows shown-of-total and echoes the query', () {
      final label = RequestSearch.resultCountLabel(shown: 3, total: 18, query: ' o+ ');
      expect(label, contains('3 of 18'));
      expect(label, contains('"o+"'));
    });
  });

  group('stated scope', () {
    test('the empty-state message admits it only searched the loaded window', () {
      final text = RequestSearch.noMatchMessage.toLowerCase();
      expect(text, contains('loaded'));
      expect(text, contains('not searched'));
    });

    test('the searchable-fields summary lists every field the matcher tries', () {
      final summary = RequestSearch.searchableFieldsSummary;
      for (final field in RequestSearchField.values) {
        expect(summary, contains(field.label));
      }
    });

    test('the debounce is short enough to feel live but not per-keystroke', () {
      expect(RequestSearch.debounce.inMilliseconds, greaterThan(100));
      expect(RequestSearch.debounce.inMilliseconds, lessThan(600));
    });
  });
}
