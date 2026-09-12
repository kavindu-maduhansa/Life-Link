import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tabs/donor_search_tab.dart';
import 'pdf_report.dart';
import '../../models/blood_inventory.dart';
import '../../models/blood_request.dart';
import '../../services/request_service.dart';
import '../../utils/request_assignment.dart';
import '../../utils/request_escalation.dart';
import '../../utils/request_status.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_states.dart';
import '../../widgets/request_health_badge.dart';
import '../../widgets/request_timeline.dart';
import '../../widgets/entrance_fade_slide.dart';

/// Full detail view for a single emergency blood request - the
/// "Emergency Blood Request Verification & Donor Coordination"
/// control surface for this request.
///
/// Combines:
///   FR08 - verification workflow (duplicate check, checklist, verify/reject)
///   FR09 - "Find Matching Donors" search launcher
///   FR10 - multi-donor response tracking + unit coordination
/// plus the timeline, audit trail, pinning, and PDF report added in
/// the second iteration of this module. All writes go through
/// [RequestService] rather than touching Firestore directly here.
class RequestDetailsScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final Map<String, bool> _checklist = {
    'Patient details are complete': false,
    'Blood group & units are valid': false,
    'Hospital/location confirmed': false,
  };
  bool _duplicateCheckDone = false;
  bool get _checklistComplete => _checklist.values.every((v) => v);

  final _service = RequestService.instance;

  /// True while an assignment transaction is in flight, so the claim /
  /// release / take-over buttons disable instead of allowing a second
  /// tap to queue another write.
  bool _assignmentBusy = false;

  DocumentReference<Map<String, dynamic>> get _requestRef => _service.requestRef(widget.requestId);

  String get _doctorId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _doctorName => FirebaseAuth.instance.currentUser?.email ?? 'Hospital Staff';

  Future<void> _runDuplicateCheck(BloodRequest request) async {
    if (_duplicateCheckDone || request.status != RequestStatus.pending) return;
    _duplicateCheckDone = true;
    try {
      final duplicates = await _service.findPossibleDuplicates(request);
      if (duplicates.isNotEmpty && mounted) {
        _showDuplicateDialog(duplicates);
      }
    } catch (_) {
      // Duplicate detection is a heads-up only (e.g. it needs a
      // Firestore composite index the first time it runs) - a
      // failure here must never block the doctor from verifying.
    }
  }

  /// Runs a Firestore-writing [action] and shows a friendly error
  /// snackbar instead of letting an unhandled Future exception (lost
  /// network, permission-denied, etc.) crash silently in the console.
  Future<void> _safeRun(Future<void> Function() action, {String? errorMessage}) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError ? e.message : (errorMessage ?? 'That action could not be completed. Please try again.');
      showErrorSnack(context, message);
    }
  }

  void _showDuplicateDialog(List<BloodRequest> duplicates) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Possible Duplicate Detected'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Possible duplicate request detected. This request shares the same hospital and blood group as another active request created around the same time. This is not a confirmed duplicate - please review before proceeding.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              ...duplicates
                  .take(3)
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${d.patientName} — ${d.bloodGroup} — ${RequestStatus.label(d.status)}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Verification')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.critical, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(requestId: duplicates.first.id)));
            },
            child: const Text('View Existing Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDonorSearch(BloodRequest request) async {
    final colors = context.colors;
    final donor = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Find Matching Donors'), backgroundColor: colors.surface, foregroundColor: colors.textPrimary),
          body: DonorSearchTab(selectMode: true, initialBloodGroupFilter: request.bloodGroup, requestLocation: request.location),
        ),
      ),
    );
    if (donor == null || !mounted) return;

    final units = await _promptUnitsPledged(request.unitsRemaining == 0 ? request.unitsNeeded : request.unitsRemaining);
    if (units == null || !mounted) return;

    try {
      await _service.notifyDonor(requestId: request.id, donor: donor, unitsPledged: units, doctorId: _doctorId, doctorName: _doctorName);
      if (mounted) showSuccessSnack(context, '${donor['donorName']} notified.');
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError ? e.message : 'Could not notify this donor. Please try again.';
      showErrorSnack(context, message);
    }
  }

  Future<int?> _promptUnitsPledged(int maxUnits) {
    final colors = context.colors;
    final safeMax = maxUnits < 1 ? 1 : maxUnits;
    int value = 1;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Units This Donor Will Provide'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: value > 1 ? () => setDialogState(() => value--) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: value < safeMax ? () => setDialogState(() => value++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, value),
              child: const Text('Notify Donor'),
            ),
          ],
        ),
      ),
    );
  }

  // #validation - a rejection with no real reason recorded breaks the
  // audit trail (a caregiver/hospital has no way to know what to fix
  // and resubmit) so this is now a real Form with a validator instead
  // of accepting whatever text.length happens to be, including empty.
  void _showRejectDialog(BloodRequest request) {
    final colors = context.colors;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'e.g. Incomplete patient details',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'A reason is required before rejecting a request.';
              if (v.length < 10) return 'Please provide a more specific reason (at least 10 characters).';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.critical, foregroundColor: Colors.white),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final reason = controller.text.trim();
              Navigator.pop(context);
              _safeRun(() => _service.rejectRequest(request, doctorId: _doctorId, doctorName: _doctorName, reason: reason));
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Ownership
  //
  // Every handler reports its outcome, including the conflict case:
  // "somebody else got there first" is information the operator needs,
  // not a silent no-op.
  // ---------------------------------------------------------------

  void _reportAssignment(AssignmentAttempt attempt, {String? action}) {
    if (!mounted) return;
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(attempt.message(action: action)),
        backgroundColor: attempt.succeeded ? null : colors.critical,
      ),
    );
  }

  Future<void> _claimRequest(BloodRequest request) async {
    if (!AssignmentRules.canClaim(assignedDoctorId: request.assignedDoctorId, currentUserId: _doctorId)) return;
    setState(() => _assignmentBusy = true);
    try {
      final attempt = await _service.claimRequest(requestId: request.id, doctorId: _doctorId, doctorName: _doctorName);
      _reportAssignment(attempt, action: 'claim this request');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not assign: $error')));
      }
    } finally {
      if (mounted) setState(() => _assignmentBusy = false);
    }
  }

  Future<void> _releaseRequest(BloodRequest request) async {
    if (!AssignmentRules.canRelease(assignedDoctorId: request.assignedDoctorId, currentUserId: _doctorId)) return;
    setState(() => _assignmentBusy = true);
    try {
      final attempt = await _service.releaseRequest(requestId: request.id, doctorId: _doctorId, doctorName: _doctorName);
      _reportAssignment(attempt, action: 'release this request');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not release: $error')));
      }
    } finally {
      if (mounted) setState(() => _assignmentBusy = false);
    }
  }

  /// Taking a request over from a colleague. The confirmation names
  /// them, because this is a handover, not a neutral click.
  Future<void> _reassignRequest(BloodRequest request) async {
    final owner = request.assignedDoctorName ?? 'another operator';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Take over this request?'),
        content: Text(
          'This request is currently assigned to $owner. Taking it over reassigns it to you '
          'and records the handover in the audit trail.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Take over')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _assignmentBusy = true);
    try {
      final attempt = await _service.reassignRequestToMe(requestId: request.id, doctorId: _doctorId, doctorName: _doctorName);
      _reportAssignment(attempt, action: 'reassign this request');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not reassign: $error')));
      }
    } finally {
      if (mounted) setState(() => _assignmentBusy = false);
    }
  }

  // ---------------------------------------------------------------
  // Escalation
  // ---------------------------------------------------------------

  Future<void> _showEscalationDialog(BloodRequest request, EscalationLevel next) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final colors = context.colors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Set escalation to ${next.label}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(next.meaning, style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.35)),
              const SizedBox(height: 14),
              TextFormField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. No donor response after 40 minutes',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Validated by the same rules the write path enforces,
                  // so the dialog can never accept something the service
                  // would then refuse.
                  final decision = EscalationRules.evaluate(
                    requestStatus: request.status,
                    current: request.escalationLevel,
                    next: next,
                    reason: value ?? '',
                  );
                  return decision.allowed ? null : decision.message;
                },
              ),
              const SizedBox(height: 10),
              Text(ResponseAttemptOutcome.disclaimer, style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.35)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: next == EscalationLevel.critical
                ? FilledButton.styleFrom(backgroundColor: colors.critical, foregroundColor: Colors.white)
                : null,
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text(next.rank > request.escalationLevel.rank ? 'Escalate' : 'Stand down'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final reason = controller.text.trim();

    final applied = await _service.setEscalationLevel(
      request: request,
      next: next,
      reason: reason,
      doctorId: _doctorId,
      doctorName: _doctorName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(applied ? 'Escalation set to ${next.label}.' : 'The escalation level was not changed.')));
  }

  /// Logs what a human did about the request. Deliberately not framed
  /// as "notify" - LifeLink sends nothing.
  Future<void> _showResponseAttemptSheet(BloodRequest request) async {
    final colors = context.colors;
    final outcome = await showModalBottomSheet<ResponseAttemptOutcome>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Record a response attempt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(ResponseAttemptOutcome.disclaimer, style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.35)),
            ),
            for (final option in ResponseAttemptOutcome.values)
              ListTile(
                leading: Icon(switch (option) {
                  ResponseAttemptOutcome.manualFollowUpRequired => Icons.pending_actions_rounded,
                  ResponseAttemptOutcome.contactedReached => Icons.phone_in_talk_rounded,
                  ResponseAttemptOutcome.contactedNoAnswer => Icons.phone_missed_rounded,
                }, color: colors.accent),
                title: Text(option.label),
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (outcome == null) return;

    await _service.recordResponseAttempt(requestId: request.id, outcome: outcome, doctorId: _doctorId, doctorName: _doctorName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recorded: ${outcome.label}')));
  }

  Future<void> _showTimelineNoteDialog(BloodRequest request) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add a timeline note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Anything the next operator should know', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add note')),
        ],
      ),
    );
    if (saved != true || controller.text.trim().isEmpty) return;

    await _service.addTimelineNote(requestId: request.id, note: controller.text, doctorId: _doctorId, doctorName: _doctorName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note added to the timeline.')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _requestRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
              final request = BloodRequest.fromDoc(snapshot.data!);
              final isPinned = request.isPinnedBy(_doctorId);
              return IconButton(
                tooltip: isPinned ? 'Unpin' : 'Pin as important',
                icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: () => _safeRun(() => _service.togglePin(request.id, _doctorId, !isPinned)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _requestRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateView(message: 'Unable to load this request right now.\n${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const LoadingState();
          }
          if (!snapshot.data!.exists) {
            return const EmptyState(icon: Icons.search_off_rounded, title: 'Not found', message: 'This request no longer exists.');
          }

          final request = BloodRequest.fromDoc(snapshot.data!);
          _runDuplicateCheck(request);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _requestRef.collection('responses').orderBy('notifiedAt', descending: true).snapshots(),
            builder: (context, responseSnap) {
              // Donor responses are non-critical to the rest of this
              // screen rendering - degrade to an empty list rather
              // than blocking the whole page on a transient error.
              final responses = responseSnap.hasError
                  ? const <DonorResponseRecord>[]
                  : (responseSnap.data?.docs ?? []).map(DonorResponseRecord.fromDoc).toList();

              var delayStep = 0;
              Widget staggered(Widget child) {
                final w = EntranceFadeSlide(
                  delay: Duration(milliseconds: 50 * delayStep),
                  child: child,
                );
                delayStep++;
                return w;
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  staggered(_PatientCaseSummaryCard(request: request)),

                  // Ownership and escalation sit directly under the case
                  // summary and above the status-specific actions: "who
                  // has this, and how loudly are we flagging it" is the
                  // first thing the next operator to open the screen
                  // needs to know.
                  const SizedBox(height: 16),
                  staggered(
                    _AssignmentCard(
                      request: request,
                      currentDoctorId: _doctorId,
                      busy: _assignmentBusy,
                      onClaim: () => _claimRequest(request),
                      onRelease: () => _releaseRequest(request),
                      onReassign: () => _reassignRequest(request),
                    ),
                  ),
                  const SizedBox(height: 16),
                  staggered(
                    _EscalationCard(
                      request: request,
                      onChangeLevel: (level) => _showEscalationDialog(request, level),
                      onRecordAttempt: () => _showResponseAttemptSheet(request),
                      onAddNote: () => _showTimelineNoteDialog(request),
                    ),
                  ),

                  if (request.status == RequestStatus.pending) ...[
                    const SizedBox(height: 16),
                    staggered(_ChecklistCard(checklist: _checklist, onChanged: (key, value) => setState(() => _checklist[key] = value))),
                    const SizedBox(height: 16),
                    staggered(
                      _VerifyActionsBar(
                        enabled: _checklistComplete,
                        request: request,
                        currentDoctorId: _doctorId,
                        onVerify: () => _safeRun(() => _service.verifyRequest(request, doctorId: _doctorId, doctorName: _doctorName)),
                        onReject: () => _showRejectDialog(request),
                      ),
                    ),
                  ],
                  if (request.status == RequestStatus.rejected) ...[
                    const SizedBox(height: 16),
                    staggered(
                      _ReVerificationCard(
                        request: request,
                        onRequestReVerification: () =>
                            _safeRun(() => _service.requestReVerification(request, doctorId: _doctorId, doctorName: _doctorName)),
                      ),
                    ),
                  ],
                  if (request.status == RequestStatus.verified) ...[
                    const SizedBox(height: 16),
                    staggered(_FindDonorsButton(onPressed: () => _openDonorSearch(request))),
                  ],
                  if (request.status == RequestStatus.matched || request.status == RequestStatus.fulfilled) ...[
                    const SizedBox(height: 16),
                    staggered(
                      _CoordinationCard(
                        request: request,
                        responses: responses,
                        onFindMore: () => _openDonorSearch(request),
                        onUpdateStatus: (responseId, donorId, donorName, status) => _safeRun(
                          () => _service.updateResponseStatus(
                            requestId: request.id,
                            responseId: responseId,
                            donorId: donorId,
                            donorName: donorName,
                            status: status,
                            doctorId: _doctorId,
                            doctorName: _doctorName,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  staggered(_TimelineCard(request: request, responses: responses)),
                  const SizedBox(height: 16),
                  staggered(_AuditTrailCard(requestId: request.id)),
                  const SizedBox(height: 16),
                  staggered(_PdfReportButton(request: request, responses: responses)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Patient Case Summary - the single source of truth the Doctor sees
/// when opening a request. Reads only fields that already exist on the
/// shared `requests` document (see `BloodRequest.fromDoc`); nothing
/// here is invented. Fields the current schema does not track (Age,
/// Gender, Ward, a distinct Required Date/Time) are shown as
/// "Not provided" instead of being fabricated - the Recipient module
/// owns request creation and this screen never writes patient data.
///
/// Visual hierarchy: identity header -> PATIENT INFORMATION ->
/// BLOOD REQUIREMENT -> REQUEST INFORMATION.
class _PatientCaseSummaryCard extends StatelessWidget {
  final BloodRequest request;
  const _PatientCaseSummaryCard({required this.request});

  /// Shown for any field the request document does not carry. The
  /// wording is deliberately "Not recorded" rather than a dash or a
  /// blank: it states that nobody entered a value, instead of leaving a
  /// reader to guess whether the field is empty, zero, or unsupported.
  static const _notRecorded = 'Not recorded';
  static const _notProvided = _notRecorded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = RequestStatus.color(request.status);
    final createdAtLabel = request.createdAt == null
        ? _notProvided
        : '${request.createdAt!.day.toString().padLeft(2, '0')}/${request.createdAt!.month.toString().padLeft(2, '0')}/${request.createdAt!.year}  ${request.createdAt!.hour.toString().padLeft(2, '0')}:${request.createdAt!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity header - who this case is about, at a glance.
          Row(
            children: [
              // #hero - continues the same blood-group avatar that was
              // tapped on the Dashboard/Verify/History card, instead of
              // a hard cut to a new screen.
              Hero(
                tag: 'bloodgroup-avatar-${request.id}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.critical.withValues(alpha: 0.1),
                  child: Text(
                    request.bloodGroup,
                    style: TextStyle(color: colors.critical, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.patientName,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(RequestStatus.icon(request.status), size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          RequestStatus.label(request.status),
                          style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RequestHealthBadge(request: request),

          const SizedBox(height: 12),
          _ClinicalBadges(request: request),

          const SizedBox(height: 16),
          _SectionLabel('PATIENT INFORMATION'),
          const SizedBox(height: 8),
          // #request-id - this row used to be labelled "Patient ID". It
          // is the Firestore *request* document id: it identifies the
          // request, not the person, and presenting it as a patient
          // identifier is wrong in a clinical setting. The hospital's
          // own patient identifier is the separate row below.
          _InfoRow(icon: Icons.tag_rounded, label: 'Request ID', value: request.id),
          _InfoRow(icon: Icons.badge_outlined, label: 'Patient Reference', value: request.patientReference ?? _notRecorded),
          _InfoRow(icon: Icons.person_outline_rounded, label: 'Patient Name', value: request.patientName),
          _InfoRow(icon: Icons.cake_outlined, label: 'Age', value: _notProvided),
          _InfoRow(icon: Icons.wc_rounded, label: 'Gender', value: _notProvided),

          Divider(height: 26, color: colors.border),
          _SectionLabel('BLOOD REQUIREMENT'),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.opacity_rounded, label: 'Blood Group', value: request.bloodGroup),
          _InfoRow(icon: Icons.science_outlined, label: 'Blood Component', value: request.bloodComponent ?? _notRecorded),
          _InfoRow(
            icon: Icons.numbers_rounded,
            label: 'Units Required',
            value: '${request.unitsConfirmed}/${request.unitsNeeded} confirmed · ${request.unitsRemaining} remaining',
          ),
          _InfoRow(
            icon: Icons.priority_high_rounded,
            label: 'Urgency',
            value: request.urgency,
            valueColor: UrgencyLevel.color(request.urgency),
          ),
          _InfoRow(
            icon: Icons.biotech_outlined,
            label: 'Crossmatch Status',
            value: CrossmatchStatus.label(request.crossmatchStatus),
            // Only an actually incompatible crossmatch is coloured as a
            // problem. An unrecorded one is a gap, not an alarm.
            valueColor: CrossmatchStatus.isBlocking(request.crossmatchStatus) ? colors.critical : null,
          ),

          Divider(height: 26, color: colors.border),
          _SectionLabel('REQUEST INFORMATION'),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.local_hospital_outlined, label: 'Hospital', value: request.hospitalName),
          _InfoRow(icon: Icons.domain_outlined, label: 'Facility ID', value: request.hospitalId ?? _notRecorded),
          _InfoRow(icon: Icons.meeting_room_outlined, label: 'Ward', value: request.ward ?? _notRecorded),
          _InfoRow(icon: Icons.place_outlined, label: 'Location', value: request.location),
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Required By',
            value: request.requiredAt == null ? _notRecorded : _formatDateTime(request.requiredAt!),
          ),
          _InfoRow(icon: Icons.assignment_ind_outlined, label: 'Requesting Officer', value: request.requestingOfficerName ?? _notRecorded),
          _InfoRow(icon: Icons.dialpad_rounded, label: 'Contact Extension', value: request.contactExtension ?? _notRecorded),
          _InfoRow(icon: Icons.person_pin_outlined, label: 'Requested By', value: request.createdByName),
          if (request.clinicalNotes != null)
            _InfoRow(icon: Icons.medical_information_outlined, label: 'Clinical Notes', value: request.clinicalNotes!),
          if (request.notes.isNotEmpty) _InfoRow(icon: Icons.notes_rounded, label: 'Request Notes', value: request.notes),
          _InfoRow(icon: Icons.schedule_outlined, label: 'Request Created', value: createdAtLabel),
          if (request.verifiedBy != null) _InfoRow(icon: Icons.verified_rounded, label: 'Verified By', value: request.verifiedBy!),
          if (request.secondApproverName != null)
            _InfoRow(
              icon: Icons.how_to_reg_outlined,
              label: 'Co-signed By',
              value: '${request.firstApproverName ?? 'First approver'} + ${request.secondApproverName}',
            ),
          if (request.rejectionReason != null)
            _InfoRow(icon: Icons.report_outlined, label: 'Rejection Reason', value: request.rejectionReason!, valueColor: colors.critical),

          const SizedBox(height: 14),
          // The disclaimer belongs inside the clinical summary, not in a
          // footnote elsewhere: anybody reading these figures should
          // read this in the same glance.
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: colors.elevatedSurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LifeLink supports coordination only. It does not replace clinical compatibility '
                    'testing, laboratory crossmatching, or your hospital\'s transfusion protocol. '
                    'Anything shown as "Not recorded" was never entered — no value has been assumed.',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d/$m/${value.year}  $h:$min';
  }
}

/// Who owns this request, and the actions to change that.
///
/// The card always states the ownership situation in words before it
/// offers a button, so an operator who opens a request mid-shift knows
/// whether somebody else is already working it.
class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.request,
    required this.currentDoctorId,
    required this.busy,
    required this.onClaim,
    required this.onRelease,
    required this.onReassign,
  });

  final BloodRequest request;
  final String currentDoctorId;

  /// True while an ownership transaction is in flight. Every button is
  /// disabled, so a second tap cannot queue a second write.
  final bool busy;

  final VoidCallback onClaim;
  final VoidCallback onRelease;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = AssignmentRules.stateFor(assignedDoctorId: request.assignedDoctorId, currentUserId: currentDoctorId);

    final (Color tone, Color container, IconData icon, String headline) = switch (state) {
      AssignmentState.unassigned => (colors.warning, colors.warningContainer, Icons.person_off_outlined, 'Nobody is working this request'),
      AssignmentState.assignedToMe => (colors.accent, colors.accentContainer, Icons.assignment_ind_rounded, 'Assigned to you'),
      AssignmentState.assignedToOther => (
        colors.textSecondary,
        colors.elevatedSurface,
        Icons.people_alt_outlined,
        'Assigned to ${request.assignedDoctorName ?? 'another operator'}',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: container, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: tone),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.assignedAt == null
                          ? 'Claiming a request tells the rest of the team you have it.'
                          : 'Since ${_PatientCaseSummaryCard._formatDateTime(request.assignedAt!)}',
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (AssignmentRules.canClaim(assignedDoctorId: request.assignedDoctorId, currentUserId: currentDoctorId))
                FilledButton.icon(
                  onPressed: busy ? null : onClaim,
                  icon: busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: Text(busy ? 'Assigning...' : 'Assign to me'),
                ),
              if (AssignmentRules.canRelease(assignedDoctorId: request.assignedDoctorId, currentUserId: currentDoctorId))
                OutlinedButton.icon(
                  onPressed: busy ? null : onRelease,
                  icon: const Icon(Icons.person_remove_outlined, size: 18),
                  label: const Text('Release assignment'),
                ),
              if (state == AssignmentState.assignedToOther)
                OutlinedButton.icon(
                  onPressed: busy ? null : onReassign,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Take over'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Escalation level, the actions that change it, and the honest
/// statement that LifeLink itself contacts nobody.
class _EscalationCard extends StatelessWidget {
  const _EscalationCard({required this.request, required this.onChangeLevel, required this.onRecordAttempt, required this.onAddNote});

  final BloodRequest request;
  final ValueChanged<EscalationLevel> onChangeLevel;
  final VoidCallback onRecordAttempt;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = request.escalationLevel;
    final isClosed = RequestStatus.historyStatuses.contains(request.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: current == EscalationLevel.critical ? colors.critical.withValues(alpha: 0.5) : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Escalation',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ),
              _ClinicalBadge(
                icon: current.isRaised ? Icons.priority_high_rounded : Icons.remove_rounded,
                label: current.label,
                tone: _toneFor(current, colors).$1,
                container: _toneFor(current, colors).$2,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(current.meaning, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35)),
          if (request.escalationNote != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'Last reason: ${request.escalationNote}',
                style: TextStyle(fontSize: 11.5, color: colors.textPrimary, height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isClosed)
            Text(
              'This request is closed, so its escalation level can no longer be changed.',
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: colors.textSecondary),
            )
          else ...[
            Text(
              'SET LEVEL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: colors.textSecondary),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final level in EscalationLevel.values)
                  _EscalationLevelButton(
                    level: level,
                    selected: level == current,
                    onPressed: level == current ? null : () => onChangeLevel(level),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRecordAttempt,
                  icon: const Icon(Icons.phone_forwarded_outlined, size: 18),
                  label: const Text('Record response attempt'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddNote,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Add timeline note'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(ResponseAttemptOutcome.disclaimer, style: TextStyle(fontSize: 10.5, color: colors.textSecondary, height: 1.35)),
          ],
        ],
      ),
    );
  }

  static (Color, Color) _toneFor(EscalationLevel level, AppColors colors) => switch (level) {
    EscalationLevel.normal => (colors.textSecondary, colors.elevatedSurface),
    EscalationLevel.watch => (colors.accent, colors.accentContainer),
    EscalationLevel.urgent => (colors.warning, colors.warningContainer),
    EscalationLevel.critical => (colors.critical, colors.criticalContainer),
  };
}

class _EscalationLevelButton extends StatelessWidget {
  const _EscalationLevelButton({required this.level, required this.selected, this.onPressed});

  final EscalationLevel level;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (tone, container) = _EscalationCard._toneFor(level, colors);

    return Semantics(
      selected: selected,
      button: true,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? tone : colors.textSecondary,
          backgroundColor: selected ? container : Colors.transparent,
          side: BorderSide(color: selected ? tone : colors.border),
          // Comfortably above the 44dp accessibility floor.
          minimumSize: const Size(88, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        // Selection is a check plus the colour, never colour alone.
        icon: Icon(selected ? Icons.check_rounded : Icons.circle_outlined, size: 14),
        label: Text(level.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// The status badge strip under the case header.
///
/// Each badge pairs an icon with its text, so a badge is still readable
/// without colour - and a field that was never recorded gets a neutral
/// "not recorded" badge rather than being silently omitted.
class _ClinicalBadges extends StatelessWidget {
  const _ClinicalBadges({required this.request});

  final BloodRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final crossmatchBlocking = CrossmatchStatus.isBlocking(request.crossmatchStatus);

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _ClinicalBadge(icon: Icons.opacity_rounded, label: request.bloodGroup, tone: colors.primary, container: colors.primaryContainer),
        _ClinicalBadge(
          icon: Icons.science_outlined,
          label: request.bloodComponent == null ? 'Component not recorded' : BloodComponent.shortLabel(request.bloodComponent!),
          tone: request.bloodComponent == null ? colors.textSecondary : colors.accent,
          container: request.bloodComponent == null ? colors.elevatedSurface : colors.accentContainer,
        ),
        _ClinicalBadge(
          icon: Icons.priority_high_rounded,
          label: '${request.urgency} urgency',
          tone: request.urgency == UrgencyLevel.critical ? colors.critical : colors.warning,
          container: request.urgency == UrgencyLevel.critical ? colors.criticalContainer : colors.warningContainer,
        ),
        _ClinicalBadge(
          icon: Icons.biotech_outlined,
          label: CrossmatchStatus.label(request.crossmatchStatus),
          tone: crossmatchBlocking ? colors.critical : (request.crossmatchStatus == null ? colors.textSecondary : colors.accent),
          container: crossmatchBlocking
              ? colors.criticalContainer
              : (request.crossmatchStatus == null ? colors.elevatedSurface : colors.accentContainer),
        ),
        _ClinicalBadge(
          icon: RequestStatus.icon(request.status),
          label: RequestStatus.label(request.status),
          tone: request.status == RequestStatus.verified || request.status == RequestStatus.fulfilled
              ? colors.success
              : colors.textSecondary,
          container: request.status == RequestStatus.verified || request.status == RequestStatus.fulfilled
              ? colors.successContainer
              : colors.elevatedSurface,
        ),
        _ClinicalBadge(
          icon: request.unitsRemaining == 0 ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
          label: request.unitsRemaining == 0
              ? 'All ${request.unitsNeeded} unit(s) covered'
              : '${request.unitsRemaining} unit(s) still needed',
          tone: request.unitsRemaining == 0 ? colors.success : colors.warning,
          container: request.unitsRemaining == 0 ? colors.successContainer : colors.warningContainer,
        ),
      ],
    );
  }
}

class _ClinicalBadge extends StatelessWidget {
  const _ClinicalBadge({required this.icon, required this.label, required this.tone, required this.container});

  final IconData icon;
  final String label;
  final Color tone;
  final Color container;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: tone),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: colors.textSecondary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: colors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final Map<String, bool> checklist;
  final void Function(String, bool) onChanged;
  const _ChecklistCard({required this.checklist, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Checklist',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text('Confirm each item before verifying this request.', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ...checklist.keys.map(
            (key) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: checklist[key],
              onChanged: (v) => onChanged(key, v ?? false),
              activeColor: colors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(key, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

/// #two-person-verification - for a Critical request, the first tap of
/// "Verify Request" only records that staff member's co-sign (status
/// stays pending); a genuinely different staff member has to tap it a
/// second time to actually move the request to `verified`. The same
/// doctor cannot approve their own first co-sign. Every other urgency
/// level keeps the original single-tap flow.
class _VerifyActionsBar extends StatelessWidget {
  final bool enabled;
  final BloodRequest request;
  final String currentDoctorId;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  const _VerifyActionsBar({
    required this.enabled,
    required this.request,
    required this.currentDoctorId,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final awaitingSecond = request.awaitingSecondApproval;
    final isSelfApprover = awaitingSecond && request.firstApproverId == currentDoctorId;
    final canVerifyNow = enabled && !isSelfApprover;

    final String verifyLabel;
    if (awaitingSecond) {
      verifyLabel = isSelfApprover ? 'Waiting for 2nd staff member' : 'Confirm 2nd Approval & Verify';
    } else if (request.urgency == 'Critical') {
      verifyLabel = 'Give 1st Approval';
    } else {
      verifyLabel = 'Verify Request';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (awaitingSecond)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gpp_maybe_outlined, size: 16, color: colors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSelfApprover
                        ? 'You gave the first approval on this critical request. A different staff member must confirm before it is verified.'
                        : '${request.firstApproverName ?? 'A staff member'} gave the first approval. Confirming below records your name as the second, independent approver.',
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: Icon(Icons.close_rounded, color: colors.critical),
                label: Text('Reject', style: TextStyle(color: colors.critical)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.critical),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canVerifyNow ? onVerify : null,
                icon: Icon(awaitingSecond ? Icons.how_to_reg_rounded : Icons.verified_rounded),
                label: Text(verifyLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colors.border,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// #10 - Re-verification workflow entry point for a rejected request.
class _ReVerificationCard extends StatelessWidget {
  final BloodRequest request;
  final VoidCallback onRequestReVerification;
  const _ReVerificationCard({required this.request, required this.onRequestReVerification});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rejected Request',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'If the recipient has updated this request with corrected information, you can send it back into the verification queue.',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRequestReVerification,
              icon: Icon(Icons.replay_rounded, color: colors.primary),
              label: Text('Send for Re-verification', style: TextStyle(color: colors.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FindDonorsButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _FindDonorsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.search_rounded),
        label: const Text('Find Matching Donors'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// #6/#7 - Donor response rate + multi-donor unit coordination.
class _CoordinationCard extends StatelessWidget {
  final BloodRequest request;
  final List<DonorResponseRecord> responses;
  final VoidCallback onFindMore;
  final Future<void> Function(String responseId, String donorId, String donorName, String status) onUpdateStatus;

  const _CoordinationCard({required this.request, required this.responses, required this.onFindMore, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notified = responses.length;
    final responded = responses.where((r) => r.status != 'notified').length;
    final responseRate = notified == 0 ? null : (responded / notified * 100).round();
    final progress = request.unitsNeeded == 0 ? 0.0 : (request.unitsConfirmed / request.unitsNeeded).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Donor Coordination',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ),
              if (request.status != RequestStatus.fulfilled)
                TextButton.icon(
                  onPressed: onFindMore,
                  icon: Icon(Icons.add_rounded, size: 18, color: colors.primary),
                  label: Text('Notify More', style: TextStyle(color: colors.primary, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${request.unitsConfirmed} / ${request.unitsNeeded} Units Confirmed',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
              const Spacer(),
              if (request.unitsRemaining > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${request.unitsRemaining} unit(s) remaining',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.warning),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 11, color: colors.success),
                      const SizedBox(width: 3),
                      Text(
                        'Fully covered',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: colors.elevatedSurface,
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            notified == 0 ? 'No donors notified yet.' : '$notified notified · $responded responded · ${responseRate ?? 0}% response rate',
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
          Divider(height: 24, color: colors.border),
          if (responses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('No donors notified yet.', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            )
          else
            ...responses.map((r) => _ResponseRow(response: r, onUpdateStatus: onUpdateStatus)),
        ],
      ),
    );
  }
}

class _ResponseRow extends StatelessWidget {
  final DonorResponseRecord response;
  final Future<void> Function(String responseId, String donorId, String donorName, String status) onUpdateStatus;
  const _ResponseRow({required this.response, required this.onUpdateStatus});

  Color _statusColor(AppColors colors) {
    switch (response.status) {
      case 'accepted':
        return colors.primary;
      case 'declined':
        return colors.critical;
      case 'completed':
        return colors.success;
      default:
        return colors.warning;
    }
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = _statusColor(colors);
    final declined = response.status == 'declined';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: declined ? colors.critical.withValues(alpha: 0.04) : colors.elevatedSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: declined ? colors.critical.withValues(alpha: 0.25) : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, size: 18, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.donorName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    Text(
                      response.status == 'completed'
                          ? '${response.unitsPledged} unit(s) confirmed'
                          : '${response.unitsPledged} unit(s) pledged',
                      style: TextStyle(
                        fontSize: 11,
                        color: response.status == 'completed' ? colors.success : colors.textSecondary,
                        fontWeight: response.status == 'completed' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (response.status == 'notified')
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.textSecondary),
                  onSelected: (value) => onUpdateStatus(response.id, response.donorId, response.donorName, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'accepted', child: Text('Mark Accepted')),
                    PopupMenuItem(value: 'declined', child: Text('Mark Declined')),
                  ],
                ),
              if (response.status == 'accepted')
                TextButton(
                  onPressed: () => onUpdateStatus(response.id, response.donorId, response.donorName, 'completed'),
                  child: Text('Mark Completed', style: TextStyle(color: colors.primary, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // #7 - a real progress tracker built only from the fields
          // this response actually has (notifiedAt / respondedAt /
          // status) - no invented "viewed" stage, since that isn't
          // tracked anywhere in Firestore yet.
          _ResponseStageTracker(response: response),
        ],
      ),
    );
  }
}

/// #7 - Donor Response Tracking mini-funnel for a single donor:
/// Notified -> Responded (Accepted/Declined) -> Completed, each dot
/// timestamped from the real `notifiedAt`/`respondedAt` fields.
class _ResponseStageTracker extends StatelessWidget {
  final DonorResponseRecord response;
  const _ResponseStageTracker({required this.response});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final declined = response.status == 'declined';
    final reachedResponded = response.status != 'notified';
    final reachedCompleted = response.status == 'completed';
    final lineColor = declined ? colors.critical : colors.success;

    final stages = [
      ('Notified', true, response.notifiedAt),
      (declined ? 'Declined' : 'Responded', reachedResponded, response.respondedAt),
      ('Completed', reachedCompleted, reachedCompleted ? response.respondedAt : null),
    ];

    return Row(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2, color: stages[i].$2 ? lineColor.withValues(alpha: 0.5) : colors.border)),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stages[i].$2 ? (declined && i > 0 ? colors.critical : lineColor) : colors.border,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stages[i].$1,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: stages[i].$2 ? colors.textPrimary : colors.textSecondary,
                ),
              ),
              if (stages[i].$3 != null)
                Text(_ResponseRow._formatTime(stages[i].$3), style: TextStyle(fontSize: 9, color: colors.textSecondary)),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final BloodRequest request;
  final List<DonorResponseRecord> responses;
  const _TimelineCard({required this.request, required this.responses});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Timeline',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          RequestTimeline(request: request, responses: responses),
        ],
      ),
    );
  }
}

class _AuditTrailCard extends StatefulWidget {
  final String requestId;
  const _AuditTrailCard({required this.requestId});

  @override
  State<_AuditTrailCard> createState() => _AuditTrailCardState();
}

class _AuditTrailCardState extends State<_AuditTrailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Audit Trail',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                ),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: colors.textSecondary),
              ],
            ),
          ),
          if (_expanded)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: RequestService.instance.auditTrail(widget.requestId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Audit trail is temporarily unavailable.', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LoadingState());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No audit entries yet.', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: docs.map((doc) {
                      final data = doc.data();
                      final ts = (data['timestamp'] as Timestamp?)?.toDate();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 6, color: colors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_actionLabel(data['action'] as String? ?? '')} — ${data['performedByName'] ?? ''}${ts != null ? ' (${_fmt(ts)})' : ''}',
                                style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static String _actionLabel(String action) => action.replaceAll('_', ' ');

  static String _fmt(DateTime dt) {
    final l = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}, ${l.day}/${l.month}';
  }
}

class _PdfReportButton extends StatelessWidget {
  final BloodRequest request;
  final List<DonorResponseRecord> responses;
  const _PdfReportButton({required this.request, required this.responses});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          List<Map<String, dynamic>> entries = const [];
          try {
            final auditSnap = await RequestService.instance.auditTrail(request.id).first;
            entries = auditSnap.docs.map((doc) {
              final data = doc.data();
              final ts = (data['timestamp'] as Timestamp?)?.toDate();
              return {
                'action': (data['action'] as String? ?? '').replaceAll('_', ' '),
                'performedByName': data['performedByName'],
                'timestampLabel': ts == null ? '' : '${ts.toLocal()}'.split('.').first,
              };
            }).toList();
          } catch (_) {
            // Report generation should still proceed with an empty
            // audit section rather than failing outright.
          }

          if (context.mounted) {
            await generateRequestReport(context: context, request: request, responses: responses, auditEntries: entries);
          }
        },
        icon: Icon(Icons.picture_as_pdf_outlined, color: colors.primary),
        label: Text('Generate PDF Report', style: TextStyle(color: colors.primary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
