import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import 'll_components.dart';

/// The four states every data-backed LifeLink screen must handle, in one
/// shared presentation so loading looks the same in every module.
///
/// A screen that shows a spinner where another shows a skeleton, or that
/// renders a raw exception where another explains itself, is exactly the
/// inconsistency this exists to remove.

/// Centred loading state with an optional line of context.
class LLLoadingState extends StatelessWidget {
  const LLLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: LLSpacing.lg),
            Text(message!, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Empty state: an icon, a title, an explanation, and optionally the one
/// action that would resolve it.
class LLEmptyState extends StatelessWidget {
  const LLEmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LLSpacing.xxl + 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: LLIconSize.emptyState, color: colors.textSecondary),
            const SizedBox(height: LLSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: LLSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.45),
            ),
            if (action != null) ...[const SizedBox(height: LLSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}

/// Error state that tells a permission problem apart from a connection
/// problem, because the two need different responses from the person
/// reading them: one needs an administrator, the other needs a retry.
class LLErrorState extends StatelessWidget {
  const LLErrorState({super.key, required this.error, this.onRetry, this.whatFailed});

  final Object error;
  final VoidCallback? onRetry;

  /// e.g. "emergency requests" - used in the message so the user knows
  /// which part of the screen failed.
  final String? whatFailed;

  bool get _isPermissionDenied {
    final e = error;
    return e is FirebaseException && e.code == 'permission-denied';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPermission = _isPermissionDenied;
    final subject = whatFailed ?? 'this data';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LLSpacing.xxl + 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission ? Icons.lock_outline_rounded : Icons.cloud_off_rounded,
              size: 42,
              color: isPermission ? colors.warning : colors.critical,
            ),
            const SizedBox(height: LLSpacing.lg),
            Text(
              isPermission ? 'You do not have access to $subject' : 'Could not load $subject',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: LLSpacing.sm),
            Text(
              isPermission
                  ? 'Your account does not have permission for this. Ask an administrator to '
                        'review your role - signing out and back in will not change it.'
                  : 'This is usually a connection problem. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.45),
            ),
            if (onRetry != null && !isPermission) ...[
              const SizedBox(height: LLSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: LLIconSize.action),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An inline notice strip, for information that belongs next to content
/// rather than replacing it - a data caveat, a stale-data warning, a
/// "some records are incomplete" note.
class LLNotice extends StatelessWidget {
  const LLNotice({super.key, required this.message, required this.icon, this.tone = LLTone.neutral});

  final String message;
  final IconData icon;
  final LLTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (fg, bg) = tone.resolve(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LLSpacing.md, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LLRadius.control),
        border: Border.all(color: fg.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: LLIconSize.label, color: fg),
          const SizedBox(width: LLSpacing.sm),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 11.5, color: colors.textPrimary, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
