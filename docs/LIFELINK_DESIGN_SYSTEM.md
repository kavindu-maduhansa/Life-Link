# LifeLink shared design system

LifeLink is one application with four role modules. This document is how the
Recipient/Caregiver and Organization Coordinator modules adopt the same look
without re-inventing it, and without touching anyone else's code.

The Doctor/Blood Bank and Donor modules already use everything below, so you
have two working references to copy from.

Last reviewed: 12 September 2026, branch `feat_Member3_DoctorM`.

---

## 1. What is shared, and what stays yours

**Shared** (do not fork these): colours, typography scale, spacing, radii, icon
sizes, breakpoints, the app shell, the app bar, navigation style, buttons,
cards, fields, chips, badges, dialogs, snackbars, and the loading / empty /
error / offline presentations.

**Yours** (nobody else should touch them): your screens, your Firestore
queries and writes, your models, your validation, your navigation
destinations and their labels, and your role's actual tasks.

The shared components deliberately contain **no business logic**. That is what
lets two modules look identical while sharing no behaviour.

> Do not create a second theme for your module. If you need something the
> shared components do not provide, build it *out of* the shared tokens
> (`LLSpacing`, `LLRadius`, `LLTone`, `context.colors`) and, if it is genuinely
> reusable, move it into `lib/widgets/lifelink/`.

---

## 2. Where things live

| File | What it gives you |
|---|---|
| `lib/theme/app_colors.dart` | All colour tokens, Light and Dark, via `context.colors` |
| `lib/theme/app_theme.dart` | The `ThemeData` for both modes - buttons, fields, dialogs, navigation |
| `lib/theme/lifelink_design.dart` | `LLSpacing`, `LLRadius`, `LLIconSize`, `LLBreakpoints`, `LLA11y`, `LLMotion`, `LLElevation` |
| `lib/widgets/lifelink/ll_nav.dart` | `LLNavDestination`, `LLAppBarAction`, `LLRoleNav` |
| `lib/widgets/lifelink/ll_app_shell.dart` | `LLAppShell`, `LLAppBar` |
| `lib/widgets/lifelink/ll_brand.dart` | `LLBrandMark`, `LLWordmark` |
| `lib/widgets/lifelink/ll_components.dart` | `LLTone`, `LLCard`, `LLStatusBadge`, `LLFilterChip`, `LLSearchField`, `LLSectionHeader`, `LLInfoRow` |
| `lib/widgets/lifelink/ll_states.dart` | `LLLoadingState`, `LLEmptyState`, `LLErrorState`, `LLNotice` |

---

## 3. Colour: never write a hex literal again

Read every colour from the active theme:

```dart
import '../../theme/app_colors.dart';

@override
Widget build(BuildContext context) {
  final colors = context.colors;
  return Text('Hello', style: TextStyle(color: colors.textPrimary));
}
```

### Why this matters

The Donor module was originally written with 157 hard-coded
`Color(0xFF......)` literals. The consequence was not cosmetic: **the module
had no Dark Mode at all**, and could not get one without rewriting every
screen. A `static const Color` field is the same trap - a static cannot read
the active theme.

### Light Mode palette

| Token | Light | Meaning |
|---|---|---|
| `background` | `#FAF7F6` Warm Porcelain | Page background |
| `surface` | `#FFFFFF` | Cards and primary surfaces |
| `elevatedSurface` | `#F5ECEE` Soft Blush | Input fills, inset rows |
| `primary` | `#8F1838` Deep Burgundy | Brand, primary action, blood-donation identity |
| `primaryContainer` | `#F9DFE5` | Soft burgundy wash |
| `accent` | `#087F8C` Clinical Teal | Operational, secondary action, selected nav, focus |
| `accentContainer` | `#DDF3F3` | Operational / healthy block |
| `critical` | `#C62845` | **Emergencies and destructive actions only** |
| `criticalContainer` | `#FCE8EC` | Critical block |
| `success` | `#267A5E` | Available, eligible, verified, completed |
| `successContainer` | `#E2F2EB` | Success block |
| `warning` | `#C47A14` | Pending attention, low stock, temporarily ineligible |
| `warningContainer` | `#FBEFDC` | Warning block |
| `analytics` | `#76556F` Muted Plum | Analytics, non-urgent supporting detail |
| `textPrimary` | `#211A1D` | Headings and body |
| `textSecondary` | `#6B6064` | Supporting text |
| `border` | `#E6DADD` | Borders and dividers |
| `disabled` | `#B9AFB2` | Disabled controls and text |

Dark Mode is the obsidian/charcoal palette the Doctor module shipped with. It
is defined alongside Light in the same file and is already correct - just use
the tokens and both modes work.

### Rules

- Red is for genuine emergencies and destructive actions. Not for navigation,
  neutral statistics, or decoration. Do not make your module excessively red.
- Burgundy is brand identity and the primary action. Teal is the secondary /
  operational action, so not every button is a filled block.
- Never put a pale accent colour on white as small text.
- Status is **icon + text + colour together**, never colour alone.
- Tint a container, do not flood a card. A screen full of urgent items must
  stay readable.

### `LLTone` - map your states onto shared meanings

```dart
LLStatusBadge(
  label: 'Verified',
  icon: Icons.verified_rounded,
  tone: LLTone.success,
)
```

`LLTone` values: `brand`, `operational`, `success`, `warning`, `critical`,
`analytics`, `neutral`. `tone.resolve(context)` returns
`(foreground, container)` for the active theme.

---

## 4. Adding your role - a worked example

This is the whole job. Declare your destinations, hand them to the shell.

```dart
import 'package:flutter/material.dart';

import '../../widgets/lifelink/ll_app_shell.dart';
import '../../widgets/lifelink/ll_nav.dart';

class RecipientHomeScreen extends StatelessWidget {
  const RecipientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LLAppShell(
      nav: LLRoleNav(
        // Shown under the title, so a user always knows which role they
        // are in while every other visual detail stays identical.
        roleLabel: 'Recipient',

        // YOUR destinations. Never copy the Doctor or Donor ones.
        destinations: [
          LLNavDestination(
            label: 'My Requests',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
            builder: (context) => const MyRequestsTab(),
          ),
          LLNavDestination(
            label: 'New Request',
            icon: Icons.add_circle_outline_rounded,
            selectedIcon: Icons.add_circle_rounded,
            builder: (context) => const NewRequestTab(),
          ),
          LLNavDestination(
            label: 'Donors',
            icon: Icons.favorite_outline_rounded,
            selectedIcon: Icons.favorite_rounded,
            builder: (context) => const RespondingDonorsTab(),
          ),
        ],

        // isPrimary actions stay visible at every width; the rest collapse
        // into an overflow menu on a narrow phone.
        actions: [
          LLAppBarAction(
            icon: Icons.logout_rounded,
            tooltip: 'Sign Out',
            isPrimary: true,
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
```

You get, for free and identical to the other modules: the brand mark, the app
bar, bottom navigation on phones, a navigation rail at 900dp and above, the
offline banner, selected-state colours, and an `IndexedStack` so your tabs keep
their scroll position and Firestore subscriptions when the user switches away.

---

## 5. Building a screen

```dart
@override
Widget build(BuildContext context) {
  final colors = context.colors;

  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _myStream,
    builder: (context, snapshot) {
      // 1. Error - and tell a permission problem apart from a network one.
      if (snapshot.hasError) {
        return LLErrorState(error: snapshot.error!, whatFailed: 'your requests');
      }
      // 2. Loading.
      if (!snapshot.hasData) {
        return const LLLoadingState(message: 'Loading your requests...');
      }
      // 3. Empty - explain it, and offer the action that resolves it.
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) {
        return LLEmptyState(
          icon: Icons.inbox_rounded,
          title: 'No requests yet',
          message: 'When you create a blood request it will appear here.',
          action: FilledButton.icon(
            onPressed: _createRequest,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create a request'),
          ),
        );
      }
      // 4. Content.
      return ListView.separated(
        padding: const EdgeInsets.all(LLSpacing.lg),
        itemCount: docs.length,
        separatorBuilder: (_, _) => const SizedBox(height: LLSpacing.md),
        itemBuilder: (context, i) => LLCard(
          onTap: () => _open(docs[i]),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  docs[i].data()['title'] as String? ?? 'Untitled',
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              const LLStatusBadge(
                label: 'Pending',
                icon: Icons.hourglass_top_rounded,
                tone: LLTone.warning,
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

**All four states are required.** A screen that renders a bare spinner forever
on a failed read is a bug, and it is the most common one in this codebase's
history.

---

## 6. Spacing, radii, breakpoints

Use the scale rather than loose numbers, so rhythm matches across modules:

```dart
padding: const EdgeInsets.all(LLSpacing.lg),      // 16
borderRadius: BorderRadius.circular(LLRadius.card), // 16
```

`LLSpacing`: `xxs 2, xs 4, sm 8, md 12, lg 16, xl 20, xxl 24, section 30`
`LLRadius`: `chip 10, control 12, card 16, sheet 20, pill 20`
`LLBreakpoints`: `wide 900` (rail vs bottom nav), `compactActions 420`,
`statRow 560`

---

## 7. Accessibility - non-negotiable

- **44x44 minimum** for anything tappable. The button themes enforce it; for a
  hand-built control use `LLA11y.minTapTarget` or a `minHeight` constraint.
- **Never colour alone.** Pair every status with an icon and text.
- **Respect Reduce Motion.** Check `LLA11y.reduceMotion(context)` or wrap a
  duration in `LLMotion.respect(context, ...)`. Skip entrance animations
  outright rather than shortening them.
- **No overflow at 400dp.** Give every `Text` in a `Row` a `Flexible`/`Expanded`
  and an `overflow: TextOverflow.ellipsis`. An unconstrained title in a `Row`
  wraps to one character per line and Flutter draws its overflow stripe - this
  has already happened once in this project.
- Tables scroll horizontally inside their own container; the page never does.

---

## 8. Checklist before you open a PR

1. No `Color(0x...)` literal and no `Colors.*` outside the theme files.
2. Light, Dark and System all render correctly.
3. Loading, empty, error and offline states all handled.
4. No overflow at 400dp width.
5. Your navigation destinations are yours - you have not borrowed another
   role's.
6. No Doctor-only action is reachable from a non-Doctor screen.
7. `dart format`, `flutter analyze` and `flutter test` all clean.

---

## 9. Role boundaries

The modules share a look, not a job. Keep these apart:

| Doctor / Blood Bank | Donor | Recipient | Coordinator |
|---|---|---|---|
| Verification | Availability | Create a request | Campaigns and drives |
| Donor matching | Eligibility | Track a request | Organisation profile |
| Response coordination | Matching emergency requests | See responding donors | Volunteer coordination |
| Blood stock readiness | Accept / decline | Request history | Reporting |
| Escalation | Donation history | | |

Do not put medical-officer actions (verification, escalation, stock edits) on a
Donor, Recipient or Coordinator screen.
