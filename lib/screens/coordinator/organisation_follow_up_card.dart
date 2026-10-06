import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrganisationFollowUpCard extends StatefulWidget {
  final String donorUid;
  final String donorCode;

  const OrganisationFollowUpCard({
    super.key,
    required this.donorUid,
    required this.donorCode,
  });

  @override
  State<OrganisationFollowUpCard> createState() =>
      _OrganisationFollowUpCardState();
}

class _OrganisationFollowUpCardState extends State<OrganisationFollowUpCard> {
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color borderColor = Color(0xFFE6DADD);

  static const List<String> _statuses = [
    'To contact',
    'Contacted',
    'Confirmed',
    'Not needed',
  ];

  final TextEditingController _noteController = TextEditingController();
  String _status = 'To contact';
  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>>? get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('coordinatorFollowUps')
        .doc('${uid}_${widget.donorUid}');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ref = _ref;
      if (ref != null) {
        final snap = await ref.get();
        final data = snap.data();
        if (data != null) {
          final s = data['status']?.toString() ?? '';
          if (_statuses.contains(s)) _status = s;
          _noteController.text = data['note']?.toString() ?? '';
        }
      }
    } catch (_) {
      // Ignore: the card still works with defaults.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final ref = _ref;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (ref == null || uid == null) return;

    setState(() => _saving = true);
    try {
      await ref.set({
        'donorUid': widget.donorUid,
        'donorCode': widget.donorCode,
        'coordinatorUid': uid,
        'status': _status,
        'note': _noteController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up saved')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save follow-up. Please try again.'),
        ),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Follow-up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: mainText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Internal note for your team. Not sent to the donor.',
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final s in _statuses)
                        ChoiceChip(
                          label: Text(s),
                          selected: _status == s,
                          selectedColor: pinkCard,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: _status == s ? primaryMaroon : mainText,
                          ),
                          onSelected: (_) => setState(() => _status = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLength: 200,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Short note (no phone numbers or names)',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(_saving ? 'Saving...' : 'Save follow-up'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}