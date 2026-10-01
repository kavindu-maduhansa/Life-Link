import '../models/blood_request.dart';

/// Free-text matching for the Verify Requests queue.
///
/// SCOPE (stated honestly in the UI too): this searches only the request
/// documents the queue has **already loaded** from its existing snapshot
/// stream. It issues no extra Firestore reads, so it costs nothing per
/// keystroke - and it cannot find a request outside the loaded window.
/// The search field's helper text says so, so staff never read an empty
/// result as "that request does not exist".

/// Which fields a query is matched against, in the order they are tried.
/// Exposed so the UI can list them in the search field's helper text
/// instead of the help going stale in a comment.
enum RequestSearchField {
  requestId,
  patientReference,
  patientName,
  bloodGroup,
  hospital,
  ward,
  requestingOfficer;

  String get label => switch (this) {
    RequestSearchField.requestId => 'Request ID',
    RequestSearchField.patientReference => 'Patient reference',
    RequestSearchField.patientName => 'Patient name',
    RequestSearchField.bloodGroup => 'Blood group',
    RequestSearchField.hospital => 'Hospital',
    RequestSearchField.ward => 'Ward',
    RequestSearchField.requestingOfficer => 'Requesting officer',
  };
}

/// Pure search/matching rules - no Firestore, no widgets.
class RequestSearch {
  const RequestSearch._();

  /// How long the UI waits after the last keystroke before filtering.
  /// Kept here so the debounce policy lives next to the search rules.
  static const Duration debounce = Duration(milliseconds: 250);

  /// A one-line description of what is searchable, for the helper text.
  static String get searchableFieldsSummary => RequestSearchField.values.map((f) => f.label).join(' · ');

  /// Which field matched, or null when nothing did. Returning the field
  /// (rather than a bool) lets the result card show *why* a request
  /// matched, which matters when searching a bare ID fragment.
  static RequestSearchField? matchField(BloodRequest request, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;

    if (_contains(request.id, q)) return RequestSearchField.requestId;
    if (_contains(request.patientReference, q)) return RequestSearchField.patientReference;
    if (_contains(request.patientName, q)) return RequestSearchField.patientName;
    if (_contains(request.bloodGroup, q)) return RequestSearchField.bloodGroup;
    if (_contains(request.hospitalName, q)) return RequestSearchField.hospital;
    if (_contains(request.ward, q)) return RequestSearchField.ward;
    if (_contains(request.requestingOfficerName, q)) return RequestSearchField.requestingOfficer;
    return null;
  }

  /// True when the request matches the query. An empty query matches
  /// everything, so clearing the field restores the full queue.
  static bool matches(BloodRequest request, String query) {
    if (query.trim().isEmpty) return true;
    return matchField(request, query) != null;
  }

  /// Filters an already-loaded list. Order is preserved so the caller's
  /// own sort (urgency, waiting time, …) still decides the order.
  static List<BloodRequest> filter(List<BloodRequest> requests, String query) {
    if (query.trim().isEmpty) return requests;
    return requests.where((r) => matches(r, query)).toList();
  }

  /// The result count line, e.g. '3 of 18 requests match "o+"'.
  static String resultCountLabel({required int shown, required int total, required String query}) {
    if (query.trim().isEmpty) {
      return total == 1 ? '1 request' : '$total requests';
    }
    return '$shown of $total requests match "${query.trim()}"';
  }

  /// Empty-state message for a query that matched nothing. Names the
  /// limitation rather than implying the request does not exist.
  static String get noMatchMessage =>
      'No request in the currently loaded queue matches that search. Requests outside the loaded window are not searched.';

  static bool _contains(String? value, String lowercaseQuery) {
    if (value == null) return false;
    return value.toLowerCase().contains(lowercaseQuery);
  }
}
