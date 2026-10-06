import 'package:flutter/material.dart';
import 'recipient_home_screen.dart';

/// Main recipient screen with unified navigation bar.
///
/// Wraps [RecipientHomeScreen] so that any existing or future references
/// to [RecipientMainScreen] will seamlessly render the complete recipient
/// module with its modern Material 3 navigation bar and wide navigation rail.
class RecipientMainScreen extends StatelessWidget {
  final int initialIndex;

  const RecipientMainScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return RecipientHomeScreen(initialIndex: initialIndex);
  }
}
